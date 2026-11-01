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

- El arte de producción es **PNG original** (sprites, atlas, fondos, tipografía, HUD, menú y efectos). JavaScript/Canvas **compone** los PNG; no dibuja como arte final criaturas con polígonos, curvas, rectángulos coloreados o SVG generados en código. Los placeholders son temporales, explícitos y rastreables mediante manifiesto.
- **Resolución lógica 640×360**, área jugable 640×336 y HUD 640×24. Escala entera ×1/×2/×3 cuando corresponda, centrado con barras cuando sobre espacio, `imageSmoothingEnabled = false`, `image-rendering: pixelated` donde aplique, sin suavizado ni desenfoque de sprites.
- Estética de **16 bits con pixel art coherente**: siluetas distinguibles, contorno oscuro de 1 px, luz arriba a la izquierda, 3–5 tonos para sombreado, hasta 16 colores por sprite; balas claramente legibles sobre todos los fondos. Consultar biblia y paletas en `docs/procedimientos-v2.md`.
- Generar y conservar `assets/assets_manifest.json`, atlas JSON y rutas PNG, con estado `placeholder`/`final` verificable. Reemplazar un PNG no debe exigir cambios en el motor. Placeholders y sus etiquetas no deben tapar controles; mostrar IDs/hitboxes de depuración **solo al pulsar F3**, nunca durante el juego normal.
- No copiar assets, sprites, música, nombres o personajes de videojuegos de referencia. Darius Gaiden, Axelay, Bio-Hazard Battle, Thunder Force IV y otros son referencias de mecánica/composición, no bancos de recursos.
- Probar visualmente menús, HUD, texto, colisiones y legibilidad **a 640×360 y 1920×1080**. Nunca afirmar que una pantalla «se ve bien» sin capturas de una sesión ejecutada.

## 4. Motor, datos y guardados

- Mantener el stack JavaScript + Canvas actual, y los valores numéricos en `data/` conforme a los contratos JSON. No introducir otro motor, framework o empaquetador salvo que sea imprescindible, justificándolo antes de cambiarlo.
- Desarrollo modular permitido en `src/`, pero las entregas serán **dos HTML autocontenidos** que funcionen sin internet en modo individual. Ningún PNG, tipografía o archivo esencial debe quedar dependiendo de una ruta externa tras generar la edición.
- Edición **Normal**: progresión, créditos y compras habituales.
- Edición **Pruebas**: mundos, etapas, armas y skins abiertos, selector de mundo y etapa; dinero ilimitado para **comprar** habilidades/equipos y mejoras. Estas compras empiezan **pendientes** salvo sonar inicial. No dar invulnerabilidad ni aumentar estadísticas automáticamente. La edición de pruebas no modifica la campaña normal.
- Mantener **guardados y preferencias separados** entre Normal y Pruebas. La nueva v2 no debe sobrescribir partidas anteriores incompatibles. Para HTML local, adaptar guardado a almacenamiento local versionado + exportación/importación JSON donde corresponda; no afirmar acceso libre a carpetas del usuario desde el navegador.
- No sustituir composiciones, canciones ni muestras musicales hasta que el usuario **reabra expresamente** ese trabajo. Mantener el audio existente mientras tanto, incluso cuando una fase toque audio: se puede implementar la infraestructura sin reemplazar pistas.

## 5. Fuente canónica y entregas

El HTML de la raíz es la fuente canónica del juego anterior mientras se migra; **no editar manualmente** los HTML generados de `versiones/`. Tras cualquier cambio que afecte una edición, ejecutar:

```sh
python3 scripts/build-editions.py
```

Comprobar que produjo:

- `versiones/poliquetos-normal.html`
- `versiones/poliquetos-pruebas.html`

Preferir enlaces individuales a ambos HTML en GitHub y no ZIP para la entrega del juego. No afirmar que un enlace descarga sin verificarlo; en repositorios privados se requiere acceso autorizado.

## 6. Pruebas obligatorias y puerta de aceptación

Antes de cerrar un encargo ejecutar y registrar el resultado real (no inventar):

```sh
node --test
python3 scripts/validate-v2-data.py --self-test
python3 scripts/build-editions.py
```

En cambios de inventario, ejecutar también `node scripts/inventory-legacy.cjs` y comprobar que los cambios fueron intencionales. Revisar la edición de Pruebas manualmente en navegador, con capturas comparables a **640×360 y 1920×1080**. Para funciones interactivas, verificar con clic y teclado; para guardados, probar sin datos, con partida válida, con partida antigua y con datos corruptos. En fases de rendimiento medir FPS, no deducirlos de la ausencia de errores.

En cada entrega informar:

1. Rama, commit y fase exacta; diferencias frente al estado inicial.
2. Archivos cambiados y funciones implementadas; estado `placeholder` o `final` de cada asset incorporado.
3. **Pruebas ejecutadas**, resultados y capturas reales. Si algo no se pudo probar, decirlo explícitamente.
4. Pasos reproducibles para que el usuario abra Normal y Pruebas y compruebe la fase.
5. Problemas conocidos, pendientes y **puntos que requieren aprobación** antes de la fase siguiente.

### Review guidelines (revisión de cada PR)

Priorizar defectos de funcionamiento, corrupción de guardados, colisiones/hitboxes, pérdida de progresión y referencias de assets inexistentes. Verificar que no se introduzcan dependencias en red para jugar en modo individual, que el arte final sea PNG, que los controles sigan siendo accionables y que los HTML generados no se hayan editado manualmente. Una prueba de sintaxis o `node --test` **no reemplaza** las pruebas visuales e interactivas. No aprobar una fase si incumple un criterio del spec.
