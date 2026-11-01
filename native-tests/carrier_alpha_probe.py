"""Regression for the carrier halo found only in real Windows capture.
A thin neutral PNG rim must not become a dark tiled panel under RGB tint.
"""
from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parents[1]
for index in range(1,9):
    path=root/f'assets/fx/w01_fx_bubble_burst_{index:02}.png'
    im=Image.open(path).convert('RGBA')
    assert im.size==(32,32),path
    pixels=list(im.getdata())
    visible=[p for p in pixels if p[3]]
    assert 0.05<len(visible)/1024<0.2,path
    assert all(min(p[:3])>=200 and max(p[:3])-min(p[:3])<=2 for p in visible),path
    assert not any(im.getpixel((x,y))[3] for x in range(12,20) for y in range(12,20)),path
print('CARRIER ALPHA PASS: 8 thin neutral rims; transparent center, no dark backing')
