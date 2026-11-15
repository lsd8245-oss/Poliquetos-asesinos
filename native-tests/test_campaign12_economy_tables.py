"""Current economy tables must use twelve-world rewards, without editing prices."""
import csv
import importlib.util
import json
from pathlib import Path
import shutil
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class Campaign12EconomyTables(unittest.TestCase):
    def test_generator_writes_fourteen_visits_and_actual_budget(self):
        spec = importlib.util.spec_from_file_location('economy_tables', ROOT/'scripts/generate-balance-v2.py')
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        with tempfile.TemporaryDirectory() as temp:
            output = Path(temp)
            (output/'data').mkdir(); (output/'docs').mkdir()
            for name in ('shop', 'worlds', 'bosses', 'campaign', 'campaign_economy'):
                shutil.copy2(ROOT/'data'/f'{name}.json', output/'data'/f'{name}.json')
            prices_before = (output/'data/shop.json').read_bytes()
            module.ROOT = output
            module.generate()
            with (output/'docs/balance_sheet.csv').open() as handle:
                visits = list(csv.DictReader(handle))
            self.assertEqual(len(visits), 14)
            self.assertEqual([row['mundo'] for row in visits[-3:]], ['12 (4.1)', '12 (4.2)', '12 (4.3)'])
            self.assertEqual(float(visits[-1]['acumulado_con_bono']), 22680)
            self.assertEqual(float(visits[-1]['acumulado']), 19640)
            self.assertEqual([float(row['ingreso_ideal']) for row in visits[-3:]], [4320, 1920, 2400])
            self.assertTrue(all(float(row['vida_minijefe']) == 0 for row in visits))
            self.assertEqual(float(visits[0]['monedas_etapa']), 225)
            self.assertEqual(float(visits[0]['recompensa_jefe']), 120)
            self.assertEqual(float(visits[0]['ingreso_ideal']), 405)
            self.assertEqual(float(visits[0]['vida_jefe_actual']), 2319)
            with (output/'docs/shop_sheet.csv').open() as handle:
                purchases = list(csv.DictReader(handle))
            self.assertEqual(sum(int(row['costo']) for row in purchases), 30450)
            self.assertEqual((output/'data/shop.json').read_bytes(), prices_before)


if __name__ == '__main__':
    unittest.main()
