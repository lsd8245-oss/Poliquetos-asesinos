"""Prepare original imagegen PNGs: crop, alpha, shared palette, nearest only.
No scenery, creatures, particles or silhouettes are drawn by this script.
"""
from pathlib import Path
import hashlib
import json
from PIL import Image, PngImagePlugin

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
objects = Image.open(HERE / 'fuentes/environment-objects.png').convert('RGBA')
particles = Image.open(HERE / 'fuentes/environment-particles.png').convert('RGBA')
records = []
provenance = []

def save(key, frames, size, fps, source, crops):
    # Threshold removes near-transparent generator color bleed, without drawing.
    prepared = []
    for frame in frames:
        alpha = frame.getchannel('A').point(lambda v: 255 if v >= 100 else 0)
        frame.putalpha(alpha)
        prepared.append(frame.resize(size, Image.Resampling.NEAREST))
    # One palette per animation prevents color shifts between consecutive frames.
    contact = Image.new('RGB', (size[0] * len(prepared), size[1]))
    for index, frame in enumerate(prepared):
        clean = Image.new('RGB', size, (10, 30, 51))
        clean.paste(frame.convert('RGB'), mask=frame.getchannel('A'))
        contact.paste(clean, (index * size[0], 0))
    palette = contact.quantize(colors=16, method=Image.Quantize.MEDIANCUT)
    paths = []
    for index, frame in enumerate(prepared, 1):
        output = frame.convert('RGB').quantize(palette=palette, dither=Image.Dither.NONE).convert('RGBA')
        output.putalpha(frame.getchannel('A'))
        relative = f'assets/backgrounds/w01/{key}_{index:02}.png'
        meta=PngImagePlugin.PngInfo()
        for k,v in {"status":"placeholder","asset_name":key,"art_stage":"integrated-review","source":source}.items():meta.add_text(k,v)
        output.save(ROOT / relative,pnginfo=meta)
        paths.append(relative)
    records.append({'nombre': key, 'mundo': 1, 'tipo': 'bg', 'tamano': list(size), 'cuadros': len(frames), 'fps': fps, 'ruta': paths[0], 'estado': 'placeholder'})
    provenance.append({'nombre': key, 'source': 'image_gen original, 2026-11-01', 'sheet': f'docs/arte/pulido-w01/fuentes/{source}', 'source_sha256': hashlib.sha256((HERE / 'fuentes' / source).read_bytes()).hexdigest(), 'crop_boxes': crops, 'processing': 'crop, binary alpha threshold100, shared16color palette, nearest-neighbor resize only', 'review': 'PNG integrado para revisión humana; no aprobado como arte final', 'frames_sha256': {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in paths}})

static = [('coast_pillars', (0, 40, 380, 355), (192, 144)), ('ruin_arch', (384, 120, 764, 355), (256, 144)), ('wreck_truss', (768, 130, 1154, 355), (320, 144)), ('coast_rocks', (1154, 160, 1536, 355), (176, 80))]
for name, box, size in static:
    frame = objects.crop(box)
    frame.putalpha(frame.getchannel('A').point(lambda v: 255 if v >= 100 else 0))
    frame = frame.crop(frame.getbbox())
    save(f'w01_bg_{name}_idle', [frame], size, 0, 'environment-objects.png', [list(box)])
for name, top, bottom, size, fps in [('algae_sway', 384, 658, (96, 96), 4), ('chain_sway', 662, 1005, (48, 128), 3)]:
    boxes = [(column * 384, top, (column + 1) * 384, bottom) for column in range(4)]
    save(f'w01_bg_{name}', [objects.crop(box) for box in boxes], size, fps, 'environment-objects.png', boxes)
for name, top, bottom, size, fps in [('fish_swim', 120, 285, (96, 40), 5), ('bubble_rise', 380, 660, (24, 40), 4), ('caustic_drift', 725, 910, (220, 72), 3), ('plankton_drift', 1010, 1195, (96, 64), 2)]:
    width = particles.width / 4
    boxes = [(round(column * width), top, round((column + 1) * width), bottom) for column in range(4)]
    save(f'w01_bg_{name}', [particles.crop(box) for box in boxes], size, fps, 'environment-particles.png', boxes)
(HERE / 'environment-fragment.json').write_text(json.dumps({'version': 2, 'assets': records, 'provenance': provenance}, indent=2, ensure_ascii=False) + '\n')
print(f'{len(records)} asset records, {sum(a["cuadros"] for a in records)} PNG frames prepared')
