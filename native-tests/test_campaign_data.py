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
        for n in range(1,15): validator.validate('waves',read(f'waves/world_{n:02}.json'))
        bad = read('combat.json')
        bad['shot'][0]['damage'] = -1
        with self.assertRaises(Exception): validator.validate('combat',bad)
        bad = read('escape.json')
        bad['tramos'][0]['enemigos'] = 29
        with self.assertRaises(ValueError): validator.validate('escape',bad)

    def test_tables_and_bosses(self):
        worlds = read('worlds.json')
        self.assertEqual([w['enemigos_total'] for w in worlds], [90,125,135,135,135,150,150,162,162,200,200,245,285,250])
        self.assertEqual([w['duracion_hasta_jefe_seg'] for w in worlds], [180]*4+[210]*4+[240]*4+[270,330])
        bosses = {b['id']: b for b in read('bosses.json')}
        hp = [1750,2100,2450,3300,3700,4100,5150,6300,6100,6550,7000,7500,9950,35750]
        minis = [975,1170,1365,1560,1755,1950,2145,2340,2535,2730,2925,3120,3315,3510]
        for w, expected, mini in zip(worlds,hp,minis):
            self.assertEqual(sum(bosses[k]['vida'] for k in w['jefes']), expected)
            self.assertEqual(bosses[w['minijefe']]['vida'], mini)
            for key in w['jefes']:
                b = bosses[key]
                self.assertEqual(b['fases'][0]['desde_pct'],100)
                self.assertEqual(b['fases'][-1]['hasta_pct'],0)
                self.assertGreaterEqual(b['minimo_seg'], .4*b['objetivo_seg'])
                for a,z in zip(b['fases'],b['fases'][1:]): self.assertEqual(a['hasta_pct'],z['desde_pct'])
        self.assertEqual(len(worlds[-1]['sectores_jefes']),4)
        self.assertEqual([len(g['jefes']) for g in worlds[-1]['sectores_jefes']], [3,1,1,1])

    def test_exact_waves_carriers_composition_and_timings(self):
        enemies = {e['id']: e for e in read('enemies.json')}
        for w in read('worlds.json'):
            events = read(f"waves/world_{w['id']:02}.json")['eventos']
            waves = [e for e in events if e['tipo']=='oleada']
            self.assertEqual(sum(e['cantidad'] for e in waves),w['enemigos_total'])
            self.assertEqual(sum(e['cantidad'] for e in waves if e['t']<w['minijefe_inicio_seg']), round(w['enemigos_total']*.4))
            self.assertEqual(Counter(e['item'] for e in waves if e.get('portadora')),Counter(rojo=2,verde=2,azul=2))
            self.assertEqual(len([e for e in events if e['tipo']=='escudo']),3)
            counts = Counter()
            for e in waves:
                self.assertTrue(e['t'] < w['minijefe_inicio_seg'] or e['t']>=w['minijefe_inicio_seg']+60)
                self.assertLess(e['t'],w['alerta_jefe_seg'])
                self.assertGreaterEqual(e['t'],10)
                self.assertGreaterEqual(e['cantidad'],4)
                self.assertLessEqual(e['cantidad'],20 if enemies[e['enemigo']]['categoria']=='enjambre' else 12)
                if e['enemigo'] in w['recurrentes']: self.assertGreaterEqual(e['t'],w['duracion_hasta_jefe_seg']*.25)
                counts[e['enemigo']] += e['cantidad']
            if w['id'] !=14:
                self.assertLessEqual(abs(sum(counts[e] for e in w['unicos'])-w['enemigos_total']*.6),.5)
                self.assertLessEqual(max(counts[e] for e in w['unicos'])-min(counts[e] for e in w['unicos']),1)
                self.assertLessEqual(max(counts[e] for e in w['recurrentes'])-min(counts[e] for e in w['recurrentes']),1)
            else:
                self.assertEqual(sum(counts[e] for e in w['unicos']),140)
                self.assertEqual(sum(counts[e] for e in w['recurrentes']),110)
            self.assertTrue(all(any(e['enemigo']==k and e['t']<w['minijefe_inicio_seg'] for e in waves) for k in w['unicos']))
            mini = next(e for e in events if e['tipo']=='minijefe')
            self.assertEqual(mini['t'],w['minijefe_inicio_seg'])
            self.assertEqual(mini['escoltas']['cantidad'],2)
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
