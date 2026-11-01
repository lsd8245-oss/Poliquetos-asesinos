"""Validate concept deliverables, not artistic approval or game integration."""
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent


def rgba(name):
    im = Image.open(ROOT / (name + '.png')).convert('RGBA')
    im.load()
    return im


def pixels(im):
    return list(im.getdata())


def verify():
    checks = []
    for name in ['cientifica', 'industrial', 'expedicion']:
        key = 'A_nave_' + name
        im = rgba(key + '_48x24')
        assert im.size == (48, 24)
        colors = {p[:3] for p in pixels(im) if p[3]}
        assert 2 <= len(colors) <= 16
        assert {p[3] for p in pixels(im)} == {0, 255}
        enlarged = rgba(key + '_x8')
        assert enlarged.tobytes() == im.resize((384, 192), Image.Resampling.NEAREST).tobytes()
        checks.append({'asset': key, 'colors': len(colors), 'size': list(im.size), 'alpha_binary': True, 'nearest_x8': True})
    union = set()
    bases = []
    for i in range(1, 4):
        im = rgba(f'B_hydroides_move_{i:02d}')
        assert im.size == (48, 48)
        union |= {p[:3] for p in pixels(im) if p[3]}
        assert {p[3] for p in pixels(im)} == {0, 255}
        assert rgba(f'B_hydroides_move_{i:02d}_x8').tobytes() == im.resize((384, 384), Image.Resampling.NEAREST).tobytes()
        bases.append(im.getchannel('A').getbbox()[3])
    assert len(union) <= 16
    assert max(bases) - min(bases) <= 1, bases
    a, b = [rgba(f'B_hydroides_hit_{i:02d}') for i in (1, 2)]
    assert a.tobytes() == b.tobytes()
    assert {p[:3] for p in pixels(a) if p[3]} == {(255, 255, 255)}
    assert a.getchannel('A').tobytes() == rgba('B_hydroides_move_03').getchannel('A').tobytes()
    checks.append({'asset': 'B_hydroides', 'frames': 3, 'shared_colors': len(union), 'size': [48, 48], 'base_y': bases, 'white_damage_frames': 2})
    for i in range(1, 5):
        im = rgba(f'C_capa_{i:02d}_1280x336')
        assert im.size == (1280, 336)
        assert im.crop((0, 0, 1, 336)).tobytes() == im.crop((1279, 0, 1280, 336)).tobytes()
        assert im.crop((639, 0, 640, 336)).tobytes() == im.crop((640, 0, 641, 336)).tobytes()
        checks.append({'asset': f'C_capa_{i:02d}', 'size': [1280, 336], 'loop_edges_equal': True, 'mirror_join_equal': True})
    for name in ['C_mockup', 'D_portada_mockup']:
        im = rgba(name + '_640x360')
        assert im.size == (640, 360)
        assert rgba(name + '_1920x1080').tobytes() == im.resize((1920, 1080), Image.Resampling.NEAREST).tobytes()
        checks.append({'asset': name, 'size': [640, 360], 'nearest_x3': True, 'type': 'MOCKUP'})
    for name in ['D_ilustracion_640x360', 'D_textos_separados_640x360']:
        assert rgba(name).size == (640, 360)
    # Decode every delivered PNG; a filename alone is not a valid image.
    files = sorted(ROOT.rglob('*.png'))
    for p in files:
        with Image.open(p) as im:
            assert im.format == 'PNG'
            im.load()
    result = {'status': 'pass', 'png_count': len(files), 'checks': checks, 'art_approval': False, 'game_integration': False}
    (ROOT / 'verificacion-png.json').write_text(json.dumps(result, indent=2, ensure_ascii=False) + '\n')
    print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == '__main__':
    verify()
