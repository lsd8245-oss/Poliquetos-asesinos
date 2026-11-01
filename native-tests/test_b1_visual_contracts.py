"""B1 pixel/immutability contracts; screenshots still decide artistic acceptance.

These checks inspect decoded PNGs, not a generator's claimed success. They do
not prove visual readability, animation quality, runtime synchronization or FPS.
The metadata deliberately permits review artwork without claiming final approval.
"""
import hashlib
import json
from pathlib import Path
import unittest

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


def frames(asset):
    result = []
    for index in range(1, asset['cuadros'] + 1):
        path = ROOT / asset['ruta'].replace('_01.png', f'_{index:02}.png')
        with Image.open(path) as source:
            result.append((source.convert('RGBA'), dict(source.info)))
    return result


def visible_bytes(image):
    """Ignore RGB hidden under alpha=0 when checking actual animation."""
    return bytes(channel for pixel in image.getdata()
                 for channel in (pixel if pixel[3] else (0, 0, 0, 0)))


class B1VisualContracts(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.assets = {
            a['nombre']: a
            for a in json.loads((ROOT / 'assets/assets_manifest.json').read_text())['assets']
            if a['mundo'] == 1
        }

    def test_gameplay_data_audio_and_existing_creature_pngs_match_accepted_base(self):
        fixture = json.loads((ROOT / 'native-tests/b1_preserved_sha256.json').read_text())
        self.assertEqual(fixture['baseline'], 'd31d3406f07868942bbd3f594bee78d0f12d63b7')
        for path, expected in fixture['sha256'].items():
            with self.subTest(path=path):
                self.assertEqual(hashlib.sha256((ROOT / path).read_bytes()).hexdigest(), expected,
                                 'B1 changed preserved gameplay/data/audio/creature asset: ' + path)
        # Adding a second data/audio source is also a scope change.
        for folder in ('data', 'assets/audio'):
            actual = {str(p.relative_to(ROOT)) for p in (ROOT / folder).rglob('*')
                      if p.is_file() and not p.name.endswith('.import')}
            expected = {p for p in fixture['sha256'] if p.startswith(folder + '/')}
            self.assertEqual(actual, expected, folder)

    def test_bullets_effects_and_pickups_are_review_art_with_pixel_silhouettes(self):
        selected = [a for key, a in self.assets.items()
                    if a['tipo'] in ('bullet', 'fx') or key.startswith('w01_ui_item_')]
        self.assertGreaterEqual(len(selected), 22, 'Missing existing W01 gameplay art')
        for asset in selected:
            key = asset['nombre']
            with self.subTest(asset=key):
                decoded = frames(asset)
                visible_colors = set()
                for index, (image, metadata) in enumerate(decoded):
                    self.assertEqual(image.size, tuple(asset['tamano']), key)
                    self.assertEqual(metadata.get('asset_name'), key)
                    self.assertEqual(metadata.get('art_stage'), 'integrated-review', key)
                    self.assertEqual(asset['estado'], 'placeholder', 'User approval is still pending')
                    self.assertEqual(metadata.get('status'), 'placeholder')
                    self.assertNotIn('Original flat labelled rectangle', metadata.get('notice', ''))
                    pixels = list(image.getdata())
                    alphas = {p[3] for p in pixels}
                    self.assertTrue(alphas <= {0, 255}, key + ' has smoothed alpha')
                    visible_colors.update(p[:3] for p in pixels if p[3])
                    box = image.getchannel('A').getbbox()
                    if box is None and asset['tipo'] == 'fx' and index == len(decoded) - 1:
                        # A final transparent frame is a legitimate disappearance.
                        continue
                    self.assertIsNotNone(box, key)
                    self.assertEqual(alphas, {0, 255}, key)
                    # A transparent border alone does not turn a solid rectangle
                    # into a shaped actor: the tight alpha box must contain gaps.
                    alpha = image.getchannel('A').crop(box)
                    occupied = sum(v > 0 for v in alpha.getdata())
                    if asset['tipo'] != 'fx' or occupied > 4:
                        self.assertLess(occupied, alpha.width * alpha.height,
                                        key + ' has a rectangular opaque body')
                self.assertGreater(len(visible_colors), 2, key)
                self.assertLessEqual(len(visible_colors), 16, key)
                self.assertGreater(asset['fps'], 0, key)
                unique = {visible_bytes(im) for im, _ in decoded}
                self.assertGreaterEqual(len(unique), 4 if asset['tipo'] == 'fx' else 2,
                                        key + ' repeats static artwork')

    def test_real_projectile_families_have_different_silhouettes(self):
        # These names map to existing renderer kinds, not invented attacks.
        silhouettes = {}
        for name in ('shot', 'enemy', 'missile', 'bomb', 'homing', 'bounce', 'laser'):
            image = frames(self.assets[f'w01_bullet_{name}_move'])[0][0]
            alpha = image.getchannel('A')
            mask = alpha.crop(alpha.getbbox()).resize((32, 32), Image.Resampling.NEAREST).tobytes()
            self.assertTrue(mask not in silhouettes,
                            f'{name} has the same normalized silhouette as {silhouettes.get(mask)}')
            silhouettes[mask] = name

    def test_fx_do_not_reuse_one_sheet_for_every_action(self):
        sheets = {}
        for name in ('explosion', 'bomb', 'hit', 'bubble', 'spark', 'trail', 'flash'):
            key = f'w01_fx_{name}_burst'
            decoded = frames(self.assets[key])
            signature = tuple(visible_bytes(im.resize((32, 32), Image.Resampling.NEAREST))
                              for im, _ in decoded)
            self.assertTrue(signature not in sheets, key + ' reuses another FX sheet')
            sheets[signature] = key

    def test_modular_scenery_is_bounded_transparent_and_really_animated(self):
        modules = {
            'coast_pillars_idle', 'ruin_arch_idle', 'wreck_truss_idle', 'coast_rocks_idle',
            'algae_sway', 'chain_sway', 'fish_swim', 'bubble_rise',
            'caustic_drift', 'plankton_drift',
        }
        actual = {key.removeprefix('w01_bg_') for key, asset in self.assets.items()
                  if asset['tipo'] == 'bg' and '_bg_layer' not in key}
        self.assertEqual(actual, modules)
        for name in sorted(modules):
            key = 'w01_bg_' + name
            asset = self.assets[key]
            with self.subTest(asset=key):
                self.assertLessEqual(asset['tamano'][0], 320)
                self.assertLessEqual(asset['tamano'][1], 144)
                decoded = frames(asset)
                for image, _ in decoded:
                    self.assertEqual(image.size, tuple(asset['tamano']), key)
                    self.assertEqual(set(image.getchannel('A').getdata()), {0, 255}, key)
                    self.assertIsNotNone(image.getchannel('A').getbbox(), key)
                with Image.open(ROOT / asset['ruta']) as original:
                    self.assertEqual(original.mode, 'RGBA', key)
                if not name.endswith('_idle'):
                    self.assertGreater(asset['fps'], 0, key)
                    self.assertGreaterEqual(asset['cuadros'], 4, key)
                    self.assertGreaterEqual(len({visible_bytes(im) for im, _ in decoded}), 3,
                                            key + ' lacks visible motion across its frames')

    def test_w01_atlas_rectangles_are_bounded_and_never_overlap(self):
        atlas = json.loads((ROOT / 'assets/atlas/w01.json').read_text())
        width, height = atlas['tamano']
        self.assertLessEqual(max(width, height), 2048)
        rectangles = []
        for key, rect in atlas['frames'].items():
            x, y, w, h = (rect[field] for field in ('x', 'y', 'w', 'h'))
            self.assertGreater(w, 0, key)
            self.assertGreater(h, 0, key)
            self.assertGreaterEqual(min(x, y), 0, key)
            self.assertLessEqual(x + w, width, key)
            self.assertLessEqual(y + h, height, key)
            rectangles.append((x, y, x + w, y + h, key))
        self.assertTrue(rectangles)
        rectangles.sort()
        for index, (x, y, right, bottom, key) in enumerate(rectangles):
            for other_x, other_y, other_right, other_bottom, other_key in rectangles[index + 1:]:
                if other_x >= right:
                    break
                overlaps = x < other_right and y < other_bottom and other_y < bottom
                self.assertFalse(overlaps, key + ' overlaps ' + other_key)


if __name__ == '__main__':
    unittest.main()
