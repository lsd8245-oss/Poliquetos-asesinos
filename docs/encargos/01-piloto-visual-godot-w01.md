# POLIQUETOS ASESINOS V2 — ENCARGO 01: CONCILIACIÓN NATIVA Y PILOTO VISUAL DEL MUNDO 1

**Destinatario:** ChatGPT Codex conectado al repositorio `lsd8245-oss/Poliquetos-asesinos`.
**Plataforma de producto:** Windows nativo, **Godot 4.6.3** (`project.godot`, `native/`).
**Rama documental observada:** `docs/instrucciones-redisenio-v2`, commit observado `f60abfb` (verificar HEAD antes de actuar).
**Rama nueva propuesta:** `arte/piloto-godot-w01`, creada desde la rama documental actual una vez comprobado que conserva la base `juego-nativo-v2`.
**Tipo de trabajo:** preparación de producción artística. **No es una fase nueva de mecánicas ni una aprobación retrospectiva de las fases 1–10.**
**Estado de este encargo intermedio:** documentación consistente con Godot + cuatro propuestas visuales para aprobación. **No es todavía la entrega final instalable; la entrega final se define más abajo como dos instaladores de Windows.**


## OBJETIVO FINAL DEL PRODUCTO (INALTERABLE) — WINDOWS, NO DEMO WEB

> **Esta sección define el formato de entrega final del proyecto, aunque este encargo concreto se limite al piloto gráfico.** No confundir las cuatro muestras artísticas de este encargo con el producto final terminado.

- **Producto final:** videojuego de escritorio **Poliquetos Asesinos**, instalado y ejecutado en **Windows** mediante **dos instaladores `.exe` independientes**, no mediante navegador, archivos HTML, simulaciones, mockups ni carpetas de scripts que el jugador deba ejecutar manualmente.
- **Edición Normal:** `entregas/Poliquetos-Normal-Instalar.exe`. Debe instalar el juego normal, crear accesos directos identificables y permitir iniciar y guardar la campaña con progresión ordinaria. No debe dar dinero infinito, invulnerabilidad ni desbloqueos de prueba.
- **Edición Pruebas:** `entregas/Poliquetos-Pruebas-Instalar.exe`. Debe instalar una edición separada que permite probar mundos, jefes y progresión con las funciones de depuración previstas por el proyecto; **mantener independientes sus rutas de instalación, partidas y configuración**, de modo que nunca sobrescriba la Normal. Las pruebas no sustituyen las reglas de combate real salvo funciones de depuración expresamente activadas.
- **Motor activo:** conservar **Godot 4.6.3**, el proyecto nativo y el empaquetado de Windows actual (incluidos los instaladores NSIS si siguen siendo válidos). No volver a generar como producto principal dos HTML, ni sustituir Godot por un motor nuevo. El HTML histórico solo se conserva como legado.
- **Diseño final:** juego lateral submarino con arte original de videojuegos de 16 bits; fondos PNG completos y múltiples capas, sprites animados detallados, jefes poliquetos monstruosos, menús e HUD terminados. **Nada de gráficos provisionales como presentación final.** Una portada conceptual o un PNG de muestra no acredita una interfaz jugable terminada.
- **Preservar el diseño:** 14 mundos más escape final, lista de familias y jefes, laboratorio de 250 enemigos, economía, combate y música conforme a `docs/specs/poliquetos-asesinos-v2.md` y decisiones de mayor prioridad. La mejora visual no autoriza modificar las mecánicas sin una solicitud expresa.
- **Entrega comprobable:** un proceso de compilación reproducible para ambas ediciones, instaladores de Windows firmados si se dispone de firma válida (si no, informar sin fingir firma), sumas SHA-256, instrucciones de instalación/desinstalación y comprobaciones de arranque, guardado/carga, mandos y rendimiento. **Si Codex no puede probar Windows en el entorno, debe declararlo y dejar pruebas manuales para el usuario; nunca declarar que ya fue probado en Windows sin ejecutarlo.**
- **Hito de aceptación final (futuro):** después de aprobar el arte y completar su integración, entregar exactamente las dos versiones instalables actualizadas y capturas reales del ejecutable, verificando que el juego se abre desde Windows, muestra el arte nuevo, permite jugar y guardar, y completa el recorrido previsto.

## 0. Orden de autoridad y problema que debes corregir primero

Antes de trabajar, lee completamente:
1. `AGENTS.md`
2. `docs/specs/poliquetos-asesinos-v2.md` (fuente de verdad del diseño)
3. `docs/procedimientos-v2.md`
4. `docs/decisiones.md`
5. `docs/v2-progreso.md`
6. `docs/revision-instrucciones-v2.md`, si existe en la rama.
7. `project.godot`, `scripts/test-native.py`, `scripts/build-native.py`, `assets/assets_manifest.json` y muestras de `assets/sprites/w01/`, `assets/backgrounds/w01/`.

Existe una **contradicción documental real**: algunos párrafos de `AGENTS.md` y `docs/procedimientos-v2.md` todavía obligan a usar JavaScript/Canvas, generar dos HTML y ejecutar `build-editions.py` como requisito de toda entrega. Pero `docs/decisiones.md` registra la decisión posterior del usuario de priorizar **Godot nativo para Windows**, y el proyecto real incluye `project.godot` e instaladores de **Normal** y **Pruebas**. Para este encargo, la plataforma objetivo explícita es Godot; HTML queda únicamente como legado conservado.

### 0.1 Entrega documental obligatoria (primera y separada)

- Modifica **solo los párrafos incompatibles** de `AGENTS.md` y `docs/procedimientos-v2.md`. Cambia la plataforma activa a Godot/Windows y la prueba obligatoria a `python3 scripts/test-native.py` (con render real cuando esté disponible). Conserva las normas útiles sobre PNG, arte original, resolución 640×360, no inventar pruebas y una tarea por encargo.
- Sustituye las menciones a “dos HTML como entregable nuevo” por dos **ediciones nativas**: Normal y Pruebas. Se preservan los HTML antiguos en `versiones/`, sin editarlos ni borrarlos. No ejecutar `scripts/build-editions.py` por rutina en un cambio exclusivamente de Godot; úsalo solo si se toca el legado.
- Guarda Normal/Pruebas **por separado**. En Godot, las tres ranuras/respaldos se ubican mediante `user://` según la implementación existente; no reescribas partidas.
- No cambies las mecánicas ni el balance; `docs/specs/poliquetos-asesinos-v2.md` permanece íntegro. El laboratorio tiene 250 enemigos y 5:30 hasta el primer jefe; hay 14 mundos y escape final.
- Documenta en `docs/decisiones.md` la conciliación. Registra commit documental independiente y reporta su hash.
- **No confundas los sistemas implementados con una aprobación artística.** Los PNG provisionales siguen siendo placeholders, incluso si las pruebas de código pasan.

## 1. Objetivo creativo del piloto

La identidad buscada es un *shoot 'em up* **submarino lateral de 16 bits**, con una **pequeña nave oceanográfica pilotada por un tripulante** que lucha contra **poliquetos biológicamente reconocibles, exagerados y monstruosos**. Referencia del *lenguaje visual* (no del contenido): **Darius Gaiden**, **Axelay**, **Thunder Force IV** y **Bio-Hazard Battle**. No se permite copiar sprites, personajes, música, fondos ni composiciones concretas de esos juegos.

La impresión final debe ser la de un videojuego comercial retro cuidadosamente dibujado: fondos con profundidad, siluetas claras, paletas coherentes, animación con intención y criaturas no intercambiables. **No** se aceptan serpientes suaves genéricas, emojis, dibujos por primitivas, SVG de código convertido a PNG, degradados vectoriales como arte de producción ni imágenes generadas que simplemente se reduzcan automáticamente de tamaño y se declaren pixel art terminado.

### 1.1 Reglas visuales

- Tamaño lógico Godot **640×360**; zona de juego **640×336** y HUD inferior **640×24**, escalado **nearest-neighbor / integer**, sin blur de sprites.
- **Sprites:** contorno oscuro de 1 px, 3–5 tonos para sombreado, **máximo 16 colores por sprite**, fondo transparente, píxel alineado y sin antialiasing.
- **Animaciones propuestas:** 2–4 cuadros para enemigos a 8–12 fps; el destello al recibir daño mantiene los **2 cuadros** previstos en el spec.
- El escenario del mundo 1 es **superficie marina luminosa**, azules/celestes/turquesas, destellos y agua clara; no un océano nocturno genérico. Cuatro capas de paralaje cuando corresponda, repetibles sin costuras.
- Protagonista y enemigos deben leerse a tamaño nativo 640×360 **sin aumentar artificialmente su hitbox**. Ningún nombre técnico, texto de placeholder ni interfaz debe tapar el combate.
- F3 puede mostrar hitboxes como elemento de depuración, pero no durante el juego normal.

## 2. Cuatro propuestas visuales — SOLAMENTE PARA APROBACIÓN

Crea una carpeta nueva `docs/arte/piloto-w01/` para **bocetos de propuesta**. Estos recursos NO reemplazarán los PNG en `assets/` hasta una aprobación posterior. Para cada propuesta entrega PNG original, hoja de variaciones cuando corresponda y una descripción breve de la intención artística.

### Propuesta A — Nave protagonista

- Nave submarina lateral de exploración, pequeña, con casco distintivo, propulsores, linterna/faros, cabina acristalada y **silueta visible del tripulante**. Un submarino heroico, no un círculo con una cara ni una nave espacial genérica.
- Construye un boceto legible al tamaño lógico **48×24 px** de juego y una ampliación **×8 por vecino más cercano** para que se aprecie el píxel.
- Entrega tres variantes **conceptuales** con la misma silueta básica (p. ej., científico-explorador, industrial y expedición militar oceanográfica) y elige una recomendada justificadamente.
- El arma debe leerse de un vistazo y el disparo orientarse a la derecha. No cambiar la hitbox de 10×6 ni controles.

### Propuesta B — Poliqueto Serpulidae (Hydroides), mundo 1

- Enemigo **tubícola**: tubo calcáreo, corona radiolar desplegable (abanico de filamentos), estructuras reconocibles y movimiento de retracción/extensión; no dibujarlo como lombriz o serpiente genérica.
- Conserva **la categoría y dimensiones reales del manifiesto/implementación Godot**. El documento de procedimientos da 32×32 como ejemplo, pero la rama nativa podría utilizar 48×48: **verifica los datos, no cambies el tamaño del actor por intuición**.
- Entrega silueta, paleta, 2–4 cuadros de movimiento y un ejemplo de destello de daño. Señala cómo se integra sin tocar la lógica de combate.
- Debe poder distinguirse del resto de poliquetos de la tabla 4.2.

### Propuesta C — Escenario del mundo 1 (superficie marina)

- Composición visible de **640×336 px** (HUD reservado debajo); **cuatro capas PNG independientes** de 640 px de ancho o múltiplo exacto y 336 px de alto mínimo, con empalme horizontal sin costuras.
- Profundidad propuesta: (1) agua y luz lejanas; (2) siluetas de embarcaciones/elementos portuarios lejanos; (3) corrientes, vida marina lejana y estructuras suaves; (4) boyas, espuma y obstáculos en primer plano.
- Mantén suficiente espacio y contraste para proyectiles brillantes, el jugador y los poliquetos. Fondos con personalidad, sin arruinar la legibilidad ni tapar el HUD.
- Presenta captura compuesta estática con la nave y Hydroides (puede ser un **mockup PNG**, no una partida ejecutada). Etiqueta con honestidad “MOCKUP” si no procede de Godot real.

### Propuesta D — Portada/menú (mockup conceptual, NO implementación)

- Boceto estático de **640×360** para el menú: **imagen ocupando todo el fondo**, con tripulante en submarino enfrentando una horda exagerada de poliquetos monstruosos, ráfagas de proyectiles, burbujas, luces y gran sensación de peligro. No un dibujo infantil plano ni un título gigante flotando sobre un fondo vacío.
- Reserva zonas de contraste para el logo `POLIQUETOS ASESINOS` y opciones legibles; no superponer letras ni colocar textos técnicos del motor.
- Mantén la perspectiva y la estilización compatibles con los sprites de juego. Es una **propuesta visual**, no el menú funcional final.
- Si usas una imagen generada como referencia de concepto, **distínguelo claramente** de pixel art final. No cites un render de concepto como screenshot de Godot.

## 3. Cómo producir las propuestas sin fingir que son finales

- Primero comprueba si en tu entorno está disponible una herramienta autorizada de creación de imágenes, por ejemplo la skill `$imagegen`. Si existe y el usuario puede usarla, úsala **solo para concept art** y después crea bocetos pixelados revisados conscientemente. Si no existe, di qué falta: **no sustituyas el encargo por polígonos generados en código y no afirmes que la IA creó ilustraciones que no creó**.
- Opcional: propón `scripts/pixelize.py` con **Pillow** para recortes, nearest-neighbor y cuantización a la paleta, pero **nunca** lo presentes como garantía de pixel art profesional. Las siluetas, el contorno y cada cuadro de animación requieren revisión manual/artística.
- Si un recurso ya existía en `assets/`, léelo para conservar ID, tamaño, pivote/offset y transparencia, pero no dupliques su arte provisional como nueva propuesta.
- Registra para cada ilustración su autor o herramienta, fecha, paleta, dimensiones, uso autorizado y estado “concepto/no aprobado”. No se deben incorporar recursos de videojuegos comerciales de terceros.

## 4. Límites estrictos de este encargo

**NO hacer ahora:**
- Programar o rediseñar los 14 mundos, jefes o economía.
- Alterar `data/` de enemigos, vida, habilidades, la tabla de balance, temporizadores o progresión.
- Rehacer el motor Godot en HTML, React, JavaScript, Unity, etc.
- Editar o sustituir música, canciones vocales, banda sonora o efectos de sonido.
- Borrar Godot, instaladores, `versiones/` HTML, ramas anteriores o guardados de usuarios.
- Compilar y anunciar una “versión definitiva con arte nuevo” antes de aprobar las muestras.
- Marcar `assets/assets_manifest.json` como `final` si el recurso sigue siendo concepto.

**SÍ hacer ahora:** corregir los documentos discordantes de plataforma, producir las cuatro propuestas conceptuales y una comparación clara con los placeholders actuales; dejar el siguiente paso listo para aprobación.

## 5. Evidencia y criterios de aceptación del piloto

Entrega **dos commits o PR claramente separados**, si hay cambios reproducibles: (A) conciliación documental; (B) recursos de concepto. No crees un gran cambio que mezcle mecánicas y arte. Para considerar el encargo revisable exige:

1. `AGENTS.md` y `docs/procedimientos-v2.md` ya indican **Godot/Windows como rama activa** y dejan el HTML como legado; sin romper el spec ni las decisiones previas.
2. Las **4 propuestas** están en `docs/arte/piloto-w01/`, con PNGs que se pueden abrir y un `README.md` de decisiones artísticas.
3. La nave protagonista es legible a **48×24**; Hydroides corresponde a Serpulidae; el fondo tiene capas coherentes; la portada tiene ilustración de fondo completo y texto separado.
4. Los sprites respetan paleta, contorno y escalado; la maqueta a 640×360 no muestra texto superpuesto ni proyectiles ilegibles.
5. No cambió ningún valor de combate, economía, guardados o música.
6. Ejecuta `python3 scripts/test-native.py` tras los cambios de documentación/arte cuando el entorno lo permita; entrega su salida. Usa `--render` solo si cuentas con pantalla/X display. **No confundas pruebas headless con inspección visual humana.** Si no puedes correrlas, di exactamente por qué.
7. Incluye capturas/PNG de las propuestas y una comparación con el arte previo. **No llames “captura del juego ejecutado” a un mockup.**
8. La respuesta presenta: rama, commit(s), archivos, pruebas realmente ejecutadas, imágenes propuestas, limitaciones y los puntos específicos que necesita aprobar el usuario.

## 6. Paso posterior — condicionado a aprobación expresa del usuario

**No lo realices en este encargo.** La meta global sigue siendo entregar los dos instaladores `.exe` de Windows funcionales, nunca un HTML como producto final. Una vez aprobada una dirección artística, integrar primero los recursos del mundo 1 en Godot (atlas/manifiesto/animaciones), verificar F3, parallax, legibilidad a **640×360, 1280×720 y 1920×1080**, capturar partidas reales y medir rendimiento. Solo después diseñar e integrar el **jefe Nereidae** y el resto de poliquetos del mundo 1, y posteriormente extender el estilo al mundo 2. Esta secuencia evita rehacer cientos de sprites por no haber aprobado el estilo.

## 7. Formato de respuesta exigido a Codex

```
PLATAFORMA: Godot 4.6.3, Windows nativo
FORMATO FINAL COMPROMETIDO: Poliquetos-Normal-Instalar.exe y Poliquetos-Pruebas-Instalar.exe (NO HTML)
RAMA BASE VERIFICADA: ...
RAMA DE TRABAJO: ...
COMMITS: documentación ... / conceptos ...
DOCUMENTACIÓN CONCILIADA: ...
PROPUESTA A — NAVE: archivos, tamaño, variantes y enlace/captura
PROPUESTA B — HYDROIDES: archivos, tamaño real, cuadros
PROPUESTA C — FONDO W01: capas, PNGs, mockup
PROPUESTA D — PORTADA: PNG completo
PRUEBAS NATIVAS: comandos y resultados observados, o limitaciones
ARCHIVOS DE JUEGO MODIFICADOS: ninguno (o justificar toda excepción)
ASSETS: concepto / placeholder / final aprobados (contar por separado)
PENDIENTES: ...
APROBACIONES QUE NECESITO DEL USUARIO: ...
NO AVANZAR SIN APROBACIÓN.
```
