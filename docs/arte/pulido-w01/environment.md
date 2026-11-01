# Ambiente W01 · B1

Base `d31d3406f07868942bbd3f594bee78d0f12d63b7`, rama `pulido/w01-combate-vfx-b1`. Trabajo ambiental aislado: `src/visuals/w01_environment.gd`, 28 PNG originales y sus fuentes/preparación/manifiesto parcial. No cambia duración, oleadas, peligros colisionables, audio ni simulación. Los cuatro PNG de fondo anteriores permanecen intactos. Todos los assets nuevos conservan `estado: placeholder` hasta la revisión visual humana; esto significa pendientes de aprobación, no recuadros técnicos.

## Composición

`draw(canvas, assets, offset, time)` usa el scroll vigente de 60 px/s y cuatro velocidades: 0,1 agua lejana; 0,3 estructuras; 0,6 vegetación/fauna/partículas; 1,0 arrecife próximo y burbujas. El agua existente se atenúa con modulación fría; el resto son PNG nuevos transparentes. Las estructuras se reservan a la franja inferior y las cadenas pequeñas a la franja superior. El corredor de combate central queda abierto. Las boyas grandes repetidas se sustituyen por pilares costeros, arcos rotos y restos de estructura naval. Las cadenas nuevas tienen un pequeño flotador decorativo.

Tres sectores de 900 px de recorrido (15 s) cambian progresivamente durante 180 px (3 s), sin alterar los 180 s nominales hasta el jefe. A 0/15/30 s se ven pilares/arcos/restos, respectivamente; después repite la secuencia ambiental de 45 s. La distribución modular tiene períodos propios de 2880/2002/2398 px por profundidad y espaciado/escala deterministas. Es una composición visual cíclica, no una nueva cronología de oleadas. Las algas, cadenas, peces, burbujas, caústicas y plancton tienen cuatro PNG por bucle; cada instancia recibe fase y velocidad diferentes. Los peces no saltan de altura al cambiar de sector.

## Fuentes y preparación

Imagegen generó las dos hojas originales `fuentes/environment-objects.png` y `fuentes/environment-particles.png` el 2026-11-01. No se copiaron sprites de otros juegos. `prepare-environment.py` solo recorta, aplica alfa binario, reduce a una paleta compartida de 16 colores por animación y escala con nearest. No dibuja objetos, fondos o partículas. `environment-fragment.json` registra dimensiones, cuadros, fps, rutas, SHA-256 de fuentes/cuadros y cajas de recorte. Integrar únicamente `assets` en el manifiesto canónico; `provenance` es documentación separada del esquema estricto. Usan tipo `bg` para bucles ambientales; los `fx` del cargador son de un solo uso.

## Verificación realizada

- Godot 4.6.3 `--headless --check-only --script src/visuals/w01_environment.gd`: salida 0, sin errores de script. Requiere XDG_DATA_HOME/CONFIG_HOME/CACHE_HOME en una ruta escribible en este entorno.
- Fixture real de Godot con OpenGL compatibility, Mesa llvmpipe, DISPLAY=:91: 11 capturas a 0/14,9/15/29,9/30/44,9/45/59,9/120/159,9/160 s, incluyendo transiciones y reinicios modulares. Log en `docs/verificacion/pulido-w01/environment/render-fixture.log`. Inspección visual de 0/15/30 s: siluetas diferenciables, corredor abierto, sin bloques opacos de fondo.
- Las capturas son **fixtures ambientales aislados**, sin nave, combate ni HUD; no son evidencia de partida humana o de EXE Windows. El script reproducible está en `docs/verificacion/pulido-w01/environment/capture-fixture.gd` y se ejecuta desde la raíz con `godot --path . --audio-driver Dummy --rendering-method gl_compatibility --script docs/verificacion/pulido-w01/environment/capture-fixture.gd` bajo un DISPLAY disponible.
- La suite nativa, integración en main/manifiesto/atlas, capturas de combate a tres escalas y exportación corresponden a la integración B1 global. Esta subentrega no declara aceptación artística ni Windows físico.
