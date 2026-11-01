"""Merge reviewed B1 PNG fragments; rebuild only W01 atlas. Never generate art."""
import json,importlib.util
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def pack(assets):
    from PIL import Image
    items=[]
    for a in assets:
        for i in range(1,a['cuadros']+1):
            im=Image.open(ROOT/a['ruta'].replace('_01.png',f'_{i:02}.png')).convert('RGBA')
            items.append((a['nombre']+f'_{i:02}',im))
    items.sort(key=lambda x:(-max(x[1].size),-x[1].width*x[1].height))
    free=[(0,0,2048,2048)];frames={};sheet=Image.new('RGBA',(2048,2048))
    def inside(a,b):return a[0]>=b[0] and a[1]>=b[1] and a[0]+a[2]<=b[0]+b[2] and a[1]+a[3]<=b[1]+b[3]
    for name,im in items:
        w,h=im.size
        fits=[r for r in free if w<=r[2] and h<=r[3]]
        if not fits:raise ValueError('W01 atlas cannot fit '+name)
        x,y,_,_=min(fits,key=lambda r:(min(r[2]-w,r[3]-h),max(r[2]-w,r[3]-h)))
        used=(x,y,w,h);new=[]
        for a,b,c,d in free:
            if x>=a+c or x+w<=a or y>=b+d or y+h<=b:new.append((a,b,c,d));continue
            if x>a:new.append((a,b,x-a,d))
            if x+w<a+c:new.append((x+w,b,a+c-x-w,d))
            if y>b:new.append((a,b,c,y-b))
            if y+h<b+d:new.append((a,y+h,c,b+d-y-h))
        new=list(dict.fromkeys(new))
        free=[a for i,a in enumerate(new) if not any(i!=j and inside(a,b) for j,b in enumerate(new))]
        frames[name]={'x':x,'y':y,'w':w,'h':h};sheet.paste(im,(x,y))
    animations={a['nombre']:{'frames':[a['nombre']+f'_{i:02}' for i in range(1,a['cuadros']+1)],'fps':max(1,a['fps']),'bucle':a['tipo']!='fx'} for a in assets}
    sheet.save(ROOT/'assets/atlas/w01.png')
    (ROOT/'assets/atlas/w01.json').write_text(json.dumps({'imagen':'w01.png','tamano':[2048,2048],'frames':frames,'animaciones':animations},indent=2)+'\n')

def main():
    file=ROOT/'assets/assets_manifest.json'
    manifest=json.loads(file.read_text())
    by_name={a['nombre']:a for a in manifest['assets']}
    for name in ('environment','fx'):
        frag=json.loads((ROOT/f'docs/arte/pulido-w01/{name}-fragment.json').read_text())
        for a in frag['assets']:
            a={k:v for k,v in a.items() if k in ('nombre','mundo','tipo','ruta','tamano','cuadros','fps','estado')}
            if a['nombre'] in by_name:by_name[a['nombre']].update(a)
            else:manifest['assets'].append(a);by_name[a['nombre']]=a
    file.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
    spec=importlib.util.spec_from_file_location('builder',ROOT/'scripts/generate-assets-v2.py')
    builder=importlib.util.module_from_spec(spec);spec.loader.exec_module(builder)
    pack([a for a in manifest['assets'] if a['mundo']==1])
    print('B1: fragments merged; only W01 atlas rebuilt')
if __name__=='__main__':main()
