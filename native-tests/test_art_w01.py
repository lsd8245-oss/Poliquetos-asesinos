"""World-one art must cover the real roster without changing actor geometry."""
import json
from pathlib import Path
import unittest
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


class WorldOneArtTests(unittest.TestCase):
    def test_errant_poses_fill_the_existing_square_collision_dimensions(self):
        for name,size in [('pision',32),('lacy',32),('syll',24),('phyll',32)]:
            for i in range(1,5):
                with Image.open(ROOT/f'assets/sprites/w01/w01_enemy_{name}_move_{i:02d}.png') as im:
                    x,y,right,bottom=im.convert('RGBA').getchannel('A').getbbox()
                self.assertGreaterEqual(right-x,size*0.7,name)
                self.assertGreaterEqual(bottom-y,size*0.7,name+' leaves invisible collision bands')

    def test_all_seven_actor_sprites_are_reviewed_pngs_at_actual_size(self):
        enemies = json.loads((ROOT / 'data/enemies.json').read_text())
        roster = [e for e in enemies if '1' in e['mundos']]
        self.assertEqual({e['id'] for e in roster}, {'hydroides','euphrosine','fabric','pision','lacy','syll','phyll'})
        manifest = {a['nombre']: a for a in json.loads((ROOT/'assets/assets_manifest.json').read_text())['assets']}
        for enemy in roster:
            key = f"w01_enemy_{enemy['id']}_move"
            a = manifest[key]
            self.assertEqual(a['tamano'], enemy['tamano'])
            with Image.open(ROOT/a['ruta']) as im:
                self.assertEqual(im.info.get('art_stage'), 'integrated-review', key)
                self.assertEqual(im.size, tuple(enemy['tamano']))
                rgba = im.convert('RGBA')
                colors = {p[:3] for p in rgba.getdata() if p[3]}
                self.assertGreater(len(colors), 3, key)
                self.assertLessEqual(len(colors), 16, key)
                self.assertEqual({p[3] for p in rgba.getdata()}, {0,255}, key)

    def test_boss_pieces_reconstruct_the_whole_png_without_overlap(self):
        root = ROOT/'assets/sprites/w01'
        for action, count in [('move',4), ('hit',2)]:
            for i in range(1,count+1):
                stem = 'w01_boss_boss_w01_nereis'
                with Image.open(root/f'{stem}_{action}_{i:02d}.png') as source:
                    whole = source.convert('RGBA')
                rebuilt = Image.new('RGBA', (180,120))
                for part,x in [('body',45), ('head',0), ('jaws',0)]:
                    self.assertTrue((root/f'{stem}_{part}_{action}_{i:02d}.png').is_file(), 'Articulated piece missing: '+part)
                    with Image.open(root/f'{stem}_{part}_{action}_{i:02d}.png') as source:
                        piece = source.convert('RGBA')
                    rebuilt.alpha_composite(piece,(x,0))
                # RGB under transparent pixels is irrelevant to render output.
                white = Image.new('RGBA',whole.size,'white')
                white.alpha_composite(whole)
                test = Image.new('RGBA',whole.size,'white')
                test.alpha_composite(rebuilt)
                self.assertEqual(test.tobytes(),white.tobytes())

    def test_wide_background_layers_have_matching_edges(self):
        for i in range(1,5):
            with Image.open(ROOT/f'assets/backgrounds/w01/w01_bg_layer{i}_idle_01.png') as im:
                self.assertEqual(im.size,(1280,336))
                self.assertEqual(im.crop((0,0,1,336)).tobytes(),im.crop((1279,0,1280,336)).tobytes())
