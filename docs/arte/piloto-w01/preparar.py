"""Prepare review sheets from imagegen concepts, never production game assets.

Run from the repository root: python3 docs/arte/piloto-w01/preparar.py
Only crops, alpha/palette preparation, nearest scaling and PNG composition.
No creature, vessel or scenery is drawn from geometric primitives.
"""
from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFont, ImageOps, ImageFilter, ImageChops

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[2]
SRC = OUT / 'originales'
NEAREST = Image.Resampling.NEAREST
FONT = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 17)
SMALL = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 13)
DARK = (17, 32, 48, 255)


def read(name):
    return Image.open(SRC / (name + '.png')).convert('RGBA')


def save(im, name):
    im.save(OUT / (name + '.png'), optimize=True)
    return im


def mask(im):
    return im.getchannel('A').point(lambda a: 255 if a >= 128 else 0)


def palette_sprite(im, fixed=None):
    """15 opaque colors + explicit dark 1px exterior outline, binary alpha."""
    alpha = mask(im)
    # Background RGB must not consume the sprite's color budget.
    rgb = Image.new('RGB', im.size, DARK[:3])
    rgb.paste(im.convert('RGB'), mask=alpha)
    if fixed:
        palette = Image.new('P', (1, 1))
        flat = [c for color in fixed for c in color]
        palette.putpalette(flat + list(fixed[0]) * (256 - len(fixed)))
        rgb = rgb.quantize(palette=palette, dither=Image.Dither.NONE).convert('RGBA')
    else:
        rgb = rgb.quantize(colors=15, dither=Image.Dither.NONE).convert('RGBA')
    rgb.putalpha(alpha)
    border = ImageChops.subtract(alpha.filter(ImageFilter.MaxFilter(3)), alpha)
    result = Image.new('RGBA', im.size)
    result.paste(DARK, (0, 0, *im.size), border)
    result.alpha_composite(rgb)
    return result


def label(im, xy, value, small=False):
    ImageDraw.Draw(im).text(xy, value, font=SMALL if small else FONT, fill='#e4f4fa')


def paper(size):
    return Image.new('RGBA', size, '#112030')


font_atlas = Image.open(ROOT / 'assets/ui/bitmap_font.png').convert('RGBA')
glyphs = json.loads((ROOT / 'assets/ui/bitmap_font.json').read_text())['glyphs']


def bitmap_text(im, xy, value, color=(238, 249, 255, 255), scale=1):
    x, y = xy
    initial = x
    for c in value:
        if c == '\n':
            x, y = initial, y + 9 * scale
            continue
        gx, gy, w, h = glyphs.get(c, glyphs['?'])
        glyph = font_atlas.crop((gx, gy, gx + w, gy + h))
        colored = Image.new('RGBA', glyph.size, color)
        colored.putalpha(glyph.getchannel('A'))
        im.alpha_composite(colored.resize((w * scale, h * scale), NEAREST), (x, y))
        x += 6 * scale


def main():
    # A: manually selected isolated rows; a shared 2:1 crop preserves silhouette.
    ships = []
    source = read('A_naves')
    names = ['cientifica', 'industrial', 'expedicion']
    for row, name in enumerate(names):
        crop = source.crop((48, row * 512 + 4, 976, row * 512 + 468))
        crop.putalpha(mask(crop))
        small = palette_sprite(crop.resize((46, 23), NEAREST))
        canvas = Image.new('RGBA', (48, 24))
        canvas.alpha_composite(small, (1, 0))
        ships.append(save(canvas, 'A_nave_' + name + '_48x24'))
        save(canvas.resize((384, 192), NEAREST), 'A_nave_' + name + '_x8')
    a = paper((1000, 760))
    label(a, (24, 16), 'A / NAVE OCEANOGRAFICA - CONCEPTOS NO APROBADOS')
    for i, (ship, name) in enumerate(zip(ships, names)):
        y = 70 + i * 224
        a.alpha_composite(ship.resize((384, 192), NEAREST), (24, y))
        a.alpha_composite(ship, (480, y + 80))
        label(a, (560, y + 48), name.upper() + (' / RECOMENDADA' if i == 0 else ''))
        label(a, (560, y + 82), '48 x 24 / izquierda: x8 nearest', True)
        label(a, (560, y + 110), 'Cabina con tripulante / disparo a derecha', True)
    save(a, 'A_variantes')

    # B: reject the clipped fourth source pose. Three inspected poses suffice.
    source = read('B_hydroides')
    crops = [(80, 20, 430, 704), (480, 20, 880, 704), (900, 20, 1510, 704)]
    base_x = [250, 694, 1220]
    # Art review: keep calcified tube ivory in ALL poses. An adaptive joint
    # palette made its third pose salmon; use a consciously selected ramp.
    hydroides_palette = [
        (17, 32, 48), (36, 38, 72), (78, 72, 78), (129, 117, 110),
        (170, 158, 136), (210, 199, 167), (236, 230, 201), (255, 242, 217),
        (86, 35, 67), (141, 43, 70), (201, 66, 74), (228, 100, 87),
        (242, 139, 119), (255, 184, 148), (230, 179, 125), (102, 61, 75),
    ]
    frames = []
    for i, (box, anchor) in enumerate(zip(crops, base_x)):
        crop = source.crop(box)
        crop.putalpha(mask(crop))
        canvas = Image.new('RGBA', (724, 724))
        canvas.alpha_composite(crop, (362 - (anchor - box[0]), box[1]))
        frame = palette_sprite(canvas.resize((46, 46), NEAREST), hydroides_palette)
        padded = Image.new('RGBA', (48, 48))
        padded.alpha_composite(frame, (1, 1))
        frames.append(save(padded, f'B_hydroides_move_{i+1:02d}'))
        save(padded.resize((384, 384), NEAREST), f'B_hydroides_move_{i+1:02d}_x8')
    silhouette = Image.new('RGBA', (48, 48), DARK)
    silhouette.putalpha(frames[2].getchannel('A'))
    save(silhouette, 'B_hydroides_silueta')
    white = Image.new('RGBA', (48, 48), 'white')
    white.putalpha(frames[2].getchannel('A'))
    for i in (1, 2):
        save(white, f'B_hydroides_hit_{i:02d}')
    b = paper((1240, 620))
    label(b, (24, 16), 'B / HYDROIDES - SERPULIDAE - ACTOR 48 x 48 - CONCEPTO')
    for i, frame in enumerate(frames):
        b.alpha_composite(frame.resize((384, 384), NEAREST), (12 + i * 408, 64))
        b.alpha_composite(frame, (36 + i * 408, 460))
        label(b, (110 + i * 408, 470), ['RETRAIDO', 'EXTENSION', 'CORONA ABIERTA'][i], True)
    b.alpha_composite(white.resize((96, 96), NEAREST), (26, 516))
    label(b, (144, 546), 'Daño: 2 cuadros blancos. Propuesta de ciclo a 8 fps, NO integrada.', True)
    save(b, 'B_hydroides_hoja')
    unique = sorted({p[:3] for f in frames for p in f.getdata() if p[3]})
    palette = paper((max(480, len(unique) * 32), 64))
    for i, color in enumerate(unique):
        palette.paste(color, (i * 32, 0, i * 32 + 32, 32))
    label(palette, (4, 40), f'{len(unique)} colores opacos compartidos / alfa binario', True)
    save(palette, 'B_hydroides_paleta')

    # C: original half + reflected half creates a continuous 1280px concept tile.
    # This is explicit preprocessing, not a claim of hand-finished background art.
    layers = []
    for i, name in enumerate(['C1_agua', 'C2_puerto', 'C3_corrientes', 'C4_boyas']):
        half = read(name).resize((640, 336), NEAREST)
        if i:
            half.putalpha(mask(half))
        tile = Image.new('RGBA', (1280, 336))
        tile.alpha_composite(half)
        tile.alpha_composite(ImageOps.mirror(half), (640, 0))
        layers.append(save(tile, f'C_capa_{i+1:02d}_1280x336'))
    bg = Image.new('RGBA', (1280, 336))
    for layer in layers:
        bg.alpha_composite(layer)
    save(bg, 'C_composicion_1280x336')
    mock = paper((640, 360))
    mock.alpha_composite(bg.crop((0, 0, 640, 336)))
    mock.alpha_composite(ships[0], (138, 164))
    mock.alpha_composite(frames[2], (446, 265))
    mock.alpha_composite(frames[1], (528, 259))
    # Projectiles are sourced from the old game's PNGs, not code shapes.
    for xy in [(234, 173), (284, 173), (334, 173), (378, 232), (402, 213)]:
        p = Image.open(ROOT / 'assets/sprites/w01/w01_bullet_enemy_move_01.png').convert('RGBA')
        mock.alpha_composite(p.resize((6, 6), NEAREST), xy)
    bitmap_text(mock, (8, 341), 'MOCKUP - CONCEPTO NO APROBADO / NO ES PARTIDA GODOT')
    save(mock, 'C_mockup_640x360')
    save(mock.resize((1920, 1080), NEAREST), 'C_mockup_1920x1080')
    seams = paper((1280, 4 * 194))
    for i, layer in enumerate(layers):
        # Inspect 320px either side of the loop boundary, not just image center.
        across = Image.new('RGBA', (640, 336))
        across.alpha_composite(layer.crop((960, 0, 1280, 336)))
        across.alpha_composite(layer.crop((0, 0, 320, 336)), (320, 0))
        seams.alpha_composite(layer.resize((640, 168), NEAREST), (0, i * 194 + 22))
        seams.alpha_composite(across.resize((640, 168), NEAREST), (640, i * 194 + 22))
        label(seams, (8, i * 194 + 2), f'CAPA {i+1} / izquierda tile completo / derecha empalme central', True)
    save(seams, 'C_empalmes')

    # D: generated concept illustration retained separately from bitmap overlay.
    cover = read('D_portada').resize((640, 360), NEAREST)
    save(cover, 'D_ilustracion_640x360')
    overlay = Image.new('RGBA', (640, 360))
    # Only presentation panels and text, never scene illustration primitives.
    panel = Image.new('RGBA', (257, 206), (6, 24, 43, 210))
    overlay.alpha_composite(panel, (12, 14))
    bitmap_text(overlay, (22, 28), 'POLIQUETOS', scale=3)
    bitmap_text(overlay, (22, 61), 'ASESINOS', (168, 242, 226, 255), scale=3)
    for i, value in enumerate(['> NUEVA PARTIDA', '  CONTINUAR', '  OPCIONES', '  CREDITOS', '  SALIR']):
        bitmap_text(overlay, (26, 111 + i * 24), value)
    overlay.alpha_composite(Image.new('RGBA', (640, 18), (6, 24, 43, 240)), (0, 342))
    bitmap_text(overlay, (10, 346), 'MOCKUP - PROPUESTA DE PORTADA / NO ES MENU FUNCIONAL')
    save(overlay, 'D_textos_separados_640x360')
    cover.alpha_composite(overlay)
    save(cover, 'D_portada_mockup_640x360')
    save(cover.resize((1920, 1080), NEAREST), 'D_portada_mockup_1920x1080')

    # Comparison uses old PNG composition, never labels it a new game capture.
    old = paper((640, 360))
    for i in range(1, 5):
        old.alpha_composite(Image.open(ROOT / f'assets/backgrounds/w01/w01_bg_layer{i}_idle_01.png').convert('RGBA'))
    old_ship = Image.open(ROOT / 'assets/ui/w01_ui_ship_original_move_01.png').convert('RGBA')
    old_enemy = Image.open(ROOT / 'assets/sprites/w01/w01_enemy_hydroides_move_01.png').convert('RGBA').resize((48, 48), NEAREST)
    old.alpha_composite(old_ship, (138, 164))
    old.alpha_composite(old_enemy, (446, 265))
    bitmap_text(old, (8, 341), 'MOCKUP CON PNG PREVIOS - NO ES CAPTURA DE PARTIDA')
    save(old, 'comparacion_previo_mockup')
    board = paper((1280, 1060))
    label(board, (16, 12), 'PNG PLACEHOLDER ACTUAL / composicion estatica')
    label(board, (656, 12), 'PROPUESTA / CONCEPTO NO APROBADO / MOCKUP')
    board.alpha_composite(old, (0, 44))
    board.alpha_composite(mock, (640, 44))
    for x, ship, enemy in [(30, old_ship, old_enemy), (670, ships[0], frames[2])]:
        board.alpha_composite(ship.resize((384, 192), NEAREST), (x, 444))
        board.alpha_composite(enemy.resize((384, 384), NEAREST), (x, 660))
    label(board, (450, 510), 'NAVE x8', True)
    label(board, (1080, 510), 'NAVE x8', True)
    label(board, (450, 800), 'HYDROIDES x8', True)
    label(board, (1080, 800), 'HYDROIDES x8', True)
    save(board, 'comparativa')


if __name__ == '__main__':
    main()
