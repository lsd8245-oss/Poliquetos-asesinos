"""Campaign contracts: counts and scheduling are gameplay, not generator details."""
import importlib.util
import json
from collections import Counter
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


def read(name):
    return json.loads((ROOT / 'data' / name).read_text(encoding='utf8'))


class CampaignDataTests(unittest.TestCase):
    def test_schema_extensions_validate_real_content_and_reject_invalid_data(self):
        spec = importlib.util.spec_from_file_location('validator',ROOT/'scripts/validate-v2-data.py')
        validator = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(validator)
        for kind in ['worlds','enemies','bosses','combat','escape']:
            validator.validate(kind,read(kind+'.json'))
        for n in range(1,13): validator.validate('waves',read(f'waves/world_{n:02}.json'))
        bad = read('combat.json')
        bad['shot'][0]['damage'] = -1
        with self.assertRaises(Exception): validator.validate('combat',bad)
        bad = read('escape.json')
        bad['tramos'][0]['enemigos'] = 29
        with self.assertRaises(ValueError): validator.validate('escape',bad)

    def test_tables_and_bosses(self):
        worlds = read('worlds.json')
        self.assertEqual([w['enemigos_total'] for w in worlds], [90,125,135,135,150,162,162,200,200,245,285,250])
        self.assertEqual([w['duracion_hasta_jefe_seg'] for w in worlds], [180]*3+[210]*3+[240]*4+[270,330])
        bosses = {b['id']: b for b in read('bosses.json')}
        archive = {b['id']: b for b in read('archive/04a/bosses.json')}
        mapping = read('campaign.json')['legacy_boss_to_current']
        self.assertEqual(set(bosses), set(mapping.values()))
        for old, current in mapping.items():
            b, original = bosses[current], archive[old]
            self.assertEqual(b['vida'], original['vida'])
            self.assertEqual(b['fases'], original['fases'])
            self.assertEqual(b['segmentos'], original['segmentos'])
            self.assertEqual(b['fases'][0]['desde_pct'],100)
            self.assertEqual(b['fases'][-1]['hasta_pct'],0)
            self.assertGreaterEqual(b['minimo_seg'], .4*b['objetivo_seg'])
            for first, second in zip(b['fases'],b['fases'][1:]):
                self.assertEqual(first['hasta_pct'],second['desde_pct'])
        for w in worlds:
            self.assertFalse(w['miniboss_enabled'])
            self.assertTrue(w['final_boss_enabled'])
            self.assertNotIn('minijefe', w)
        self.assertEqual(len(worlds[-1]['sectores_jefes']),3)
        self.assertEqual([len(g['jefes']) for g in worlds[-1]['sectores_jefes']], [3,1,1])

    def test_exact_waves_carriers_composition_and_timings(self):
        enemies = {e['id']: e for e in read('enemies.json')}
        source_worlds = {w['id']: w for w in read('archive/04a/worlds.json')}
        for w in read('worlds.json'):
            original = source_worlds[w['legacy_id']]
            events = read(f"waves/world_{w['id']:02}.json")['eventos']
            source = read(f"archive/04a/waves/world_{w['legacy_id']:02}.json")['eventos']
            waves = [e for e in events if e['tipo']=='oleada']
            self.assertEqual(sum(e['cantidad'] for e in waves),w['enemigos_total'])
            self.assertEqual(Counter(e['item'] for e in waves if e.get('portadora')),Counter(rojo=2,verde=2,azul=2))
            self.assertEqual(len([e for e in events if e['tipo']=='escudo']),3)
            self.assertFalse(any(e['tipo']=='minijefe' for e in events))
            self.assertEqual(len({e['legacy_index'] for e in events}), len(events))
            self.assertEqual([e['t'] for e in events], sorted(e['t'] for e in events))
            counts = Counter()
            for e in waves:
                self.assertLess(e['t'],w['alerta_jefe_seg'])
                self.assertGreaterEqual(e['t'],10)
                self.assertGreaterEqual(e['cantidad'],4)
                self.assertLessEqual(e['cantidad'],20 if enemies[e['enemigo']]['categoria']=='enjambre' else 12)
                self.assertTrue(enemies[e['enemigo']]['mundos'][str(w['id'])]['runtime_ready'])
                old = source[e['legacy_index']]
                self.assertEqual({k:v for k,v in e.items() if k not in ('t','legacy_index')},
                                 {k:v for k,v in old.items() if k!='t'})
                counts[e['enemigo']] += e['cantidad']
            if w['id'] !=12:
                self.assertLessEqual(abs(sum(counts[e] for e in original['unicos'])-w['enemigos_total']*.6),.5)
                self.assertLessEqual(max(counts[e] for e in original['unicos'])-min(counts[e] for e in original['unicos']),1)
                self.assertLessEqual(max(counts[e] for e in original['recurrentes'])-min(counts[e] for e in original['recurrentes']),1)
            else:
                self.assertEqual(sum(counts[e] for e in original['unicos']),140)
                self.assertEqual(sum(counts[e] for e in original['recurrentes']),110)
            self.assertTrue(all(counts[k]>0 for k in original['unicos']))
            self.assertLess(max(b['t']-a['t'] for a,b in zip(waves,waves[1:])),60)
            self.assertTrue(any(original['minijefe_inicio_seg']<=e['t']<original['minijefe_inicio_seg']+60 for e in waves))
            self.assertEqual(next(e for e in events if e['tipo']=='alerta_jefe')['t'],w['alerta_jefe_seg'])

    def test_escape_and_seeded_lab(self):
        escape = read('escape.json')
        self.assertEqual((escape['duracion_seg'],escape['scroll_px_s'],escape['enemigos_total']),(300,120,90))
        self.assertEqual(escape['checkpoints'],[0,90,180,270])
        for section in escape['tramos']:
            self.assertEqual(sum(e['cantidad'] for e in escape['eventos'] if e['tipo']=='oleada' and section['inicio_seg']<=e['t']<section['fin_seg']),section['enemigos'])
        spec = importlib.util.spec_from_file_location('campaign',ROOT/'scripts/generate-campaign-v2.py')
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        a,b,c = module.build_campaign(123),module.build_campaign(123),module.build_campaign(456)
        self.assertEqual(a,b)
        self.assertNotEqual(a['waves'][14],c['waves'][14])
        self.assertEqual(a['waves'][1],c['waves'][1])

    def test_weapon_dps_and_all_behavior_codes(self):
        c = read('combat.json')
        self.assertEqual([x['dps'] for x in c['shot']],[10,13,16,20,24,29,34,40])
        self.assertEqual([x['dps'] for x in c['missile']],[4,6,8,10,12,14,17,20])
        for group in ['shot','missile']:
            for x in c[group]: self.assertAlmostEqual(x['damage']*x['count']/x['interval'],x['dps'])
        self.assertEqual([x['damage'] for x in c['bomb']],[50,80,120,170,230,300,380,500])
        self.assertEqual(set(c['movement']),{f'M{i}' for i in range(1,9)})
        self.assertEqual(set(c['fire_patterns']),{f'F{i}' for i in range(6)})

    def test_runtime_equipment_and_projectile_tuning(self):
        c = read('combat.json')
        self.assertEqual(c['gear']['net_capacity'],5)
        self.assertEqual(c['gear']['magnet_speed'],260)
        self.assertEqual(c['gear']['niskin_interval'],20)
        self.assertEqual(c['friendly_projectile']['ttl'],3)
        self.assertEqual(c['friendly_projectile']['size'],[10,4])


if __name__ == '__main__': unittest.main()
