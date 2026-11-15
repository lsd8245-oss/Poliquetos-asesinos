"""Rebuild campaign 05A deterministically from immutable 04A JSON.

Only campaign data, its schemas and direct asset aliases are written. PNG, atlas,
audio, HTML and the historical inventory are never generated or replaced.
"""
import copy
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
ARCHIVE = ROOT / 'data/archive/04a'
SOURCE_COMMIT = '9871b5a997408cd4ffec45b8a2b2b0593435537c'
WORLD_MAP = {1: 1, 2: 2, 4: 3, 5: 4, 7: 5, 8: 6, 9: 7,
             10: 8, 11: 9, 12: 10, 13: 11, 14: 12, 15: 13}
PENDING_FAMILIES = {
    'eulalia': 'Eulalia · Phyllodocidae',
    'hediste_diversicolor': 'Hediste diversicolor · Nereididae',
    'capitella_capitata': 'Capitella capitata (complejo) · Capitellidae',
    'polydora_ciliata': 'Polydora ciliata · Spionidae',
    'vanadis_antarctica': 'Vanadis antarctica · Alciopidae',
    'pelagobia_longicirrata': 'Pelagobia longicirrata · Lopadorrhynchidae',
    'laetmonice_producta': 'Laetmonice producta · Aphroditidae',
    'austrolaenilla_antarctica': 'Austrolaenilla antarctica · Polynoidae',
    'neanthes_visicete': 'Neanthes visicete · Nereididae',
    'branchipolynoe': 'Branchipolynoe · Polynoidae',
    'thermopolynoe': 'Thermopolynoe · Polynoidae',
    'macellicephala_tricornis': 'Macellicephala tricornis · Polynoidae',
    'bathykermadeca_hadalis': 'Bathykermadeca hadalis · Polynoidae',
    'mech_oenone': 'Robot Centinela Oenone',
    'mech_diopatra': 'Robot Artillería Diopatra',
}


def load(path):
    return json.loads(path.read_text(encoding='utf8'))


def write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    content = json.dumps(data, ensure_ascii=False, indent=2) + '\n'
    if not path.exists() or path.read_text(encoding='utf8') != content:
        path.write_text(content, encoding='utf8')


def archive_originals():
    """Use the pinned Git tree, even if invoked after active data was migrated."""
    if (ARCHIVE / 'archive_manifest.json').exists():
        manifest = load(ARCHIVE / 'archive_manifest.json')
        if manifest['source_commit'] != SOURCE_COMMIT:
            raise ValueError('Unexpected archive source commit')
        for name, digest in manifest['sha256'].items():
            if hashlib.sha256((ARCHIVE / name).read_bytes()).hexdigest() != digest:
                raise ValueError(f'Archive modified: {name}')
        return
    paths = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', SOURCE_COMMIT,
                                     'data', 'assets/assets_manifest.json'], cwd=ROOT, text=True).splitlines()
    hashes = {}
    for name in paths:
        if not name.endswith('.json'):
            continue
        relative = 'assets_manifest.json' if name.startswith('assets/') else name.removeprefix('data/')
        content = subprocess.check_output(['git', 'show', f'{SOURCE_COMMIT}:{name}'], cwd=ROOT)
        target = ARCHIVE / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        if target.exists() and target.read_bytes() != content:
            raise ValueError(f'Refusing to overwrite historical data: {relative}')
        target.write_bytes(content)
        hashes[relative] = hashlib.sha256(content).hexdigest()
    write(ARCHIVE / 'archive_manifest.json', {'source_commit': SOURCE_COMMIT, 'sha256': hashes})


def build():
    original_worlds = load(ARCHIVE / 'worlds.json')
    original_enemies = {e['id']: e for e in load(ARCHIVE / 'enemies.json')}
    original_bosses = {b['id']: b for b in load(ARCHIVE / 'bosses.json')}
    proposal = load(ROOT / 'docs/planificacion/lista_12_mundos_propuesta.json')['mundos']
    manifest = load(ARCHIVE / 'assets_manifest.json')['assets']
    boss_map = {key: f"boss_w{WORLD_MAP[b['mundo']]:02}_" + key.split('_', 2)[2]
                for key, b in original_bosses.items()
                if b['tipo'] == 'jefe' and b['mundo'] in WORLD_MAP and key != 'boss_w14_epitoke'}
    campaign = {'version': 3, 'world_count': 12, 'escape_id': 13, 'laboratory_id': 12,
                'lab_encounters': 3, 'source_commit': SOURCE_COMMIT,
                'old_to_new': {str(k): v for k, v in WORLD_MAP.items()},
                'removed_world_destinations': {'3': 2, '6': 4},
                'legacy_lab_to_new': {'0': 0, '1': 1, '2': 1, '3': 2, '4': 3},
                'legacy_boss_to_current': boss_map,
                'asset_sources': {str(v): k for k, v in WORLD_MAP.items()},
                'skin_world_rewards': {'7': 'bioluminiscente', '10': 'magma'},
                'act_worlds': {'1': [1, 2, 3], '2': [4, 5, 6], '3': [7, 8, 9, 10, 11], '4': [12]}}
    worlds, bosses, enemies, waves, scheduling = [], [], {}, {}, []
    for p in proposal:
        old, new = p['antiguo_id'], p['nuevo_id']
        w = copy.deepcopy(original_worlds[old-1])
        w.update(id=new, legacy_id=old, acto=p['acto'], miniboss_enabled=False, final_boss_enabled=True)
        for field in ('minijefe', 'mini_tipo', 'vida_minijefe', 'minijefe_inicio_seg', 'minijefe_ventana_seg'):
            w.pop(field, None)
        w['unicos'] = p['comunes_originales'] + p['comunes_agregados']
        w['recurrentes'] = p['recurrentes_originales'] + [p['recurrente_agregado']]
        w['jefes'] = [boss_map[key] for key in w['jefes'] if key in boss_map]
        w['sectores_jefes'] = [s for s in w['sectores_jefes'] if 'boss_w14_epitoke' not in s['jefes']]
        for index, sector in enumerate(w['sectores_jefes'], 1):
            sector['id'] = index
            sector['jefes'] = [boss_map[key] for key in sector['jefes']]
        if old == 14:
            w['base_monedas'] = sum(s['base_monedas'] for s in w['sectores_jefes'])
            w['jefe_objetivo_seg'] = sum(s['objetivo_seg'] for s in w['sectores_jefes'])
        worlds.append(w)
        for key in p['jefes_ids_originales']:
            if key not in boss_map:
                continue
            b = copy.deepcopy(original_bosses[key])
            b.update(id=boss_map[key], mundo=new, asset_id=key, asset_world=old)
            bosses.append(b)
        for role, ids in [('unico', w['unicos']), ('recurrente', w['recurrentes'])]:
            for key in ids:
                if key not in enemies:
                    if key in original_enemies:
                        enemies[key] = copy.deepcopy(original_enemies[key])
                        enemies[key].update(mundos={}, runtime_ready=True)
                    else:
                        enemies[key] = {'id': key, 'familia': PENDING_FAMILIES[key], 'tipo': 'pendiente',
                                        'mundos': {}, 'estado': 'pendiente', 'runtime_ready': False,
                                        'pending': ['original_png_and_atlas', 'accepted_behavior_and_balance']}
                enemies[key]['mundos'][str(new)] = {'rol': role, 'sprite_set': f'w{new:02}_enemy_{key}',
                                                    'runtime_ready': enemies[key]['runtime_ready']}
        original = load(ARCHIVE / f'waves/world_{old:02}.json')
        regular = [e for e in original['eventos'] if e['tipo'] == 'oleada']
        last_time = regular[-1]['t']
        times = [round(10 + i*(last_time-10)/(len(regular)-1), 4) for i in range(len(regular))]
        events, ordinal = [], 0
        comparison = []
        for index, source in enumerate(original['eventos']):
            if source['tipo'] == 'minijefe':
                continue
            event = copy.deepcopy(source)
            event['legacy_index'] = index
            if source['tipo'] == 'oleada':
                event['t'] = times[ordinal]
                comparison.append({'legacy_index': index, 'old_t': source['t'], 'new_t': event['t']})
                ordinal += 1
            elif source['tipo'] == 'alerta_jefe':
                event['id'] = boss_map[source['id']]
                event['jefes'] = [boss_map[key] for key in source['jefes'] if key in boss_map]
            events.append(event)
        events.sort(key=lambda event: (event['t'], event['legacy_index']))
        waves[new] = dict(original, mundo=new, eventos=events)
        scheduling.append({'world': new, 'legacy_world': old, 'regular_count': len(regular),
                           'individuals': sum(e['cantidad'] for e in regular), 'schedule': comparison})
    escape = load(ARCHIVE / 'escape.json')
    escape['id'] = 13
    escape['eventos'] = [dict(e, legacy_index=i) for i, e in enumerate(escape['eventos'])]
    aliases, pending = {}, []
    # Generic stage/UI/background assets and historical mini graphics are identified by source world.
    # Original keys always refer to the preserved manifest, regardless of active-key collisions.
    for asset in manifest:
        old = asset['mundo']
        if old in WORLD_MAP and asset['tipo'] not in ('enemy', 'boss'):
            aliases[f"w{WORLD_MAP[old]:02}_" + asset['nombre'].split('_', 1)[1]] = asset['nombre']
    by_name = {a['nombre']: a for a in manifest}
    for w in worlds:
        new, old = w['id'], w['legacy_id']
        for key in w['unicos'] + w['recurrentes']:
            # Prefer original art in this stage; otherwise explicitly reuse the same species elsewhere.
            candidates = [old] + [int(n) for n in original_enemies.get(key, {}).get('mundos', {}) if int(n) != old]
            for animation in ('move', 'hit'):
                active = f'w{new:02}_enemy_{key}_{animation}'
                source = next((f'w{n:02}_enemy_{key}_{animation}' for n in candidates
                               if f'w{n:02}_enemy_{key}_{animation}' in by_name), None)
                if source:
                    aliases[active] = source
                else:
                    pending.append({'key': active, 'enemy': key, 'world': new, 'state': 'pending',
                                    'reason': 'No accepted original PNG/atlas for this species'})
    # Escape uses mechanical and organic enemies from its original sprites or their explicit sources.
    for asset in manifest:
        if asset['mundo'] == 15 and asset['tipo'] == 'enemy':
            aliases['w13_' + asset['nombre'].split('_', 1)[1]] = asset['nombre']
    for event in escape['eventos']:
        if event['tipo'] != 'oleada':
            continue
        for animation in ('move', 'hit'):
            active = f"w13_enemy_{event['enemigo']}_{animation}"
            if active not in aliases:
                source = next((a['nombre'] for a in manifest
                               if a['nombre'].endswith(f"_enemy_{event['enemigo']}_{animation}")), None)
                if source:
                    aliases[active] = source
    for boss in bosses:
        prefix = f"w{boss['asset_world']:02}_boss_{boss['asset_id']}_"
        for asset in manifest:
            if asset['nombre'].startswith(prefix):
                aliases[f"w{boss['mundo']:02}_boss_{boss['id']}_" + asset['nombre'][len(prefix):]] = asset['nombre']
    alias_data = {'source_commit': SOURCE_COMMIT, 'aliases': dict(sorted(aliases.items())),
                  'pending': sorted(pending, key=lambda p: p['key'])}
    shop = load(ARCHIVE / 'shop.json')
    economy = []
    for w in worlds:
        rows = [row for row in shop['economia'] if int(row['mundo'].split()[0]) == w['legacy_id']]
        if w['id'] == 12:
            rows = [rows[i] for i in (0, 2, 3)]
        for i, source in enumerate(rows):
            row = copy.deepcopy(source)
            row.update(mundo=str(w['id']) if len(rows) == 1 else f"12 (4.{i+1})",
                       acto=w['acto'], vida_minijefe=0)
            economy.append(row)
    shop['economia'] = economy
    balance = load(ARCHIVE / 'balance_report.json')
    migrated_encounters = []
    for encounter in balance['encounters']:
        if encounter['world'] not in WORLD_MAP or 'boss_w14_epitoke' in encounter['boss_ids']:
            continue
        encounter['world'] = WORLD_MAP[encounter['world']]
        encounter['boss_ids'] = [boss_map[key] for key in encounter['boss_ids']]
        if encounter['world'] == 12 and encounter['group'] > 1:
            encounter['group'] -= 1
        encounter['legacy_budget'] = encounter.pop('budget')
        migrated_encounters.append(encounter)
    balance.update(encounters=migrated_encounters, status='provisional_05c',
                   assumption='HP preserved from 04A; historical build budgets retained as legacy_budget, not a claim of 05A affordability.')
    balance.pop('nominal_target_seconds', None)
    balance.pop('nominal_minimum_seconds', None)
    cosmetics = load(ARCHIVE / 'cosmetics.json')
    unlocks = {'mundo4_completado': 'mundo3_completado', 'objeto_jefe3': 'historico_jefe3',
               'objeto_jefe6': 'historico_jefe6', 'objeto_jefe9': 'objeto_jefe7', 'objeto_jefe12': 'objeto_jefe10'}
    for cosmetic in cosmetics:
        cosmetic['desbloqueo'] = unlocks.get(cosmetic['desbloqueo'], cosmetic['desbloqueo'])
    return {'campaign': campaign, 'worlds': worlds, 'bosses': bosses, 'enemies': list(enemies.values()),
            'waves': waves, 'escape': escape, 'aliases': alias_data, 'shop': shop, 'balance_report': balance,
            'cosmetics': cosmetics, 'wave_schedule_migration': {'policy': 'same ordered waves uniformly from 10s to original last regular wave',
                                                              'worlds': scheduling},
            'campaign_economy': economy_report(original_worlds, worlds, shop)}


def economy_report(before_worlds, worlds, shop):
    def row(w):
        base = w['base_monedas']
        regular = int(base*.75/5)*5
        sectors = w['sectores_jefes']
        bonus = base*.2
        victory = base*.4
        later_rooms = sum(s['base_monedas']*.6 for s in sectors[1:])
        return {'world': w['id'], 'act': w['acto'], 'base': base, 'stage_coins': regular,
                'victory': victory, 'no_death_bonus': bonus, 'later_room_coins': later_rooms,
                'total': regular + victory + bonus + later_rooms,
                'guaranteed_victory_only': victory}
    before = [row(w) for w in before_worlds]
    after = [row(w) for w in worlds]
    def aggregate(rows):
        return {'worlds': rows, 'total': sum(r['total'] for r in rows),
                'victory_only': sum(r['victory'] for r in rows),
                'by_act': {str(act): sum(r['total'] for r in rows if r['act'] == act) for act in range(1, 5)}}
    return {'status': 'provisional_05c',
            'assumptions': ['Modelled subtotal: regular-enemy coin drops plus fixed encounter rewards on Normal, all regular coins collected, no deaths.',
                            'Variable bullet-to-coin conversion at final-boss and miniboss phase transitions is unquantified and excluded; all 14 historical minibosses have two phases.',
                            'Weapon-at-cap cash, replay and difficulty multipliers excluded.',
                            'Escape 1000 is score, not spendable credits.',
                            'miniboss_direct_coin_loss=0 refers only to the fixed death reward, not phase-conversion income; removed weapon reward may convert to 100 at cap.',
                            'The 4485 (16.51%) reduction compares modelled subtotals, not maximum obtainable income or total possible loss.',
                            'No numeric prices or HP changed; human balance not approved.'],
            'before': aggregate(before), 'after': aggregate(after),
            'miniboss_direct_coin_loss': 0, 'miniboss_weapon_cap_cash_loss_upper_bound': 1400,
            'removed_stage_loss': sum(r['total'] for r in before if r['world'] in (3, 6)),
            'laboratory_loss': before[-1]['total']-after[-1]['total'],
            'all_upgrade_cost': sum(sum(u['costos']) for u in shop['mejoras']),
            'all_equipment_cost': sum(e['costo'] for e in shop['equipo']),
            'first_world': {'victory_only': after[0]['victory'], 'full_collection_no_death': after[0]['total'],
                            'cheapest_upgrade': min(u['costos'][0] for u in shop['mejoras']),
                            'no_coin_collection_no_death': after[0]['victory'] + after[0]['no_death_bonus']}}


def schemas(data):
    def base(kind):
        return load(ARCHIVE / f'schemas/{kind}.schema.json')
    result = {}
    world = base('worlds')
    props = world['items']['properties']
    for field in ('minijefe', 'mini_tipo', 'vida_minijefe', 'minijefe_inicio_seg', 'minijefe_ventana_seg'):
        props.pop(field)
        if field in world['items']['required']:
            world['items']['required'].remove(field)
    props.update(legacy_id={'type': 'integer', 'minimum': 1, 'maximum': 14},
                 miniboss_enabled={'const': False}, final_boss_enabled={'const': True})
    props['id']['maximum'] = 12
    props['sectores_jefes']['items']['properties']['id']['maximum'] = 3
    world['items']['required'] += ['legacy_id', 'miniboss_enabled', 'final_boss_enabled', 'unicos', 'recurrentes']
    world.update(minItems=12, maxItems=12, examples=[data['worlds']])
    result['worlds'] = world
    enemy = base('enemies')
    props = enemy['items']['properties']
    props['runtime_ready'] = {'type': 'boolean'}
    props['pending'] = {'type': 'array', 'items': {'type': 'string'}, 'minItems': 1}
    props['estado']['enum'].append('pendiente')
    appearance = props['mundos']['patternProperties'].pop('^([1-9]|1[0-5])$')
    appearance['properties']['runtime_ready'] = {'type': 'boolean'}
    appearance['required'].append('runtime_ready')
    props['mundos']['patternProperties']['^([1-9]|1[0-2])$'] = appearance
    ready_fields = ['categoria', 'movimiento', 'disparo', 'puntos', 'drop', 'tamano']
    enemy['items']['required'] = ['id', 'familia', 'tipo', 'mundos', 'estado', 'runtime_ready']
    enemy['items']['allOf'] = [{'if': {'properties': {'runtime_ready': {'const': True}}},
                              'then': {'required': ready_fields},
                              'else': {'required': ['pending'], 'properties': {'estado': {'const': 'pendiente'}},
                                       'not': {'anyOf': [{'required': [field]} for field in ('movimiento', 'disparo')]}}}]
    enemy['examples'] = [[data['enemies'][0], next(e for e in data['enemies'] if not e['runtime_ready'])]]
    result['enemies'] = enemy
    boss = base('bosses')
    boss['items']['properties'].update(asset_id={'type': 'string', 'pattern': '^boss_w[0-9]{2}_[a-z0-9_]+$'},
                                       asset_world={'type': 'integer', 'minimum': 1, 'maximum': 14})
    boss['items']['properties']['mundo']['maximum'] = 12
    boss['items']['properties']['tipo'] = {'const': 'jefe'}
    boss['items']['required'] += ['mundo', 'tipo', 'asset_id', 'asset_world']
    boss['examples'] = [[data['bosses'][0]]]
    result['bosses'] = boss
    wave = base('waves')
    wave['properties']['mundo']['maximum'] = 12
    variants = wave['properties']['eventos']['items']['oneOf']
    variants[1]['properties']['tipo'] = {'const': 'alerta_jefe'}
    variants[1]['properties'].pop('escoltas')
    for variant in variants:
        variant['properties']['legacy_index'] = {'type': 'integer', 'minimum': 0}
        variant['required'].append('legacy_index')
    wave['examples'] = [dict(data['waves'][1], eventos=[data['waves'][1]['eventos'][0]])]
    result['waves'] = wave
    escape = base('escape')
    escape['properties']['id'] = {'const': 13}
    # Escape's inline event contracts share the same identity field as regular stages.
    for variant in escape.get('properties', {}).get('eventos', {}).get('items', {}).get('oneOf', []):
        variant['properties']['legacy_index'] = {'type': 'integer', 'minimum': 0}
        variant['required'].append('legacy_index')
    escape['properties']['fondo_transicion']['properties']['mundo_destino']['maximum'] = 12
    escape['examples'][0]['id'] = 13
    result['escape'] = escape
    shop = base('shop')
    shop['properties']['economia'].update(minItems=14, maxItems=14)
    result['shop'] = shop
    result['cosmetics'] = base('cosmetics')
    result['cosmetics']['examples'] = [[data['cosmetics'][0]]]
    save = base('save')
    save['title'] = 'Native profile v3 (edition-scoped campaign12 slot)'
    save['properties']['version'] = {'const': 3}
    for field in ('world', 'entry_world', 'lander_used_world'):
        save['properties'][field]['maximum'] = 13
    save['properties']['cleared']['items']['maximum'] = 12
    save['properties']['lab_boss']['maximum'] = 3
    result['save'] = save
    campaign_properties = {key: {'const': value} for key, value in data['campaign'].items()}
    result['campaign'] = {'$schema': 'https://json-schema.org/draft/2020-12/schema', 'type': 'object',
                          'properties': campaign_properties, 'required': list(campaign_properties),
                          'additionalProperties': False, 'examples': [data['campaign']]}
    result['campaign_aliases'] = {'$schema': 'https://json-schema.org/draft/2020-12/schema', 'type': 'object',
        'required': ['source_commit', 'aliases', 'pending'], 'additionalProperties': False,
        'properties': {'source_commit': {'type': 'string', 'pattern': '^[a-f0-9]{40}$'},
                       'aliases': {'type': 'object', 'minProperties': 1,
                                   'propertyNames': {'pattern': '^w[0-9]{2}_[a-z0-9_]+$'},
                                   'additionalProperties': {'type': 'string', 'pattern': '^w[0-9]{2}_[a-z0-9_]+$'}},
                       'pending': {'type': 'array', 'items': {'type': 'object',
                           'required': ['key', 'enemy', 'world', 'state', 'reason'], 'additionalProperties': False,
                           'properties': {'key': {'type': 'string'}, 'enemy': {'type': 'string'},
                                          'world': {'type': 'integer', 'minimum': 1, 'maximum': 12},
                                          'state': {'const': 'pending'}, 'reason': {'type': 'string', 'minLength': 1}}}}},
        'examples': [dict(data['aliases'], aliases={'w03_boss_boss_w03_tere_move': 'w04_boss_boss_w04_tere_move'},
                          pending=data['aliases']['pending'][:1])]}
    return result


def main():
    archive_originals()
    data = build()
    for name in ('campaign', 'worlds', 'enemies', 'bosses', 'escape', 'shop', 'cosmetics',
                 'balance_report', 'wave_schedule_migration', 'campaign_economy'):
        write(ROOT / f'data/{name}.json', data[name])
    for path in (ROOT / 'data/waves').glob('world_*.json'):
        if int(path.stem.split('_')[1]) not in data['waves']:
            path.unlink()
    for n, wave in data['waves'].items():
        write(ROOT / f'data/waves/world_{n:02}.json', wave)
    write(ROOT / 'assets/campaign_aliases.json', data['aliases'])
    for kind, schema in schemas(data).items():
        write(ROOT / f'data/schemas/{kind}.schema.json', schema)
    print('05A: 12 worlds + escape 13; 3 laboratory rooms; originals archived; deterministic migration complete.')


if __name__ == '__main__':
    main()
