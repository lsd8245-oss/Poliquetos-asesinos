# Poliquetos Asesinos — instrucciones permanentes para Codex

## 1. Alcance, autoridad y lectura obligatoria

Este repositorio contiene la versión anterior jugable y el rediseño v2, que **todavía está en construcción por fases**. Antes de modificar código, leer, en este orden:

1. `AGENTS.md` (este archivo): normas de trabajo y de entrega.
2. `docs/specs/poliquetos-asesinos-v2.md`: **fuente de verdad de las mecánicas, números, mundos y fases 0–10**.
3. `docs/procedimientos-v2.md`: **procedimiento operativo**, contrato de cada encargo, criterios de revisión e integración de arte.
4. `docs/decisiones.md` y `docs/v2-progreso.md`: decisiones ya aceptadas y estado comprobado de cada fase.

Si hay conflicto: instrucciones directas actuales del usuario > `AGENTS.md` (entregas y restricciones de trabajo) > especificación v2 (diseño) > procedimientos (cómo ejecutarlo) > documentación anterior. **No usar el PDF inicial para sobrescribir la v2**: el laboratorio tiene **250 enemigos y 5:30 hasta el jefe**, no 178 ni 4:00. No alterar taxonomía, distribución o patrones sin identificar la decisión y documentarla.

## 2. Alcance de cada encargo

- Una sola fase de la sección 13 de la especificación por encargo; **no avanzar a la siguiente fase sin aceptación explícita del usuario**. Un error crítico y reproducible puede resolverse en una rama de corrección acotada, sin mezclar otras funciones.
- Comenzar verificando **rama, commit, estado de trabajo y última fase aprobada**. No asumir que un video procede de la rama abierta: `rediseno-v2-fase-0` contiene la fase 0 y, según su registro, no implementa el nuevo motor visual.
- Una rama por fase (`rediseno-v2-fase-1`, `...-2`, etc.), creada a partir de la última rama aceptada; un commit coherente por entrega de fase. No cambiar la rama principal ni mezclar fases sin permiso.
- Conservar archivos, guardados y contenido previo como referencia mientras no se haya validado su reemplazo. No presentar placeholders ni prototipos técnicos como un juego v2 terminado.
- Si aparece una ambigüedad que afecta diseño, consultar la sección 14 de la especificación y `docs/decisiones.md`. Si el propio spec ofrece un valor por defecto, puede aplicarse identificándolo. Documentar en `docs/decisiones.md` las decisiones técnicas no triviales.

## 3. Reglas de arte y presentación (obligatorias)

- El arte de producción es **PNG original** (sprites, atlas, fondos, tipografía, HUD, menú y efectos). Godot **compone** los PNG; no dibuja como arte final criaturas con polígonos, curvas, rectángulos coloreados o SVG generados en código. Los placeholders son temporales, explícitos y rastreables mediante manifiesto.
- **Resolución lógica 640×360**, área jugable 640×336 y HUD 640×24. Escala entera ×1/×2/×3 cuando corresponda, centrado con barras cuando sobre espacio, filtro de texturas nearest-neighbor de Godot y escalado integer, sin suavizado ni desenfoque de sprites.
- Estética de **16 bits con pixel art coherente**: siluetas distinguibles, contorno oscuro de 1 px, luz arriba a la izquierda, 3–5 tonos para sombreado, hasta 16 colores por sprite; balas claramente legibles sobre todos los fondos. Consultar biblia y paletas en `docs/procedimientos-v2.md`.
- Generar y conservar `assets/assets_manifest.json`, atlas JSON y rutas PNG, con estado `placeholder`/`final` verificable. Reemplazar un PNG no debe exigir cambios en el motor. Placeholders y sus etiquetas no deben tapar controles; mostrar IDs/hitboxes de depuración **solo al pulsar F3**, nunca durante el juego normal.
- No copiar assets, sprites, música, nombres o personajes de videojuegos de referencia. Darius Gaiden, Axelay, Bio-Hazard Battle, Thunder Force IV y otros son referencias de mecánica/composición, no bancos de recursos.
- Probar visualmente menús, HUD, texto, colisiones y legibilidad **a 640×360 y 1920×1080**. Nunca afirmar que una pantalla «se ve bien» sin capturas de una sesión ejecutada.

## 4. Motor, datos y guardados

- Mantener **Godot 4.6.3 / Windows nativo**, `project.godot`, `native/` y los módulos GDScript de `src/`. Los valores numéricos permanecen en `data/` conforme a los contratos JSON. No recrear el motor ni cambiar plataforma sin una instrucción expresa. JavaScript/Canvas y los HTML se conservan únicamente como legado.
- Entrega final: **dos instaladores Windows independientes**, `entregas/Poliquetos-Normal-Instalar.exe` y `entregas/Poliquetos-Pruebas-Instalar.exe`, mediante el empaquetado nativo existente (NSIS). Ambas ediciones funcionan sin internet en modo individual; sus recursos esenciales viajan en el paquete. Los conceptos artísticos no equivalen a esa entrega final.
- Edición **Normal**: progresión, créditos y compras habituales.
- Edición **Pruebas**: mundos, etapas, armas y skins abiertos, selector de mundo y etapa; dinero ilimitado para **comprar** habilidades/equipos y mejoras. Estas compras empiezan **pendientes** salvo sonar inicial. No dar invulnerabilidad ni aumentar estadísticas automáticamente. La edición de pruebas no modifica la campaña normal.
- Mantener **guardados y preferencias separados** entre Normal y Pruebas. La nueva v2 no debe sobrescribir partidas anteriores incompatibles. En Godot, conservar las tres ranuras JSON y respaldos `.bak` en `user://`, con subdirectorios independientes para Normal/Pruebas según la implementación existente. No reescribir partidas. Instalación y configuración también deben ser independientes.
- No sustituir composiciones, canciones ni muestras musicales hasta que el usuario **reabra expresamente** ese trabajo. Mantener el audio existente mientras tanto, incluso cuando una fase toque audio: se puede implementar la infraestructura sin reemplazar pistas.

## 5. Fuente canónica y entregas

La fuente activa es `project.godot` con GDScript, datos y assets PNG. Conservar `scripts/build-native.py` y el empaquetado NSIS; el hito final exige los dos instaladores `.exe`, sumas SHA-256 e instrucciones de instalación/desinstalación. No reconstruir instaladores ni anunciar arte nuevo jugable durante un encargo de conceptos sin integración.

Los HTML de la raíz y de `versiones/` son legado conservado: no borrarlos ni editarlos por rutina. Solo si un encargo modifica ese legado, usar su fuente canónica y ejecutar `python3 scripts/build-editions.py`; nunca parchear los generados a mano. Sus pruebas Node corresponden a esa línea, no a la validación nativa.

Preferir enlaces individuales verificables, sin ZIP. No afirmar descarga o arranque Windows sin comprobarlo. Firmar instaladores solo si se dispone de una firma válida y declarar su ausencia cuando corresponda.

## 6. Pruebas obligatorias y puerta de aceptación

Antes de cerrar un encargo nativo ejecutar y registrar el resultado real (no inventar):

```sh
python3 scripts/test-native.py
```

Usar `python3 scripts/test-native.py --render` si hay pantalla/X display disponible; el modo headless no sustituye inspección visual. Conservar los registros y declarar cualquier limitación. No ejecutar `build-editions.py` por rutina en cambios exclusivamente nativos.

En cambios del legado, ejecutar además sus pruebas `node --test`, el validador `python3 scripts/validate-v2-data.py --self-test` y el generador correspondiente. En cambios del inventario heredado, ejecutar `node scripts/inventory-legacy.cjs` y revisar las diferencias intencionales.

Revisar Normal/Pruebas nativos con capturas reales a **640×360 y 1920×1080**; para la integración artística también a **1280×720**. Probar clics/teclado cuando haya cambios interactivos; guardados ausentes/válidos/antiguos/corruptos cuando se modifique persistencia. Medir FPS en encargos de rendimiento. En el hito final probar instalación/desinstalación, arranque, guardados y mando en Windows real; si no es posible, declararlo sin sustituir esa comprobación por Linux.

Conceptos y mockups deben identificarse como tales: no son capturas de Godot ni arte final aprobado. Esperar aprobación explícita antes de integrarlos o avanzar al mundo 2.

En cada entrega informar:

1. Rama, commit y fase exacta; diferencias frente al estado inicial.
2. Archivos cambiados y funciones implementadas; estado `placeholder` o `final` de cada asset incorporado.
3. **Pruebas ejecutadas**, resultados y capturas reales. Si algo no se pudo probar, decirlo explícitamente.
4. Pasos reproducibles para que el usuario abra las dos ediciones nativas y compruebe la fase; para conceptos, enlaces a PNG y puntos que debe aprobar.
5. Problemas conocidos, pendientes y **puntos que requieren aprobación** antes de la fase siguiente.

### Review guidelines (revisión de cada PR)

Priorizar defectos de funcionamiento, corrupción de guardados, colisiones/hitboxes, pérdida de progresión y referencias de assets inexistentes. Verificar que no se introduzcan dependencias en red para jugar en modo individual, que el arte final sea PNG, que los controles sigan siendo accionables y que el empaquetado nativo y los perfiles separados se preserven; si se toca el legado, que sus HTML generados no se editen manualmente. Una prueba de sintaxis o `node --test` **no reemplaza** las pruebas visuales e interactivas. No aprobar una fase si incumple un criterio del spec.

El piloto de `docs/encargos/01-piloto-visual-godot-w01.md` conserva su historia en `docs/arte/piloto-w01/`. Tras aceptar su dirección y confirmar el catálogo W01, el usuario autorizó continuar con la integración artística del mundo1: alcance y verificación en `docs/arte/integracion-w01/plan.md`. No avanzar al mundo2 ni interpretar esta autorización como aprobación final del lote o aceptación retrospectiva de fases.
