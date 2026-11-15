"""05A contract regressions, including historical identity and negative validation."""
import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
MAP = {1: 1, 2: 2, 4: 3, 5: 4, 7: 5, 8: 6, 9: 7,
       10: 8, 11: 9, 12: 10, 13: 11, 14: 12, 15: 13}


def read(name, archive=False):
    return json.loads((ROOT / 'data' / ('archive/04a/' if archive else '') / name).read_text())


def validator():
    spec = importlib.util.spec_from_file_location('campaign12_validator', ROOT / 'scripts/validate-v2-data.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class Campaign12DataTests(unittest.TestCase):
    def test_twelve_worlds_and_escape(self):
        worlds = read('worlds.json')
        self.assertEqual([w['id'] for w in worlds], list(range(1, 13)))
        self.assertEqual([w['legacy_id'] for w in worlds], list(MAP)[:-1])
        self.assertEqual([w['acto'] for w in worlds], [1]*3 + [2]*3 + [3]*5 + [4])
        self.assertEqual(read('escape.json')['id'], 13)
        campaign = read('campaign.json')
        self.assertEqual((campaign['version'], campaign['world_count'], campaign['escape_id'],
                          campaign['laboratory_id'], campaign['lab_encounters']), (3, 12, 13, 12, 3))
        self.assertEqual(campaign['old_to_new'], {str(k): v for k, v in MAP.items()})
        self.assertEqual(campaign['removed_world_destinations'], {'3': 2, '6': 4})
        self.assertEqual(campaign['legacy_lab_to_new'], {'0': 0, '1': 1, '2': 1, '3': 2, '4': 3})

    def test_minibosses_disabled_and_all_surviving_finals_active(self):
        bosses = {b['id']: b for b in read('bosses.json')}
        expected = []
        for w in read('worlds.json'):
            self.assertFalse(w.get('miniboss_enabled', True))
            self.assertTrue(w.get('final_boss_enabled', False))
            self.assertNotIn('minijefe', w)
            expected.extend(w['jefes'])
            for key in w['jefes']:
                self.assertTrue(key.startswith(f"boss_w{w['id']:02}_"))
                self.assertEqual(bosses[key]['mundo'], w['id'])
        self.assertEqual(set(expected), set(bosses))
        self.assertTrue(all(b['tipo'] == 'jefe' and 'epitok' not in b['id'] for b in bosses.values()))

    def test_catalogue_exact_additions_and_pending_species(self):
        proposal = json.loads((ROOT / 'docs/planificacion/lista_12_mundos_propuesta.json').read_text())
        enemies = {e['id']: e for e in read('enemies.json')}
        for w, p in zip(read('worlds.json'), proposal['mundos']):
            self.assertEqual(w['unicos'], p['comunes_originales'] + p['comunes_agregados'])
            self.assertEqual(w['recurrentes'], p['recurrentes_originales'] + [p['recurrente_agregado']])
            self.assertEqual(w['enemigos_total'], p['enemigos_etapa_presupuesto'])
            for role, ids in [('unico', w['unicos']), ('recurrente', w['recurrentes'])]:
                for key in ids:
                    self.assertEqual(enemies[key]['mundos'][str(w['id'])]['rol'], role)
        self.assertFalse(enemies['mech_oenone']['runtime_ready'])
        self.assertFalse(enemies['eulalia']['runtime_ready'])
        for enemy in enemies.values():
            self.assertTrue(set(map(int, enemy['mundos'])).issubset(range(1, 13)))
            if not enemy['runtime_ready']:
                self.assertEqual(enemy['estado'], 'pendiente')
                self.assertNotIn('movimiento', enemy)
                self.assertNotIn('disparo', enemy)

    def test_laboratory_three_consecutive_rooms_preserves_robot_group(self):
        lab = read('worlds.json')[-1]
        self.assertEqual([s['id'] for s in lab['sectores_jefes']], [1, 2, 3])
        self.assertEqual([len(s['jefes']) for s in lab['sectores_jefes']], [3, 1, 1])
        self.assertEqual([s['jefes'][0].split('_', 2)[2] for s in lab['sectores_jefes']],
                         ['robot_pinza', 'scientist', 'eunice_titan'])
        self.assertEqual(lab['base_monedas'], 4800)
        self.assertEqual(lab['jefe_objetivo_seg'], 390)

    def test_waves_keep_identity_composition_and_fill_removed_window(self):
        files = sorted((ROOT / 'data/waves').glob('world_*.json'))
        self.assertEqual([p.stem for p in files], [f'world_{n:02}' for n in range(1, 13)])
        for w in read('worlds.json'):
            old = read(f"waves/world_{w['legacy_id']:02}.json", True)['eventos']
            events = read(f"waves/world_{w['id']:02}.json")['eventos']
            self.assertFalse(any(e['tipo'] == 'minijefe' or 'escoltas' in e for e in events))
            self.assertEqual([e['t'] for e in events], sorted(e['t'] for e in events))
            waves = [e for e in events if e['tipo'] == 'oleada']
            original = [e for e in old if e['tipo'] == 'oleada']
            self.assertEqual(sum(e['cantidad'] for e in waves), w['enemigos_total'])
            self.assertEqual([e['legacy_index'] for e in waves],
                             [i for i, e in enumerate(old) if e['tipo'] == 'oleada'])
            for new, prior in zip(waves, original):
                self.assertEqual({k: v for k, v in new.items() if k not in ('t', 'legacy_index')},
                                 {k: v for k, v in prior.items() if k != 't'})
                self.assertEqual(old[new['legacy_index']]['enemigo'], new['enemigo'])
            self.assertEqual((waves[0]['t'], waves[-1]['t']), (10, original[-1]['t']))
            self.assertTrue(any(old[0]['t'] < e['t'] < w['alerta_jefe_seg'] and
                                read('worlds.json', True)[w['legacy_id']-1]['minijefe_inicio_seg'] <= e['t'] <
                                read('worlds.json', True)[w['legacy_id']-1]['minijefe_inicio_seg'] + 60
                                for e in waves))

    def test_aliases_resolve_original_assets_without_transitive_resolution(self):
        aliases = json.loads((ROOT / 'assets/campaign_aliases.json').read_text())
        original = {a['nombre']: a for a in json.loads((ROOT / 'assets/assets_manifest.json').read_text())['assets']}
        self.assertIn('source_commit', aliases)
        for active, source in aliases['aliases'].items():
            self.assertIn(source, original)
            self.assertTrue((ROOT / original[source]['ruta']).is_file())
            # Source keys are resolved in the original manifest, never recursively as active keys.
            self.assertRegex(active, r'^w\d\d_')
        self.assertEqual(aliases['aliases']['w03_boss_boss_w03_tere_move'], 'w04_boss_boss_w04_tere_move')
        self.assertEqual(aliases['aliases']['w01_enemy_sabellaria_move'], 'w06_enemy_sabellaria_move')
        pending = {p['key'] for p in aliases['pending']}
        self.assertIn('w01_enemy_eulalia_move', pending)
        self.assertNotIn('w01_enemy_eulalia_move', aliases['aliases'])
        self.assertEqual(aliases['aliases']['w13_bg_layer1_idle'], 'w15_bg_layer1_idle')

    def test_preserved_hp_prices_and_explicit_economy(self):
        old_bosses = {b['id']: b for b in read('bosses.json', True)}
        for boss in read('bosses.json'):
            for field in ['vida', 'vida_base', 'fases', 'parametros', 'recompensa_extra']:
                self.assertEqual(boss.get(field), old_bosses[boss['asset_id']].get(field))
        shop, old_shop = read('shop.json'), read('shop.json', True)
        self.assertEqual(shop['mejoras'], old_shop['mejoras'])
        self.assertEqual(shop['equipo'], old_shop['equipo'])
        self.assertTrue(all(row['vida_minijefe'] == 0 for row in shop['economia']))
        self.assertEqual([row['mundo'] for row in shop['economia']][-3:], ['12 (4.1)', '12 (4.2)', '12 (4.3)'])
        report = read('campaign_economy.json')
        self.assertEqual(report['status'], 'provisional_05c')
        self.assertGreater(report['before']['total'], report['after']['total'])

    def test_archive_is_source_commit_bytes_and_migration_idempotent(self):
        archive = ROOT / 'data/archive/04a'
        manifest = read('archive/04a/archive_manifest.json')
        for relative, digest in manifest['sha256'].items():
            path = archive / relative
            self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), digest)
            source = 'assets/assets_manifest.json' if relative == 'assets_manifest.json' else 'data/' + relative
            baseline = subprocess.check_output(['git', 'show', f"{manifest['source_commit']}:{source}"], cwd=ROOT)
            self.assertEqual(path.read_bytes(), baseline)
        before = {p: p.read_bytes() for p in (ROOT / 'data').rglob('*.json')}
        before[ROOT / 'assets/campaign_aliases.json'] = (ROOT / 'assets/campaign_aliases.json').read_bytes()
        subprocess.run(['python3', 'scripts/migrate-campaign-12.py'], cwd=ROOT, check=True, capture_output=True)
        self.assertEqual(before, {p: p.read_bytes() for p in before})

    def test_validator_rejects_duplicate_world_wrong_escape_pending_spawn_and_miniboss(self):
        v = validator()
        data = v.load_campaign()
        v.validate_campaign(data)
        mutations = [lambda d: d['worlds'][1].update(id=1),
                     lambda d: d['escape'].update(id=15),
                     lambda d: d['worlds'][0].update(final_boss_enabled=False),
                     lambda d: d['worlds'][-1]['sectores_jefes'][1].update(id=3),
                     lambda d: d['waves'][1]['eventos'][0].update(enemigo='eulalia'),
                     lambda d: d['waves'][1]['eventos'].append({'tipo': 'minijefe', 'id': 'mini_w01_pision', 't': 60}),
                     lambda d: d['aliases']['aliases'].update(w01_enemy_hydroides_move='w99_missing_move'),
                     lambda d: d['aliases']['aliases'].update(w01_enemy_hydroides_move='w01_enemy_phyll_move'),
                     lambda d: d['bosses'][0].update(mundo=12),
                     lambda d: d['bosses'][0].update(vida=d['bosses'][0]['vida'] + 1),
                     lambda d: d['worlds'][0]['unicos'].append('euphrosine'),
                     lambda d: d['shop']['economia'][0].update(base_monedas=900),
                     lambda d: d['shop']['economia'][0].update(vida_minijefe=975),
                     lambda d: d['waves'][1]['eventos'][0].update(legacy_index=9),
                     lambda d: d['waves'][1]['eventos'][0].update(cantidad=20)]
        for mutation in mutations:
            with self.subTest(mutation=mutation):
                bad = copy.deepcopy(data)
                mutation(bad)
                with self.assertRaises((ValueError, v.ValidationError)):
                    v.validate_campaign(bad)

    def test_save_schema_accepts_campaign12_and_rejects_obsolete_active_ids(self):
        profile = {'version': 3, 'edition': 'normal', 'slot': 1, 'difficulty': 'normal',
                   'world': 13, 'lab_boss': 0, 'credits': 0, 'upgrades': {},
                   'equipment': {'sonar': True}, 'weapons': {'shot': 1, 'missile': 1, 'bomb': 1},
                   'bombs': 2, 'skins': ['original'], 'skin': 'original',
                   'colors': {'hull': '#ffffff', 'lights': '#ffffff', 'trail': '#ffffff'},
                   'deaths': {}, 'time': 0, 'cleared': [12], 'seed': 1, 'completed': False}
        v = validator()
        v.validate('save', profile)
        for field, value in [('version', 2), ('world', 15), ('lab_boss', 4), ('cleared', [14])]:
            with self.subTest(field=field):
                bad = copy.deepcopy(profile)
                bad[field] = value
                with self.assertRaises(v.ValidationError):
                    v.validate('save', bad)


if __name__ == '__main__':
    unittest.main()
