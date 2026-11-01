from pathlib import Path
from PIL import Image, PngImagePlugin
import json, shutil, hashlib, colorsys, argparse

ROOT=Path(__file__).resolve().parents[3]
parser=argparse.ArgumentParser(description='Prepare B1 imagegen PNG crops; never draws artwork.')
parser.add_argument('--only',help='Update just one asset key and its provenance records.')
args=parser.parse_args()
OUT=ROOT/'docs/arte/pulido-w01'
ORIG=OUT/'originales'
ORIG.mkdir(parents=True,exist_ok=True)
sources={
 'projectiles':'/workspace/generated_images/exec-52617717-d50f-49e4-af03-f24bb1a7fa88.png',
 'fx':'/workspace/generated_images/exec-1c11c735-789d-4ab0-b9d6-a40e67acc81c.png',
 'ui':'/workspace/generated_images/exec-aaf74985-52d5-4f56-8075-0915ace5c979.png'}
for name,p in sources.items():
 destination=ORIG/f'b1-{name}-imagegen.png'
 if not destination.exists():shutil.copyfile(p,destination)
sources={k:str((ORIG/f'b1-{k}-imagegen.png').relative_to(ROOT)) for k in sources}
images={k:Image.open(ROOT/p).convert('RGBA') for k,p in sources.items()}
manifest={a['nombre']:a for a in json.loads((ROOT/'assets/assets_manifest.json').read_text())['assets']}
records=[];assets=[]

def cell(sheet,row,col):
 im=images[sheet]; w,h=im.size
 box=(round(col*w/8),round(row*h/8),round((col+1)*w/8),round((row+1)*h/8))
 # Imagegen keeps columns consistent but gives effect rows different heights.
 # Use inspected source bounds, retaining one common anchor within each row.
 if sheet=='fx':
  top,bottom=[(0,170),(170,350),(350,505),(500,680),(685,795),(805,945),(945,1080),(1080,1254)][row]
  box=(box[0],top,box[2],bottom)
 if sheet=='projectiles' and row==0 and col<4:box=(box[0],50,box[2],116)
 if sheet=='projectiles' and row==1:box=(box[0],175,box[2],285)
 return im.crop(box),box

def palette(frames):
 # One shared 16-color palette per animation, selected from visible source pixels.
 colors=[p[:3] for im in frames for p in im.getdata() if p[3]>=96]
 pixels=Image.new('RGB',(len(colors),1));pixels.putdata(colors)
 pal=pixels.quantize(colors=16,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE)
 result=[]
 for im in frames:
  alpha=im.getchannel('A').point(lambda a:255 if a>=96 else 0)
  rgb=im.convert('RGB').quantize(palette=pal,dither=Image.Dither.NONE).convert('RGBA')
  rgb.putalpha(alpha)
  # Canonical hidden RGB makes frame comparison and atlas copying deterministic.
  rgb.putdata([p if p[3] else (0,0,0,0) for p in rgb.getdata()])
  result.append(rgb)
 return result

def emit(key,frames,source,boxes,dimensions=None,fps=None,kind=None,notes=''):
 if args.only and key!=args.only:return
 old=manifest.get(key)
 if old:a=dict(old)
 else:
  kind=kind or ('fx' if '_fx_' in key else 'ui')
  folder='assets/fx' if kind=='fx' else 'assets/ui'
  a={'nombre':key,'mundo':1,'tipo':kind,'ruta':folder+'/'+key+'_01.png','tamano':list(dimensions),'cuadros':len(frames),'fps':fps,'estado':'placeholder'}
 a.update(cuadros=len(frames),estado='placeholder')
 if dimensions is not None:a['tamano']=list(dimensions)
 if fps is not None:a['fps']=fps
 size=tuple(a['tamano'])
 frames=palette([im.resize(size,Image.Resampling.NEAREST) for im in frames])
 assets.append(a)
 for n,im in enumerate(frames,1):
  path=a['ruta'].replace('_01.png',f'_{n:02}.png')
  metadata=PngImagePlugin.PngInfo()
  frame_source=source.format(frame=n) if '{frame' in source else source
  for k,v in {'art_stage':'integrated-review','status':'placeholder','asset_name':key,'author':'OpenAI imagegen; Codex crop/palette preparation','source':frame_source,'frame':str(n),'notice':'Original PNG artwork integrated for visual review; pending human approval. '+notes}.items():metadata.add_text(k,v)
  im.save(ROOT/path,pnginfo=metadata)
  records.append({'path':path,'asset':key,'frame':n,'size':list(size),'source':frame_source,'source_box':boxes[n-1] if len(boxes)>1 else boxes[0], 'sha256':hashlib.sha256((ROOT/path).read_bytes()).hexdigest(),'state':'integrated-review','status':'placeholder','author':'OpenAI imagegen / Codex Pillow preparation','date':'2026-11-01','transform':'crop, nearest-neighbor resize, alpha>=96 binary, shared maximum16 RGB palette; no geometric drawing','notes':notes})

def from_cells(key,sheet,cells,**kw):
 if args.only and key!=args.only:return
 crops=[cell(sheet,*c) for c in cells]
 if key in ('w01_bullet_shot_move','w01_bullet_missile_move','w01_fx_bubble_burst'):
  fitted=[]
  for im,box in crops:
   used=im.getchannel('A').point(lambda a:255 if a>=160 else 0).getbbox()
   cropped=im.crop(used)
   if key=='w01_bullet_missile_move':
    sprite=cropped.resize((14,6),Image.Resampling.NEAREST)
    tight=sprite.getchannel('A').point(lambda a:255 if a>=96 else 0).getbbox()
    sprite=sprite.crop(tight).resize((14,6),Image.Resampling.NEAREST)
    target=Image.new('RGBA',(16,8));target.alpha_composite(sprite,(1,1));cropped=target
   fitted.append((cropped,[box[0]+used[0],box[1]+used[1],box[0]+used[2],box[1]+used[3]]))
  crops=fitted
 if key=='w01_fx_bubble_burst':
  # Real Windows t20 revealed blue rims multiplied by red carrier tint
  # becoming dark blocks. The center was already transparent. Keep source
  # pearl highlights only and map their palette to light neutral grays.
  # Source alpha and source colors define the entire silhouette: no geometry.
  fixed=[]
  for im,box in crops:
   mapped=[]
   for r,g,b,a in im.getdata():
    if a>=96 and g>=140 and b>=160:
     pearl=min(255,210+round((g-140)*45/115))
     mapped.append((pearl,pearl,pearl,255))
    else:mapped.append((0,0,0,0))
   im=im.copy();im.putdata(mapped);fixed.append((im,box))
  crops=fixed
  kw['dimensions']=(32,32)
  kw['notes']='Original imagegen bubble cropped and alpha/color masked: retain only pearl highlights, remove dark blue backing colors; neutral light-gray palette avoids dark blocks under colored carrier tint. Promoted from8x8 to32x32 visual frame; gameplay hitboxes unchanged. Center and exterior remain transparent. Eight source frames; loop age-based playback.'
 if key=='w01_fx_spark_burst':
  fitted=[]
  for im,box in crops:
   used=im.getchannel('A').point(lambda a:255 if a>=96 else 0).getbbox()
   cx=(used[0]+used[2])//2;cy=(used[1]+used[3])//2
   region=(cx-48,cy-48,cx+48,cy+48)
   sprite=im.crop(region).resize((7,7),Image.Resampling.NEAREST)
   target=Image.new('RGBA',(8,8));target.alpha_composite(sprite,(0,0))
   fitted.append((target,[box[0]+region[0],box[1]+region[1],box[0]+region[2],box[1]+region[3]]))
  crops=fitted
 emit(key,[p[0] for p in crops],sources[sheet],[p[1] for p in crops],**kw)

for name,row,start in [('shot',0,0),('enemy',0,4),('missile',1,0),('laser',1,4),('homing',2,0),('bounce',2,4),('bomb',3,0)]:
 from_cells(f'w01_bullet_{name}_move','projectiles',[(row,c) for c in range(start,start+4)],fps=10,notes='Existing simulation, damage and collision sizes unchanged; source design faces right.')
for name,row,col in [('coin',4,0),('shot',4,2),('missile',4,4),('bomb',4,6),('shield',5,0),('score',5,2),('life',5,4),('magnet',5,6)]:
 from_cells(f'w01_ui_item_{name}_idle','projectiles',[(row,col),(row,col+1)],fps=8)
for name,row,col in [('sonar',6,0),('ctd',7,0),('deflector',7,4)]:
 from_cells(f'w01_ui_equipment_{name}_idle','projectiles',[(row,col),(row,col+1)],dimensions=(16,16),fps=8)
from_cells('w01_ui_hazard_idle','projectiles',[(3,c) for c in range(4,8)],fps=8,notes='Coral-colored anemone spine hazard on navy rock; no technical label.')
for name,row in [('explosion',0),('bomb',1),('hit',2),('bubble',3),('spark',4),('trail',5),('flash',6),('shield',7)]:
 from_cells(f'w01_fx_{name}_burst','fx',[(row,c) for c in range(8)],dimensions=(48,48) if name=='shield' else None,fps=12,notes='Eight original sequential source frames; age-based playback; trail and carrier bubble require looping time.')
# Muzzle uses an appropriately tight native canvas and collect uses the gold
# sparkle source. Distinct sizes/colors preserve role-specific visual behavior.
from_cells('w01_fx_muzzle_burst','fx',[(6,c) for c in range(8)],dimensions=(24,16),fps=24,notes='Directional cyan-white muzzle flash; short333ms playback.')
from_cells('w01_fx_collect_burst','fx',[(4,c) for c in range(8)],dimensions=(24,24),fps=16,notes='Gold collection sparkle, distinct from cyan weapon impact; 500ms playback.')

# UI sheet coordinates reflect actual generated placement, rather than prompt.
u=images['ui'];uw,uh=u.size
for key,box in [('w01_ui_panel_idle',(4,62,624,638)),('w01_ui_panel_selected_idle',(630,62,1247,638)),('w01_ui_hud_idle',(4,788,1247,884))]:
 emit(key,[u.crop(box)],sources['ui'],[box],fps=0,notes='Quiet navy instrument texture, no technical text; tint alpha supplied by runtime for translucent equipment panels.')

# Authorized palette variants derive exclusively from the preserved scientific
# ship's PNG silhouette. No original frame is overwritten and no shapes drawn.
skins={'batiscafo_amarillo':(0.135,0.82),'coral':(0.025,0.64),'abisal':(0.65,0.7),'bioluminiscente':(0.43,0.8),'magma':(0.015,0.9),'laboratorio':(0.52,0.2),'fantasma':(0.54,0.13),'dorado':(0.12,0.85)}
for skin,(hue,sat) in skins.items():
 frames=[]
 for n in range(1,5):
  original=Image.open(ROOT/f'assets/ui/w01_ui_ship_original_move_{n:02}.png').convert('RGBA')
  mapped=[]
  for r,g,b,a in original.getdata():
   h,s,v=colorsys.rgb_to_hsv(r/255,g/255,b/255)
   if a and v>.22:r,g,b=[round(c*255) for c in colorsys.hsv_to_rgb(hue,sat*.6 if v>.85 else sat,v)]
   mapped.append((r,g,b,a))
  recolor=original.copy();recolor.putdata(mapped);frames.append(recolor)
 emit(f'w01_ui_ship_{skin}_move',frames,'assets/ui/w01_ui_ship_original_move_{frame:02}.png',[[0,0,48,24]],notes='Palette-only derivative of original scientific ship; silhouette/anchor intact. Original scientific ship untouched. Hull motion handled by renderer.')

fragment={'state':'integrated-review','approval':'All PNGs remain placeholder pending B1 native visual review. No final approval claimed.','assets':assets,'provenance':records,'source_records':[{'path':p,'tool':'OpenAI imagegen','license':'Original generated artwork for this repository; no commercial game assets copied','date':'2026-11-01','sha256':hashlib.sha256((ROOT/p).read_bytes()).hexdigest()} for p in sources.values()]}
if args.only:
 old=json.loads((OUT/'fx-fragment.json').read_text())
 old['assets']=[a for a in old['assets'] if a['nombre']!=args.only]+assets
 old['provenance']=[r for r in old['provenance'] if r['asset']!=args.only]+records
 fragment=old
(OUT/'fx-fragment.json').write_text(json.dumps(fragment,ensure_ascii=False,indent=2)+'\n')
print(f'{len(assets)} animation keys, {len(records)} PNG frames prepared')
for a in assets:print(a['nombre'],a['tamano'],a['cuadros'],a['fps'])
