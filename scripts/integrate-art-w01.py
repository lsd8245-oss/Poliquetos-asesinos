"""Prepare original imagegen W01 artwork for review in Godot; no gameplay edits.

Sources and previous pilot are retained in docs/arte/. Crop, palette, alpha,
nearest scaling and PNG composition only; never draw animals with primitives.
Does not regenerate placeholders, music, data, other worlds or user saves.
"""
import hashlib
import importlib.util
import json
from pathlib import Path
from PIL import Image, ImageChops, ImageFilter, ImageOps, ImageEnhance, PngImagePlugin

ROOT = Path(__file__).resolve().parents[1]
DOC = ROOT/'docs/arte/integracion-w01'
PILOT = ROOT/'docs/arte/piloto-w01'
NEAREST = Image.Resampling.NEAREST
DARK = (17,32,48)
# Explicit limited ramps selected for each family's anatomical identity.
PALETTES = {
 'fire': ['112030','37233e','67263f','993349','bc3e48','d6574b','ed7a59','f89c70','b87759','e1bc91','fff2d9','e7deca','b0a6a4','736675','442f48','ffd5a8'],
 'fan': ['112030','2d294d','51446f','756198','9a86bb','bca6d2','e1d2e9','fff2dc','e7d0a5','c4a57d','947951','66523f','47353e','9c3545','e16669','efa494'],
 'sand': ['112030','35343d','57504e','7a7063','9c8c77','bca98d','d6c7a7','ece6c9','fff2d9','7c542d','aa7237','cf994f','ecc579','f9db97','4e4852','bd7f63'],
 'violet': ['112030','25263f','36344e','504560','6b587b','857099','a28cb0','c3afcc','ead6df','7d3049','ae395a','e76685','ffd9ce','b8a2b8','42394d','7d7289'],
 'gold': ['112030','3e302d','633e27','8c4d21','ad641e','d48423','f1a83c','ffd76e','fff0b0','e8c9a2','ba8b5a','815c3b','9e352a','e75f38','41282e','75562f'],
 'leaf': ['112030','293b37','365745','487254','609266','81b377','b6d693','e8efc0','4b472f','74693e','9d925b','c8bc88','22504d','307569','4ca08a','73c5a7'],
}


def load(path):
    return Image.open(path).convert('RGBA')


def binary(im):
    im=im.copy()
    im.putalpha(im.getchannel('A').point(lambda a:255 if a>=128 else 0))
    return im


def limited(im, ramp):
    alpha=im.getchannel('A')
    palette=Image.new('P',(1,1))
    colors=[tuple(bytes.fromhex(c)) for c in ramp]
    palette.putpalette([v for c in colors for v in c]+list(colors[0])*(256-len(colors)))
    rgb=Image.new('RGB',im.size,DARK)
    rgb.paste(im.convert('RGB'),mask=alpha)
    result=rgb.quantize(palette=palette,dither=Image.Dither.NONE).convert('RGBA')
    result.putalpha(alpha)
    edge=ImageChops.subtract(alpha.filter(ImageFilter.MaxFilter(3)),alpha)
    backing=Image.new('RGBA',im.size)
    backing.paste((*DARK,255),(0,0,*im.size),edge)
    backing.alpha_composite(result)
    return backing


def poses(name, size, ramp):
    source=binary(load(DOC/'originales'/f'{name}.png'))
    # The sources were visually inspected: exactly two isolated horizontal cells.
    split=source.width//2
    boxes=[(0,0,split,source.height),(split,0,source.width,source.height)]
    images=[]
    for box in boxes:
        image=source.crop(box)
        bound=image.getchannel('A').getbbox()
        if bound is None:raise ValueError('Empty source '+name)
        images.append(image.crop(bound))
    scale=min((size[0]-4)/max(p.width for p in images),(size[1]-4)/max(p.height for p in images))
    result=[]
    for im in images:
        im=im.resize((max(1,round(im.width*scale)),max(1,round(im.height*scale))),NEAREST)
        canvas=Image.new('RGBA',size)
        y=size[1]-2-im.height if name=='fabric' else (size[1]-im.height)//2
        canvas.alpha_composite(im,((size[0]-im.width)//2,y))
        result.append(limited(canvas,PALETTES[ramp]))
    return [result[0],result[1],result[0],result[1]]


def main():
    manifest=json.loads((ROOT/'assets/assets_manifest.json').read_text())
    by_name={a['nombre']:a for a in manifest['assets']}
    records=[]

    def put(key, frames, kind, source):
        folder='assets/backgrounds/w01' if kind=='bg' else 'assets/ui' if kind=='ui' else 'assets/sprites/w01'
        if key in by_name:
            asset=by_name[key]
        else:
            asset={'nombre':key,'mundo':1,'tipo':kind,'ruta':f'{folder}/{key}_01.png','tamano':list(frames[0].size),'cuadros':len(frames),'fps':8 if kind in ('enemy','mini','boss') else 1,'estado':'placeholder'}
            manifest['assets'].append(asset)
            by_name[key]=asset
        asset['tamano']=list(frames[0].size)
        asset['cuadros']=len(frames)
        if key.endswith('_hit'):asset['fps']=60
        # Individual new designs are reviewable, not automatically approved final.
        asset['estado']='placeholder'
        for i,im in enumerate(frames,1):
            path=ROOT/asset['ruta'].replace('_01.png',f'_{i:02d}.png')
            metadata=PngImagePlugin.PngInfo()
            for k,v in {'status':'placeholder','art_stage':'integrated-review','asset_name':key,'author':'OpenAI imagegen; selected crops/palettes and PNG preparation by Codex','source':source,'date':'2026-11-01','notice':'Original illustrated artwork integrated for review; not a labelled geometric placeholder or final approved art.'}.items():metadata.add_text(k,v)
            im.save(path,pnginfo=metadata)
            records.append({'path':str(path.relative_to(ROOT)),'asset':key,'size':list(im.size),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'source':source,'state':'integrated-review','author':'OpenAI imagegen / Codex Pillow preparation','date':'2026-11-01'})

    def creature(key, frames, kind, source):
        put(key+'_move',frames,kind,source)
        white=Image.new('RGBA',frames[0].size,'white')
        white.putalpha(frames[0].getchannel('A'))
        put(key+'_hit',[white,white.copy()],kind,source)

    # Approved pilot is integrated first; full source concept remains untouched.
    ship=load(PILOT/'A_nave_cientifica_48x24.png')
    for skin in ['original','batiscafo_amarillo','coral','abisal','bioluminiscente','magma','laboratorio','fantasma','dorado']:
        if skin not in ['original','batiscafo_amarillo']:continue
        image=load(PILOT/('A_nave_industrial_48x24.png' if skin=='batiscafo_amarillo' else 'A_nave_cientifica_48x24.png'))
        put(f'w01_ui_ship_{skin}_move',[image.copy() for i in range(4)],'ui','docs/arte/piloto-w01/A_variantes.png')
    creature('w01_enemy_hydroides',[load(PILOT/f'B_hydroides_move_{i:02d}.png') for i in [1,2,3,2]],'enemy','docs/arte/piloto-w01/originales/B_hydroides.png')
    for i,name in enumerate(['C1_agua','C2_puerto','C3_corrientes','C4_boyas'],1):put(f'w01_bg_layer{i}_idle',[load(PILOT/f'C_capa_{i:02d}_1280x336.png')],'bg',f'docs/arte/piloto-w01/originales/{name}.png')
    put('w01_ui_cover_idle',[load(PILOT/'D_ilustracion_640x360.png')],'ui','docs/arte/piloto-w01/originales/D_portada.png')
    panel=load(ROOT/'assets/ui/w01_ui_panel_idle_01.png')
    # Remove the old placeholder's label, preserving only its PNG panel material.
    panel=panel.crop((0,24,panel.width,panel.height)).resize((348,316),NEAREST)
    panel=ImageEnhance.Brightness(panel).enhance(0.3)
    panel.putalpha(panel.getchannel('A').point(lambda a:round(a*0.82)))
    put('w01_ui_cover_panel_idle',[panel],'ui','assets/ui/w01_ui_panel_idle_01.png (translucent derivative)')
    for state,name in [('','panel'),('_selected','panel_selected')]:
        material=load(ROOT/f'assets/ui/w01_ui_{name}_idle_01.png')
        material=material.crop((0,24,material.width,material.height)).resize((246,19),NEAREST)
        put(f'w01_ui_cover_button{state}_idle',[material],'ui',f'assets/ui/w01_ui_{name}_idle_01.png (label-free derivative)')

    enemies=json.loads((ROOT/'data/enemies.json').read_text())
    ramps={'euphrosine':'fire','fabric':'fan','pision':'sand','lacy':'violet','syll':'gold','phyll':'leaf'}
    for e in enemies:
        if e['id'] in ramps:
            name=e['id']
            creature('w01_enemy_'+name,poses(name,tuple(e['tamano']),ramps[name]),'enemy',f'docs/arte/integracion-w01/originales/{name}.png')
    creature('w01_mini_pision',poses('mini_pision',(128,96),'sand'),'mini','docs/arte/integracion-w01/originales/mini_pision.png')
    boss=poses('nereis',(180,120),'fire')
    root='w01_boss_boss_w01_nereis'
    creature(root,boss,'boss','docs/arte/integracion-w01/originales/nereis.png')
    # These pieces reconstitute the identical full image: no collision/AI edits.
    for piece in ['body','head','jaws','front','tail']:
        frames=[]
        for whole in boss:
            if piece=='body':im=whole.crop((45,0,180,120))
            elif piece in ['head','jaws']:
                im=whole.crop((0,0,45,120))
                region=(0,46,45,92)
                if piece=='head':im.paste((0,0,0,0),region)
                else:
                    patch=im.crop(region)
                    im=Image.new('RGBA',(45,120));im.alpha_composite(patch,(0,46))
            elif piece=='front':im=whole.crop((0,0,90,120))
            else:im=whole.crop((90,0,180,120))
            frames.append(im)
        creature(root+'_'+piece,frames,'boss','docs/arte/integracion-w01/originales/nereis.png (independent cropped piece)')
    # Hit pieces must reconstruct root hit geometry, which is frame01 only.
    (ROOT/'assets/assets_manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
    spec=importlib.util.spec_from_file_location('asset_builder',ROOT/'scripts/generate-assets-v2.py')
    builder=importlib.util.module_from_spec(spec);spec.loader.exec_module(builder)
    builder.pack_atlas(1,[a for a in manifest['assets'] if a['mundo']==1])
    (DOC/'procedencia.json').write_text(json.dumps({'state':'integrated-review','approval':'Style accepted; individual finished assets pending review in native game','records':records},ensure_ascii=False,indent=2)+'\n')
    print(f'W01: {len(records)} PNG frames prepared; only W01 atlas rebuilt. No gameplay data edited.')


if __name__=='__main__':main()
