#!/usr/bin/env python3
"""Build ORIGINAL labelled rectangular placeholders, bitmap font and bounded atlases.

Pillow is a development dependency only. Existing PNGs are preserved by default:
artists replace an individual frame and rerun this script only to refresh atlases.
Use --force-placeholders intentionally to discard replacement artwork.
"""
import argparse
import json
from pathlib import Path
import re
from PIL import Image, ImageDraw, PngImagePlugin

ROOT = Path(__file__).resolve().parents[1]
# Original simple 5x7 bitmap alphabet; lower case intentionally uses small capitals.
PATTERNS = {
'A':'01110/10001/10001/11111/10001/10001/10001','B':'11110/10001/10001/11110/10001/10001/11110',
'C':'01111/10000/10000/10000/10000/10000/01111','D':'11110/10001/10001/10001/10001/10001/11110',
'E':'11111/10000/10000/11110/10000/10000/11111','F':'11111/10000/10000/11110/10000/10000/10000',
'G':'01111/10000/10000/10111/10001/10001/01111','H':'10001/10001/10001/11111/10001/10001/10001',
'I':'11111/00100/00100/00100/00100/00100/11111','J':'00111/00010/00010/00010/10010/10010/01100',
'K':'10001/10010/10100/11000/10100/10010/10001','L':'10000/10000/10000/10000/10000/10000/11111',
'M':'10001/11011/10101/10101/10001/10001/10001','N':'10001/11001/10101/10011/10001/10001/10001',
'O':'01110/10001/10001/10001/10001/10001/01110','P':'11110/10001/10001/11110/10000/10000/10000',
'Q':'01110/10001/10001/10001/10101/10010/01101','R':'11110/10001/10001/11110/10100/10010/10001',
'S':'01111/10000/10000/01110/00001/00001/11110','T':'11111/00100/00100/00100/00100/00100/00100',
'U':'10001/10001/10001/10001/10001/10001/01110','V':'10001/10001/10001/10001/10001/01010/00100',
'W':'10001/10001/10001/10101/10101/10101/01010','X':'10001/10001/01010/00100/01010/10001/10001',
'Y':'10001/10001/01010/00100/00100/00100/00100','Z':'11111/00001/00010/00100/01000/10000/11111',
'0':'01110/10001/10011/10101/11001/10001/01110','1':'00100/01100/00100/00100/00100/00100/01110',
'2':'01110/10001/00001/00010/00100/01000/11111','3':'11110/00001/00001/01110/00001/00001/11110',
'4':'00010/00110/01010/10010/11111/00010/00010','5':'11111/10000/10000/11110/00001/00001/11110',
'6':'01110/10000/10000/11110/10001/10001/01110','7':'11111/00001/00010/00100/01000/01000/01000',
'8':'01110/10001/10001/01110/10001/10001/01110','9':'01110/10001/10001/01111/00001/00001/01110',
' ':'00000/00000/00000/00000/00000/00000/00000','!':'00100/00100/00100/00100/00100/00000/00100',
'?':'01110/10001/00001/00010/00100/00000/00100','.':'00000/00000/00000/00000/00000/00110/00110',
',':'00000/00000/00000/00000/00110/00100/01000',':':'00000/00110/00110/00000/00110/00110/00000',
';':'00000/00110/00110/00000/00110/00100/01000','-':'00000/00000/00000/11111/00000/00000/00000',
'_':'00000/00000/00000/00000/00000/00000/11111','+':'00000/00100/00100/11111/00100/00100/00000',
'=':'00000/00000/11111/00000/11111/00000/00000','/':'00001/00010/00010/00100/01000/01000/10000',
'\\':'10000/01000/01000/00100/00010/00010/00001','(':'00010/00100/01000/01000/01000/00100/00010',
')':'01000/00100/00010/00010/00010/00100/01000','[':'01110/01000/01000/01000/01000/01000/01110',
']':'01110/00010/00010/00010/00010/00010/01110','<':'00010/00100/01000/10000/01000/00100/00010',
'>':'01000/00100/00010/00001/00010/00100/01000','"':'01010/01010/01010/00000/00000/00000/00000',
"'":'00100/00100/01000/00000/00000/00000/00000','*':'00000/10101/01110/11111/01110/10101/00000',
'#':'01010/01010/11111/01010/11111/01010/01010','%':'11001/11010/00010/00100/01000/01011/10011',
'&':'01100/10010/10100/01000/10101/10010/01101','@':'01110/10001/10111/10101/10111/10000/01111',
'$':'00100/01111/10100/01110/00101/11110/00100','^':'00100/01010/10001/00000/00000/00000/00000',
'`':'01000/00100/00000/00000/00000/00000/00000','~':'00000/00000/01001/10110/00000/00000/00000',
'|':'00100/00100/00100/00100/00100/00100/00100','{':'00010/00100/00100/01000/00100/00100/00010',
'}':'01000/00100/00100/00010/00100/00100/01000',
}
CHARACTERS = ''.join(chr(i) for i in range(32, 127)) + 'áéíóúüñÁÉÍÓÚÜÑ¿¡'
COLORS = {'enemy':(168,55,63,255), 'mini':(191,75,133,255),'boss':(107,65,159,255),
          'bullet':(246,208,64,255),'bg':(45,53,66,255),'fx':(239,132,51,255),'ui':(61,116,139,255)}
MINIS = ['pision','arenicola','oenone','myxicola','spirobranchus','glycera','terebellides','lumbrineris','lopado','flabegraviera','chryso','paralvinella','aphro','mech_nereis']

def dump(path, value):
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2)+'\n')

def snake(value):
    return re.sub(r'(?<!^)(?=[A-Z])','_',value).lower()

def glyph(char):
    upper = char.upper()
    base = {'Á':'A','É':'E','Í':'I','Ó':'O','Ú':'U','Ü':'U','Ñ':'N'}.get(upper, upper)
    if char in '¿¡':
        return glyph('?' if char == '¿' else '!').transpose(Image.Transpose.ROTATE_180)
    pattern = PATTERNS.get(base, PATTERNS['?']).split('/')
    image=Image.new('RGBA',(6,9))
    pixels=image.load()
    for y,row in enumerate(pattern):
        for x,value in enumerate(row):
            if value=='1': pixels[x,y+2]=(255,255,255,255)
    accent = {'Á':[(2,0),(3,0),(1,1)],'É':[(2,0),(3,0),(1,1)],'Í':[(2,0),(3,0),(1,1)],
              'Ó':[(2,0),(3,0),(1,1)],'Ú':[(2,0),(3,0),(1,1)],'Ü':[(1,0),(3,0)],'Ñ':[(1,1),(2,0),(3,1)]}
    for point in accent.get(upper,[]): pixels[point]=(255,255,255,255)
    return image

def make_font():
    image=Image.new('RGBA',(96,((len(CHARACTERS)+15)//16)*9))
    frames={}
    for i,char in enumerate(CHARACTERS):
        x,y=(i%16)*6,(i//16)*9
        image.paste(glyph(char),(x,y))
        frames[char]=[x,y,6,9]
    image.save(ROOT/'assets/ui/bitmap_font.png')
    dump(ROOT/'assets/ui/bitmap_font.json',{'imagen':'bitmap_font.png','advance':6,'line_height':9,'glyphs':frames,'estado':'placeholder','author':'Poliquetos original development bitmap alphabet'})

def definitions():
    result=[]
    def add(world,kind,name,action,size,frames=2,fps=8):
        key=f'w{world:02}_{kind}_{name}_{action}'
        folder=f'assets/backgrounds/w{world:02}' if kind=='bg' else ('assets/ui' if kind=='ui' else 'assets/fx' if kind=='fx' else f'assets/sprites/w{world:02}')
        result.append({'nombre':key,'mundo':world,'tipo':kind,'ruta':f'{folder}/{key}_01.png','tamano':list(size),'cuadros':frames,'fps':fps,'estado':'placeholder'})
    inventory=json.loads((ROOT/'data/legacy_inventory.json').read_text())['worlds']
    native=ROOT/'data/worlds.json'
    if native.exists():
        raw=json.loads(native.read_text())
        worlds=raw if isinstance(raw,list) else raw.get('mundos',raw.get('worlds',[]))
    else:
        worlds=[{'id':w['id'],'unicos':[snake(e) for e in w['unique']],'recurrentes':[snake(e) for e in w['recurrent']], 'mini_tipo':f"mini_w{w['id']:02}_{MINIS[w['id']-1]}"} for w in inventory]
    for world in range(1,16):
        for layer in range(1,5): add(world,'bg',f'layer{layer}','idle',(640,336),1,0)
    for world in worlds:
        number=world['id']
        for enemy in dict.fromkeys(world.get('unicos',[])+world.get('recurrentes',[])):
            add(number,'enemy',enemy,'move',(32,32),4)
        if world.get('mini_tipo'): add(number,'mini',world['mini_tipo'],'move',(112,96),4)
    bosses_path=ROOT/'data/bosses.json'
    if bosses_path.exists():
        raw=json.loads(bosses_path.read_text())
        bosses=raw if isinstance(raw,list) else raw.get('jefes',raw.get('bosses',[]))
    else:
        bosses=[{'mundo':w['id'],'id':f"boss_w{w['id']:02}_{snake(b['id'])}"} for w in inventory for b in w['bosses']]
    for boss in bosses:
        if boss.get('tipo') == 'minijefe': continue
        add(boss['mundo'],'boss',boss['id'],'move',(320,192) if 'eunice' in boss['id'] else (240,160),4)
    # Escape uses its own palette set, including the laboratory's robotic enemies.
    lab=next(w for w in worlds if w['id']==14)
    for enemy in lab.get('unicos',[]): add(15,'enemy',enemy,'move',(32,32),4)
    cosmetics_path=ROOT/'data/cosmetics.json'
    skins=json.loads(cosmetics_path.read_text()) if cosmetics_path.exists() else [{'id':'original'}]
    for skin in skins: add(1,'ui','ship_'+skin['id'],'move',(48,24),4,10)
    for name,size in [('panel',(640,360)),('panel_selected',(640,360)),('pixel',(1,1)),('hud',(640,24)),('cursor',(8,8)),('hitbox',(16,16)),('hazard',(64,16)),('title',(320,48))]:
        add(1,'ui',name,'idle',size,1,0)
    for name,size in [('shot',(12,4)),('enemy',(8,8)),('missile',(16,8)),('laser',(32,8)),('homing',(12,8)),('bounce',(8,8)),('bomb',(12,12))]:
        add(1,'bullet',name,'move',size,2,10)
    for name in ['coin','shot','missile','bomb','shield','score','life','magnet']:
        add(1,'ui',f'item_{name}','idle',(16,16),2,8)
    for name,size in [('explosion',(64,64)),('bomb',(128,128)),('hit',(32,32)),('bubble',(8,8)),('spark',(8,8)),('trail',(16,8)),('flash',(48,24))]:
        add(1,'fx',name,'burst',size,8,12)
    # Damage flashes are actual white PNGs: white tinting a coloured PNG is a no-op.
    for move in list(result):
        if move['tipo'] in ('enemy','mini','boss') and move['nombre'].endswith('_move'):
            hit=dict(move)
            hit.update(nombre=move['nombre'].removesuffix('_move')+'_hit',
                       ruta=move['ruta'].replace('_move_01.png','_hit_01.png'), cuadros=2, fps=60)
            result.append(hit)
    return result

def placeholder(asset,index):
    key=asset['nombre']; w,h=asset['tamano']; kind=asset['tipo']
    color=COLORS[kind]
    if kind=='bg':
        layer=int(key.split('layer')[1].split('_')[0]);world=asset['mundo']
        color=(24+world*5,35+layer*8,49+world*3,255 if layer==1 else 40)
    is_hit=kind in ('enemy','mini','boss') and key.endswith('_hit')
    if is_hit or 'pixel_idle' in key: color=(255,255,255,255)
    if 'panel_selected' in key: color=(59,112,156,255)
    image=Image.new('RGBA',(w,h),color)
    # A tiny original bitmap label. Sub-pixel-sized bullets/pixel rely on PNG metadata.
    if w>=16 and h>=16:
        label=key+f'_{index:02}'
        cell_w,cell_h=(4,6) if w<64 else (6,9)
        columns=max(1,(w-4)//cell_w)
        for i,char in enumerate(label):
            x=2+(i%columns)*cell_w;y=2+(i//columns)*cell_h
            if y+cell_h>=h: break
            mark=glyph(char)
            if cell_w==4: mark=mark.resize((4,6),Image.Resampling.NEAREST)
            if is_hit:
                dark=Image.new('RGBA',mark.size,(24,24,24,255))
                dark.putalpha(mark.getchannel('A'))
                mark=dark
            image.paste(mark,(x,y),mark)
    meta=PngImagePlugin.PngInfo();meta.add_text('status','placeholder');meta.add_text('asset_name',key);meta.add_text('frame',str(index));meta.add_text('notice','Original flat labelled rectangle; replace with artist-produced final PNG.')
    return image,meta

def pack_atlas(world,assets):
    # Shelf packing, largest first. Capped at 2048x2048, never one giant campaign atlas.
    items=[]
    for asset in assets:
        for index in range(1,asset['cuadros']+1):
            frame=asset['nombre']+f'_{index:02}'
            path=ROOT/asset['ruta'].replace('_01.png',f'_{index:02}.png')
            items.append((frame,Image.open(path).convert('RGBA')))
    items.sort(key=lambda item:(-item[1].height,-item[1].width,item[0]))
    atlas=Image.new('RGBA',(2048,2048));frames={};x=y=row_h=0
    for key,image in items:
        if x+image.width>atlas.width: x=0;y+=row_h;row_h=0
        if y+image.height>atlas.height: raise ValueError(f'w{world:02} exceeds bounded atlas; split into pages before adding more assets')
        atlas.paste(image,(x,y))
        frames[key]={'x':x,'y':y,'w':image.width,'h':image.height}
        x+=image.width;row_h=max(row_h,image.height)
    # Keep width2048; crop height to nearest power of two while retaining all bounds.
    used=y+row_h; height=next(v for v in (512,1024,2048) if v>=used)
    atlas=atlas.crop((0,0,2048,height))
    atlas.save(ROOT/f'assets/atlas/w{world:02}.png')
    animations={a['nombre']:{'frames':[a['nombre']+f'_{i:02}' for i in range(1,a['cuadros']+1)],'fps':max(1,a['fps']),'bucle':a['tipo']!='fx'} for a in assets}
    dump(ROOT/f'assets/atlas/w{world:02}.json',{'imagen':f'w{world:02}.png','tamano':[atlas.width,atlas.height],'frames':frames,'animaciones':animations})

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--force-placeholders',action='store_true',help='discard existing PNG artwork and regenerate all flat placeholders')
    args=parser.parse_args()
    (ROOT/'assets/ui').mkdir(parents=True,exist_ok=True);(ROOT/'assets/atlas').mkdir(parents=True,exist_ok=True)
    if not (ROOT/'assets/ui/bitmap_font.png').exists() or args.force_placeholders: make_font()
    assets=definitions()
    for asset in assets:
        statuses=[]
        for index in range(1,asset['cuadros']+1):
            path=ROOT/asset['ruta'].replace('_01.png',f'_{index:02}.png')
            path.parent.mkdir(parents=True,exist_ok=True)
            if not path.exists() or args.force_placeholders:
                image,meta=placeholder(asset,index);image.save(path,pnginfo=meta)
            with Image.open(path) as image:
                if image.size!=tuple(asset['tamano']): raise ValueError(f'{path}: keep frame size {asset["tamano"]}, got {image.size}')
                statuses.append(image.info.get('status','final'))
        if any(status!='placeholder' for status in statuses): asset['estado']='final'
    for world in range(1,16): pack_atlas(world,[a for a in assets if a['mundo']==world])
    dump(ROOT/'assets/assets_manifest.json',{'version':2,'assets':assets})
    print(f'Generated {len(assets)} animations, {sum(a["cuadros"] for a in assets)} individual PNG frames, 15 bounded atlases. Existing artist PNGs preserved.')

if __name__=='__main__': main()
