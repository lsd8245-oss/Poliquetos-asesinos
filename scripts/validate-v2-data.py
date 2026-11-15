"""Validate v2 contracts and existing data without treating legacy stats as v2."""
import argparse
import copy
import hashlib
import json
from pathlib import Path

from jsonschema import Draft202012Validator, ValidationError

ROOT = Path(__file__).resolve().parents[1]
SCHEMAS = ROOT / "data/schemas"


def load(path):
    return json.loads(path.read_text(encoding="utf-8"))


def validate(kind, data):
    schema = load(SCHEMAS / f"{kind}.schema.json")
    Draft202012Validator(schema).validate(data)
    if kind in ('worlds', 'enemies', 'bosses'):
        if len({item['id'] for item in data}) != len(data):
            raise ValueError('Duplicate content identifier')
    if kind == 'worlds':
        if [world['id'] for world in data] != list(range(1, 13)):
            raise ValueError('Expected twelve consecutive campaign worlds')
        for world in data:
            if world['miniboss_enabled'] or not world['final_boss_enabled']:
                raise ValueError('05A disables only minibosses; final bosses remain active')
            if world['alerta_jefe_seg'] != world['duracion_hasta_jefe_seg'] - 10:
                raise ValueError('Incorrect boss alert timeline')
    if kind == 'bosses':
        for boss in data:
            phases = boss['fases']
            if phases[0]['desde_pct'] != 100 or phases[-1]['hasta_pct'] != 0:
                raise ValueError('Boss phases must span full HP')
            if any(a['hasta_pct'] != b['desde_pct'] for a,b in zip(phases, phases[1:])):
                raise ValueError('Boss phases have a gap')
    if kind == 'combat':
        for group in ('shot', 'missile'):
            for weapon in data[group]:
                if abs(weapon['damage'] * weapon['count'] / weapon['interval'] - weapon['dps']) > 1e-7:
                    raise ValueError('Weapon damage/cadence differs from DPS')
    if kind == 'escape':
        if sum(section['enemigos'] for section in data['tramos']) != data['enemigos_total']:
            raise ValueError('Escape section counts differ from total')
        if 'eventos' in data:
            for section in data['tramos']:
                count = sum(e['cantidad'] for e in data['eventos'] if e['tipo'] == 'oleada' and section['inicio_seg'] <= e['t'] < section['fin_seg'])
                if count != section['enemigos']:
                    raise ValueError('Escape waves differ from section count')
    if kind == "atlas":
        width, height = data["tamano"]
        for frame in data["frames"].values():
            if frame["x"] + frame["w"] > width or frame["y"] + frame["h"] > height:
                raise ValueError("Atlas frame outside image")
        for anim in data["animaciones"].values():
            if not set(anim["frames"]).issubset(data["frames"]):
                raise ValueError("Animation references missing frame")
    if kind == "shop":
        for upgrade in data["mejoras"]:
            if len(upgrade["costos"]) != upgrade["rangos"]:
                raise ValueError("Upgrade needs one price per rank")
    if kind == "legacy_inventory":
        entities = {e["id"]: e for e in data["entities"]}
        if len(entities) != len(data["entities"]):
            raise ValueError("Duplicate legacy type")
        if [w["id"] for w in data["worlds"]] != list(range(1, 15)):
            raise ValueError("Expected worlds 1 through 14")
        for world in data["worlds"]:
            for role in ("unique", "recurrent"):
                for key in world[role]:
                    if {"world": world["id"], "role": role} not in entities[key]["appearances"]:
                        raise ValueError("Missing legacy appearance")
            for boss in world["bosses"]:
                if boss["type"] not in entities:
                    raise ValueError("Missing boss type")


def validate_file(kind, path):
    data = load(path)
    validate(kind, data)
    if kind == "waves" and path.name.startswith("world_"):
        if data["mundo"] != int(path.stem.removeprefix("world_")):
            raise ValueError("Wave world differs from filename")


def load_campaign():
    """Load the complete live contract; historical worlds never enter this set."""
    data = {kind: load(ROOT / f'data/{kind}.json')
            for kind in ('campaign', 'worlds', 'enemies', 'bosses', 'escape', 'shop', 'cosmetics')}
    files = sorted((ROOT / 'data/waves').glob('world_*.json'))
    if [p.name for p in files] != [f'world_{n:02}.json' for n in range(1, 13)]:
        raise ValueError('Active waves must contain exactly worlds 01 through 12')
    data['waves'] = {int(p.stem.split('_')[1]): load(p) for p in files}
    data['aliases'] = load(ROOT / 'assets/campaign_aliases.json')
    data['manifest'] = load(ROOT / 'assets/assets_manifest.json')
    return data


def validate_campaign(data):
    """Check semantic references, original budgets and identities across JSON files."""
    for kind in ('campaign', 'worlds', 'enemies', 'bosses', 'escape', 'shop', 'cosmetics'):
        validate(kind, data[kind])
    validate('campaign_aliases', data['aliases'])
    if set(data['waves']) != set(range(1, 13)):
        raise ValueError('Missing or extra campaign wave file')
    for wave in data['waves'].values():
        validate('waves', wave)
    campaign = data['campaign']
    mapping = campaign['old_to_new']
    original_worlds = load(ROOT / 'data/archive/04a/worlds.json')
    original_enemies = {e['id']: e for e in load(ROOT / 'data/archive/04a/enemies.json')}
    original_bosses = {b['id']: b for b in load(ROOT / 'data/archive/04a/bosses.json')}
    proposal = load(ROOT / 'docs/planificacion/lista_12_mundos_propuesta.json')['mundos']
    enemies = {e['id']: e for e in data['enemies']}
    bosses = {b['id']: b for b in data['bosses']}
    live_bosses, appearances = set(), {}
    for world, expected in zip(data['worlds'], proposal):
        n, old = world['id'], world['legacy_id']
        if mapping.get(str(old)) != n or old != expected['antiguo_id'] or world['acto'] != expected['acto']:
            raise ValueError('World migration/act differs from the approved matrix')
        if world['unicos'] != expected['comunes_originales'] + expected['comunes_agregados']:
            raise ValueError('Common catalogue must preserve originals and exactly two additions')
        if world['recurrentes'] != expected['recurrentes_originales'] + [expected['recurrente_agregado']]:
            raise ValueError('Recurrent catalogue must preserve originals and exactly one addition')
        for role, keys in [('unico', world['unicos']), ('recurrente', world['recurrentes'])]:
            for key in keys:
                if key not in enemies:
                    raise ValueError(f'Missing catalogue enemy: {key}')
                appearances.setdefault(key, {})[str(n)] = role
        expected_bosses = [campaign['legacy_boss_to_current'][key] for key in expected['jefes_ids_originales']
                           if key != 'boss_w14_epitoke']
        if world['jefes'] != expected_bosses:
            raise ValueError('Surviving final bosses must all remain active in their original groups')
        for key in world['jefes']:
            if key not in bosses or bosses[key]['mundo'] != n or not key.startswith(f'boss_w{n:02}_'):
                raise ValueError('Boss identifier/world reference mismatch')
            boss = bosses[key]
            prior = original_bosses.get(boss['asset_id'])
            if not prior or boss['asset_world'] != old or campaign['legacy_boss_to_current'].get(prior['id']) != key:
                raise ValueError('Invalid original boss asset reference')
            for field in ('vida', 'vida_base', 'fases', 'parametros', 'recompensa_extra', 'tamano', 'segmentos'):
                if boss.get(field) != prior.get(field):
                    raise ValueError(f'05A must preserve boss {field}')
            live_bosses.add(key)
        prior_world = original_worlds[old-1]
        if any(world[field] != prior_world[field] for field in ('enemigos_total', 'duracion_hasta_jefe_seg', 'alerta_jefe_seg')):
            raise ValueError('05A does not increase stage counts or duration')
        wave = data['waves'][n]
        if wave['mundo'] != n:
            raise ValueError('Wave belongs to the wrong campaign world')
        events = wave['eventos']
        if [e['t'] for e in events] != sorted(e['t'] for e in events):
            raise ValueError('Events must be ordered by time')
        original = load(ROOT / f'data/archive/04a/waves/world_{old:02}.json')['eventos']
        surviving = {i: event for i, event in enumerate(original) if event['tipo'] != 'minijefe'}
        if len(events) != len(surviving) or {e['legacy_index'] for e in events} != set(surviving):
            raise ValueError('Missing/duplicate historical event identity')
        regular = [e for e in events if e['tipo'] == 'oleada']
        original_regular = [e for e in original if e['tipo'] == 'oleada']
        if [e['legacy_index'] for e in regular] != [i for i, e in enumerate(original) if e['tipo'] == 'oleada']:
            raise ValueError('Original regular wave order must remain stable')
        if sum(e['cantidad'] for e in regular) != world['enemigos_total']:
            raise ValueError('Stage individuals differ from approved budget')
        for index, event in enumerate(regular):
            expected_t = round(10 + index*(original_regular[-1]['t']-10)/(len(regular)-1), 4)
            if event['t'] != expected_t or event['t'] >= world['alerta_jefe_seg']:
                raise ValueError('Regular schedule must fill the removed miniboss window')
        for event in events:
            prior = surviving[event['legacy_index']]
            expected_event = copy.deepcopy(prior)
            expected_event['legacy_index'] = event['legacy_index']
            if event['tipo'] == 'oleada':
                expected_event['t'] = event['t']
                enemy = enemies.get(event['enemigo'], {})
                appearance = enemy.get('mundos', {}).get(str(n), {})
                if not enemy.get('runtime_ready') or not appearance.get('runtime_ready'):
                    raise ValueError('Pending species cannot spawn in runtime')
            elif event['tipo'] == 'alerta_jefe':
                expected_event['id'] = campaign['legacy_boss_to_current'][prior['id']]
                expected_event['jefes'] = [campaign['legacy_boss_to_current'][key] for key in prior['jefes']]
            if event != expected_event:
                raise ValueError('05A must preserve event composition, formations, carriers and hazards')
    if live_bosses != set(bosses):
        raise ValueError('Inactive or orphan boss present in active catalogue')
    if set(enemies) != set(appearances):
        raise ValueError('Missing or orphan enemy in active catalogue')
    for key, enemy in enemies.items():
        if {n: appearance['rol'] for n, appearance in enemy['mundos'].items()} != appearances[key]:
            raise ValueError('Enemy appearance differs from world catalogue')
        if any(a['runtime_ready'] != enemy['runtime_ready'] for a in enemy['mundos'].values()):
            raise ValueError('Enemy runtime readiness differs from assignment')
        if key in original_enemies:
            for field in ('familia', 'tipo', 'categoria', 'movimiento', 'disparo', 'puntos', 'drop', 'tamano', 'parametros'):
                if enemy.get(field) != original_enemies[key].get(field):
                    raise ValueError('Existing enemy taxonomy and behavior must remain intact')
        elif enemy['runtime_ready']:
            raise ValueError('New species require accepted art and behavior before runtime activation')
    lab = data['worlds'][-1]
    sectors = lab['sectores_jefes']
    if [s['id'] for s in sectors] != [1, 2, 3] or [len(s['jefes']) for s in sectors] != [3, 1, 1]:
        raise ValueError('Laboratory requires three consecutive rooms with three concurrent robots')
    if [key for s in sectors for key in s['jefes']] != lab['jefes']:
        raise ValueError('Laboratory room progression must match active bosses')
    if lab['base_monedas'] != sum(s['base_monedas'] for s in sectors) or lab['jefe_objetivo_seg'] != sum(s['objetivo_seg'] for s in sectors):
        raise ValueError('Laboratory totals must exclude the removed Epitoka encounter')
    for current, historical in zip(sectors, [original_worlds[-1]['sectores_jefes'][i] for i in (0, 2, 3)]):
        if any(current[f] != historical[f] for f in ('base_monedas', 'objetivo_seg', 'texto')):
            raise ValueError('Surviving laboratory room budgets must remain intact')
    aliases = data['aliases']['aliases']
    originals = {a['nombre']: a for a in data['manifest']['assets']}
    for source in aliases.values():
        if source not in originals or not (ROOT / originals[source]['ruta']).is_file():
            raise ValueError('Alias must directly reference a preserved original PNG')
    pending = [p['key'] for p in data['aliases']['pending']]
    if len(pending) != len(set(pending)) or set(pending) & set(aliases):
        raise ValueError('Asset cannot be duplicated or both aliased and pending')
    for world in data['worlds']:
        n, old = world['id'], world['legacy_id']
        for layer in range(1, 5):
            if aliases.get(f'w{n:02}_bg_layer{layer}_idle') != f'w{old:02}_bg_layer{layer}_idle':
                raise ValueError('Background must preserve original world artwork')
        for key in world['unicos'] + world['recurrentes']:
            for animation in ('move', 'hit'):
                active = f'w{n:02}_enemy_{key}_{animation}'
                if enemies[key]['runtime_ready']:
                    if active not in aliases or not aliases[active].endswith(f'_enemy_{key}_{animation}'):
                        raise ValueError('Runtime species needs its own explicitly sourced PNG')
                elif active not in pending:
                    raise ValueError('Missing artwork must be explicitly pending')
        for key in world['jefes']:
            source = bosses[key]
            if aliases.get(f'w{n:02}_boss_{key}_move') != f"w{old:02}_boss_{source['asset_id']}_move":
                raise ValueError('Final boss PNG must match original species and world')
    for event in data['escape']['eventos']:
        if event['tipo'] == 'oleada':
            key = event['enemigo']
            if key not in enemies or not enemies[key]['runtime_ready'] or f'w13_enemy_{key}_move' not in aliases:
                raise ValueError('Escape references missing runtime species or PNG')
    shop, original_shop = data['shop'], load(ROOT / 'data/archive/04a/shop.json')
    if shop['mejoras'] != original_shop['mejoras'] or shop['equipo'] != original_shop['equipo']:
        raise ValueError('05A preserves prices until the explicit economy review')
    if any(r['vida_minijefe'] != 0 for r in shop['economia']):
        raise ValueError('Inactive miniboss must not have active economy rewards')
    expected_rows = [str(n) for n in range(1, 12)] + [f'12 (4.{i})' for i in (1, 2, 3)]
    if [row['mundo'] for row in shop['economia']] != expected_rows:
        raise ValueError('Economy rows must follow twelve-world campaign and three laboratory rooms')
    expected_economy = []
    for world in data['worlds']:
        rows = [row for row in original_shop['economia'] if int(row['mundo'].split()[0]) == world['legacy_id']]
        if world['id'] == 12:
            rows = [rows[i] for i in (0, 2, 3)]
        for index, source in enumerate(rows):
            expected = dict(source, mundo=str(world['id']) if len(rows) == 1 else f'12 (4.{index+1})',
                            acto=world['acto'], vida_minijefe=0)
            expected_economy.append(expected)
    if shop['economia'] != expected_economy:
        raise ValueError('Economy budgets and surviving rewards must preserve original values')
    archive = ROOT / 'data/archive/04a'
    for relative, digest in load(archive / 'archive_manifest.json')['sha256'].items():
        if hashlib.sha256((archive / relative).read_bytes()).hexdigest() != digest:
            raise ValueError('Archived original data was modified')


def self_test():
    cases = {
        "campaign": (lambda x: x.update(escape_id=15)),
        "campaign_aliases": (lambda x: x.update(source_commit='invalid')),
        "worlds": (lambda x: x[0].update(enemigos_total=-1)),
        "enemies": (lambda x: x[0].update(id="INVALID ID")),
        "bosses": (lambda x: x[0].update(vida=-1)),
        "shop": (lambda x: x["mejoras"][0].update(costos=[1])),
        "cosmetics": (lambda x: x[0].update(id="INVALID ID")),
        "audio": (lambda x: x[0].update(volumen=2)),
        "waves": (lambda x: x["eventos"][0].update(cantidad=-1)),
        "combat": (lambda x: x["shot"][0].update(damage=-1)),
        "escape": (lambda x: x.update(duracion_seg=0)),
        "atlas": (lambda x: x["frames"][next(iter(x["frames"]))].update(x=1024)),
        "assets_manifest": (lambda x: x["assets"][0].update(estado="inventado")),
    }
    for kind, mutate in cases.items():
        example = load(SCHEMAS / f"{kind}.schema.json")["examples"][0]
        validate(kind, example)
        bad = copy.deepcopy(example)
        mutate(bad)
        try:
            validate(kind, bad)
        except (ValueError, __import__("jsonschema").ValidationError):
            pass
        else:
            raise AssertionError(f"{kind} accepted invalid data")
    atlas = load(SCHEMAS / "atlas.schema.json")["examples"][0]
    atlas["animaciones"]["move"]["frames"] = ["missing"]
    try:
        validate("atlas", atlas)
    except ValueError:
        pass
    else:
        raise AssertionError("Missing frame accepted")
    # Check filename/world agreement without creating temporary repository data.
    import tempfile
    with tempfile.TemporaryDirectory() as tmp:
        wave = load(SCHEMAS / "waves.schema.json")["examples"][0]
        target = Path(tmp) / "world_02.json"
        target.write_text(json.dumps(wave), encoding="utf-8")
        try:
            validate_file("waves", target)
        except ValueError:
            pass
        else:
            raise AssertionError("Wrong wave world accepted")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    schemas = sorted(SCHEMAS.glob("*.schema.json"))
    if not schemas:
        raise ValueError("No schemas found")
    for path in schemas:
        Draft202012Validator.check_schema(load(path))
    validate_file("legacy_inventory", ROOT / "data/legacy_inventory.json")
    # Validate populated future data as soon as its owning phase adds it.
    for kind in ("worlds", "enemies", "bosses", "combat", "shop", "cosmetics", "audio", "escape"):
        path = ROOT / f"data/{kind}.json"
        if path.exists():
            validate_file(kind, path)
    for path in (ROOT / "data/waves").glob("world_*.json"):
        validate_file("waves", path)
    validate_campaign(load_campaign())
    for path in (ROOT / "assets/atlas").glob("w*.json"):
        validate_file("atlas", path)
    manifest = ROOT / "assets/assets_manifest.json"
    if manifest.exists():
        validate_file("assets_manifest", manifest)
    if args.self_test:
        self_test()
    print(f"{len(schemas)} contracts verified; available campaign data and legacy inventory valid.")


if __name__ == "__main__":
    main()
