"""Validate the artist-facing PNG/atlas contract, not generated source text."""
import json
from pathlib import Path
import unittest
import os
import shutil
import subprocess
import tempfile
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]

def read_image(path):
    with Image.open(path) as image:
        return image.copy()

class AssetsTest(unittest.TestCase):
    def test_native_asset_manifest_exists(self):
        self.assertTrue((ROOT / 'assets/assets_manifest.json').is_file(), 'native PNG manifest is missing')

    def test_complete_frames_and_bounded_atlases(self):
        manifest = json.loads((ROOT / 'assets/assets_manifest.json').read_text())
        names = set()
        atlases = {}
        atlas_images = {}
        for world in range(1, 16):
            atlas = json.loads((ROOT / f'assets/atlas/w{world:02}.json').read_text())
            image = read_image(ROOT / 'assets/atlas' / atlas['imagen'])
            self.assertEqual(image.size, tuple(atlas['tamano']))
            self.assertLessEqual(max(image.size), 2048)
            for key, rect in atlas['frames'].items():
                self.assertGreaterEqual(rect['x'], 0, key)
                self.assertGreaterEqual(rect['y'], 0, key)
                self.assertLessEqual(rect['x'] + rect['w'], image.width, key)
                self.assertLessEqual(rect['y'] + rect['h'], image.height, key)
            for layer in range(1, 5):
                self.assertIn(f'w{world:02}_bg_layer{layer}_idle', atlas['animaciones'])
            atlases[world] = atlas
            atlas_images[world] = image
        for asset in manifest['assets']:
            key = asset['nombre']
            self.assertNotIn(key, names)
            names.add(key)
            self.assertEqual(asset['estado'], 'placeholder')
            animation = atlases[asset['mundo']]['animaciones'][key]
            self.assertEqual(len(animation['frames']), asset['cuadros'])
            if asset['tipo'] in ('enemy', 'mini', 'boss'):
                self.assertIn(asset['cuadros'], range(2, 5))
                self.assertIn(asset['fps'], range(8, 13))
            if asset['tipo'] == 'fx':
                self.assertIn(asset['cuadros'], range(6, 9))
            for index, frame_key in enumerate(animation['frames'], 1):
                path = ROOT / asset['ruta'].replace('_01.png', f'_{index:02}.png')
                image = read_image(path)
                self.assertEqual(image.size, tuple(asset['tamano']), key)
                self.assertEqual(image.info.get('status'), 'placeholder', key)
                self.assertEqual(image.info.get('asset_name'), key, key)
                rect = atlases[asset['mundo']]['frames'][frame_key]
                self.assertEqual(image.tobytes(), atlas_images[asset['mundo']].crop((rect['x'], rect['y'], rect['x']+rect['w'], rect['y']+rect['h'])).tobytes())
                if asset['tipo'] == 'bg':
                    self.assertGreaterEqual(image.height, 336)
                    self.assertEqual(image.width % 640, 0)
                    self.assertEqual(image.crop((0,0,1,image.height)).tobytes(), image.crop((image.width-1,0,image.width,image.height)).tobytes())
        for shared in ('ship_original_move', 'panel_idle', 'pixel_idle'):
            self.assertIn('w01_ui_' + shared, names)

    def test_bitmap_font_covers_ascii_and_spanish(self):
        metadata = json.loads((ROOT / 'assets/ui/bitmap_font.json').read_text())
        font = read_image(ROOT / 'assets/ui' / metadata['imagen'])
        for char in ''.join(chr(c) for c in range(32,127)) + 'áéíóúüñÁÉÍÓÚÜÑ¿¡':
            self.assertIn(char, metadata['glyphs'])
            x,y,w,h = metadata['glyphs'][char]
            self.assertLessEqual(x+w, font.width)
            self.assertLessEqual(y+h, font.height)
            if char != ' ':
                self.assertIsNotNone(font.crop((x,y,x+w,y+h)).getbbox(), char)

    def test_individual_png_replacement_precedes_atlas_fallback(self):
        godot = shutil.which('godot')
        if not godot:
            self.skipTest('Godot binary unavailable')
        manifest = json.loads((ROOT / 'assets/assets_manifest.json').read_text())
        ship = next(a for a in manifest['assets'] if a['nombre'] == 'w01_ui_ship_original_move')
        with tempfile.TemporaryDirectory(prefix='poli-assets-') as temporary:
            fixture = Path(temporary)
            (fixture / 'src/core').mkdir(parents=True)
            (fixture / 'assets/atlas').mkdir(parents=True)
            (fixture / 'assets/ui').mkdir(parents=True)
            shutil.copy2(ROOT / 'src/core/assets.gd', fixture / 'src/core/assets.gd')
            for name in ('w01.png', 'w01.json'):
                shutil.copy2(ROOT / 'assets/atlas' / name, fixture / 'assets/atlas' / name)
            for name in ('bitmap_font.png', 'bitmap_font.json'):
                shutil.copy2(ROOT / 'assets/ui' / name, fixture / 'assets/ui' / name)
            (fixture / 'assets/assets_manifest.json').write_text(json.dumps({'version':2,'assets':[ship]}))
            (fixture / 'project.godot').write_text('config_version=5\n[application]\nconfig/name="Asset contract fixture"\n')
            # A same-size artist replacement with no PNG metadata or code change.
            replacement = fixture / ship['ruta']
            Image.new('RGBA', (48,24), (12,34,56,255)).save(replacement)
            (fixture / 'check.gd').write_text('''extends SceneTree
const Assets = preload("res://src/core/assets.gd")
func _init():
    var assets = Assets.new()
    assets.load_all()
    var replacement = assets.get_texture("w01_ui_ship_original_move").get_image()
    assert(replacement.get_pixel(0,0) == Color8(12,34,56,255))
    DirAccess.remove_absolute("res://assets/ui/w01_ui_ship_original_move_01.png")
    assets = Assets.new()
    assets.load_all()
    var fallback = assets.get_texture("w01_ui_ship_original_move")
    assert(fallback is AtlasTexture)
    assert(fallback.region.size == Vector2(48,24))
    assert(fallback.get_image().get_pixel(0,0) == Color8(61,116,139,255))
    print("Replacement and atlas fallback passed")
    quit(0)
''')
            env = dict(os.environ, XDG_DATA_HOME=str(fixture / 'user'), XDG_CONFIG_HOME=str(fixture / 'config'), XDG_CACHE_HOME=str(fixture / 'cache'))
            result = subprocess.run([godot,'--headless','--path',str(fixture),'--script','check.gd'],capture_output=True,text=True,env=env,timeout=15)
            self.assertEqual(result.returncode, 0, result.stdout+result.stderr)
            self.assertIn('Replacement and atlas fallback passed', result.stdout)

    def test_campaign_data_sprite_coverage(self):
        if not (ROOT / 'data/worlds.json').exists():
            self.skipTest('native campaign data not generated yet')
        names = {a['nombre'] for a in json.loads((ROOT / 'assets/assets_manifest.json').read_text())['assets']}
        raw = json.loads((ROOT / 'data/worlds.json').read_text())
        worlds = raw.get('mundos', raw.get('worlds', [])) if isinstance(raw,dict) else raw
        for world in worlds:
            number = world['id']
            for enemy in world.get('unicos', []) + world.get('recurrentes', []):
                self.assertIn(f'w{number:02}_enemy_{enemy}_move', names)
            if world.get('mini_tipo'):
                self.assertIn(f"w{number:02}_mini_{world['mini_tipo']}_move", names)
        raw = json.loads((ROOT / 'data/bosses.json').read_text())
        bosses = raw.get('jefes', raw.get('bosses', [])) if isinstance(raw,dict) else raw
        for boss in bosses:
            if boss.get('tipo') == 'minijefe':
                continue
            self.assertIn(f"w{boss['mundo']:02}_boss_{boss['id']}_move", names)

if __name__ == '__main__':
    unittest.main()
