"""Generate both standalone editions from the canonical game; no runtime dependencies."""
from pathlib import Path
import re
root=Path(__file__).resolve().parents[1]
source=next(p for p in root.glob('*.html'))
normal=source.read_text()
assert normal.count('const POLIGAMES_SANDBOX=false;')==1
sandbox=normal.replace('const POLIGAMES_SANDBOX=false;','const POLIGAMES_SANDBOX=true;',1)
# All save/progress/cosmetic/audio preferences stay separate from the normal profile.
sandbox=re.sub(r"(['\"])(pa\d*-[A-Za-z0-9_-]+)",lambda m:m[1]+'pruebas-'+m[2],sandbox)
sandbox=sandbox.replace("'poligames-gear-keys-v1'","'pruebas-poligames-gear-keys-v1'").replace("'poligames-campaign8-progress'","'pruebas-poligames-campaign8-progress'")
# Incompatible edition identities prevent mixed-mode cooperative sessions.
sandbox=sandbox.replace("'poligames-campaign8-1'","'poligames-campaign8-pruebas-1'")
out=root/'versiones';out.mkdir(exist_ok=True)
(out/'poliquetos-normal.html').write_text(normal)
(out/'poliquetos-pruebas.html').write_text(sandbox)
print('Generadas: versiones/poliquetos-normal.html y versiones/poliquetos-pruebas.html')
