# ENCARGO 04 — Poliquetos Asesinos v2: navegación, hábitat, accesibilidad y desafío del mundo 1

**Fecha de referencia:** 1 de noviembre de 2026.  
**Producto:** Godot nativo para Windows, ediciones Normal y Pruebas; NO HTML.  
**Rama base:** `pulido/w01-combate-vfx-b1`, verificar primero que sigue siendo la última rama aceptada; el commit observado al redactar este encargo es `7dcad1c5a864305803d96aeddfeaeea8182c6a01`.  
**Fuentes de diseño:** `AGENTS.md`, `docs/specs/poliquetos-asesinos-v2.md`, `docs/procedimientos-v2.md`, `docs/decisiones.md` y `docs/v2-progreso.md`. Ante contradicciones, conservar las decisiones sobre Godot/Windows y usar la especificación v2 para el contenido y cifras. No reescribir fases aprobadas ni el juego anterior.  
**Esfuerzo Codex recomendado:** **ALTO** para la primera entrega (04A). **MUY ALTO** para los futuros bloques de geometría/colisiones (04B) y comportamiento completo de jefes (04C).  
**Alcance inmediato:** implementar **solo 04A**. Los bloques 04B, 04C y 04D son un plan; requieren autorización posterior.

## 0. Evidencia del usuario y diagnóstico fundamentado

El usuario adjuntó un video de aproximadamente **148 segundos** (`prueba 1(3).mp4`). Se acompañan cuatro capturas:

- `evidencia_video/01_bordes_negros_windows.jpg`: ventana de Windows maximizada con título/barra de tareas visibles y el contenido jugable mucho menor que la superficie disponible.
- `evidencia_video/02_enemigos_y_habitat.jpg`: el mar se desplaza, pero no presenta relieve sólido que obligue a maniobrar.
- `evidencia_video/03_tubicola_sonar.jpg`: se ven organismos asociados a sustrato visualmente aislados y el HUD muestra **«SONAR LISTO»** sin tecla ni función explicada.
- `evidencia_video/04_jefe_nereidae.jpg`: presentación del jefe Nereidae y barra de vida; el usuario informa que puede derrotarlo sin moverse.

**Observaciones del usuario:** (a) la pantalla completa deja bordes negros, (b) los tubícolas/sedentarios aparecen flotando, (c) jefes y minijefes son excesivamente fáciles, (d) algunos enemigos tienen auras confusas, (e) el sonar aparece como disponible pero no se sabe activar, (f) faltan paredes, caminos, corredores y obstáculos con colisión que obliguen a navegar.

**Contraste con el repositorio:**

1. `project.godot` fija 640×360 y `display/window/stretch/scale_mode="integer"`. Es posible que una ventana maximizada de 1918×1078, menor que 1920×1080 debido a decoraciones o barra de tareas, caiga a escala entera ×2, con grandes márgenes. `src/core/main.gd::_apply_options()` también diferencia modos ventana y pantalla completa. Distinguir causa, no parchear a ciegas.
2. La especificación v2 §5.8.3 exige **tubícolas/sedentarios fijos al escenario**, arrastrados visualmente por el scroll. `Hydroides` (Serpulidae) y `Fabriciidae` ya están etiquetados como `tubicola`/`M5` en `data/enemies.json`; el movimiento tipo M5 conserva una Y fija pero no ancla físicamente el tubo a una roca/estructura visible.
3. El HUD dibuja `SONAR LISTO` para el equipo inicial, pero no se observa una entrada `sonar` en `src/core/main.gd::_held`/`_event_action` ni una acción implementada del sonar. **No afirmar que funciona** solo porque figura como instalado.
4. La especificación v2 §5.9 ya clasifica boyas y cascos como **obstáculos sólidos**; un simple sprite o una zona que solo quita vida no resuelve los corredores ni las colisiones de terreno.
5. El código ya implementa oleadas, disparos, tienda, minijefe y jefe. **No reemplazar** el motor, balance completo, sprites nuevos B1 ni datos de 14 mundos por una demostración aislada.

## 1. Priorización y alcance por bloques

| Bloque | Trabajo | Permiso actual | Esfuerzo |
|---|---|---|---|
| **04A** | **Pantalla realmente completa, sonar comprensible, semántica de auras, auditoría de objetos tubícolas** | **Sí, único bloque a ejecutar ahora** | **Alto** |
| **04B** | Terreno sólido/corredores jugables, anclaje tubícola, 3 subzonas del mundo 1, colisión y navegación | No, autorización posterior | **Muy alto** |
| **04C** | Minijefe Pisionidae y jefe Nereidae con patrones exigentes y justos, pruebas de dificultad | No, autorización posterior | **Muy alto** |
| **04D** | Pulido de tienda, recompensas, economía visible, guardado, rendimiento y validación integral W01 | No, autorización posterior | Alto |

No combinar 04A con 04B–04D. Entregar documentación y pruebas de 04A antes de cualquier trabajo mayor.

## 2. Bloque 04A — instrucciones que sí debe IMPLEMENTAR Codex

### 2.1 Pantalla completa sin franjas negras enormes

- Reproducir la captura en Windows real si se dispone; en caso contrario probar el EXE exportado con la mejor alternativa disponible y **declarar expresamente su limitación**.
- Registrar: resolución física, DPI, tamaño real de ventana, modo informado por `DisplayServer.window_get_mode()`, tamaño del contenido, escala usada, barras negras y situación de la barra de tareas.
- Ofrecer dos opciones explícitas en «Opciones > Pantalla»: **«Rellenar pantalla»** (preferida, sin franjas negras en monitores 16:9) y **«Píxel perfecto»** (escala entera; admite bordes cuando es inevitable). Mantener «Ventana x1/x2/x3».
- Para rellenar, conservar proporción sin deformar sprites: utilizar escala fraccional/ajuste seguro, o ampliar el área visual compatible, o recortar solo zonas de fondo sin ocultar amenazas ni HUD. Nunca estirar 16:9 a ultrawide arbitrariamente. **No cambiar la resolución lógica del combate (640×336 + HUD 24)** ni sus hitboxes por arreglar el modo pantalla.
- La opción de pantalla completa **real** no debe mostrar barra de título ni de tareas de Windows. No confundir maximizar con fullscreen. Permitir restaurar modo ventana, manejar Alt+Tab y cambios de resolución.
- Pruebas visuales: 1920×1080 (sin barras para «Rellenar»), 1366×768, 2560×1440, 1600×900 y, si es posible, un monitor 16:10. Captura completa, no recorte del área útil. En cada resolución, verificar que navegación, jefes y HUD quedan enteros.
- Añadir ajuste al menú accesible con teclado y mando. Documentar claramente qué se sacrifica al elegir «Píxel perfecto».

### 2.2 Sonar real y fácil de entender

- Confirmar que `sonar` es propiedad inicial en Normal y Pruebas; conservar esa regla. Si ya existe una función oculta, documentar y conectar su entrada; no construir dos implementaciones.
- Propuesta de interacción **por aprobar como decisión de diseño**: sonar activo con **Q** (configurable, y botón de mando configurable), pulso visual circular de barrido y **12 segundos de recarga**. *Este cooldown es una propuesta nueva: dejarlo en `data/combat.json` y anotarlo en `docs/decisiones.md`.*
- Efecto sugerido: revelar durante 4 s los peligros camuflados y los puntos de anclaje de enemigos tubícolas, y destacar con un contorno discreto los obstáculos próximos. El sonar **no inflige daño**, no atraviesa escudos ni reemplaza el CTD.
- HUD debe decir «**Q SONAR · LISTO**», «**SONAR · 08 s**» o «**NO INST.**» según estado; una primera utilización debe mostrar una explicación de una frase. Añadir al menú Controles y al tutorial de la primera etapa.
- Con una tecla/mando comprobado en la edición instalada, exigir pulso visible, cambio de texto y cooldown real. Evitar destellos agresivos; respetar «Reducir destellos».

### 2.3 Auras y etiquetas visuales comprensibles

- Auditar cada halo del mundo 1 y catalogar **origen**, condición, duración y significado: portadora de ítem, ataque cargando, invulnerabilidad, punto débil o decoración. Documentarlo.
- Suprimir auras permanentes puramente decorativas si confunden. Para una criatura que suelta botín, usar marcador discreto que se distinga de un escudo o un telegráfico; reservar pulsos intensos para ataques inminentes.
- F3 puede exponer datos técnicos; durante juego normal, no dibujar halos idénticos para estados distintos, hitboxes, IDs ni etiquetas de depuración.
- Capturas comparativas de una criatura normal, una portadora, una carga de ataque y un objetivo vulnerable; comprobar legibilidad sobre fondo claro y oscuro.

### 2.4 Informe de ecología tubícola (sin reprogramar aún las colisiones)

- Identificar tipos con `tipo=tubicola` o sedentarios, comenzando por **Hydroides (Serpulidae)** y **Fabriciidae** del mundo 1. Anotar sprite, formación, movimiento, posición y falta de sustrato.
- Preparar mapa de puntos de anclaje en relieve de mundo 1: roca, casco, columna sumergida, suelo o techo. Cada tubo tendrá un pie o base unido a su superficie y se desplazará **junto con ella** en coordenadas del mundo.
- Proponer conductas por tipo: Hydroides extiende/retrae corona y dispara desde tubo; Fabriciidae extiende filamentos y se esconde; especies errantes pueden nadar o reptar en ráfagas; Pisionidae se acerca a sedimentos. Mantener familias/IDs y conteos originales. No afirmar que todas las especies de la misma familia comparten idéntica ecología sin respaldo.
- En **04A** entregar diseño y lista de cambios; **la implementación del anclaje + geometría va en 04B**, no alterar por ahora los datos de oleadas o la dificultad.

### 2.5 Entregables y criterios de aceptación 04A

- Código en rama propia basada en la rama base aceptada; PR/commit, cambios acotados, documentación, comandos y logs.
- Dos **instaladores Windows** Normal/Pruebas reconstruidos y hashes SHA-256 de lo entregado; guardados independientes sin migración destructiva.
- Video de una sesión real con cambio ventana→rellenar→píxel perfecto, activación Q del sonar, estados de HUD/recarga y un grupo de criaturas con halos diferenciados.
- Prueba automatizada de modos y sonar + capturas reales a 640×360, 1920×1080, 1366×768. En reportes distinguir exportación PE bajo Wine de ejecución Windows nativa.
- No cambiar música, duración de niveles, estadísticas de jefes, compras, especies, número de enemigos ni el arte B1 salvo auras y UI necesarios para este bloque.
- Si el equipo no puede verificar fullscreen con un monitor Windows real, **declararlo pendiente**. No afirmar aprobación visual final basándose solo en modo headless.

## 3. Bloque 04B — DISEÑO APROBABLE, NO IMPLEMENTAR TODAVÍA

### Terreno que obliga a pilotar

- El mundo no puede consistir en una sucesión infinita de imágenes de fondo: crear un sistema de **geometría jugable en coordenadas del mundo** con sprites PNG originales, máscaras o polígonos de colisión, composición visual y colisiones sincronizadas. Las superficies siguen el scroll de 60 px/s.
- Diseñar el mundo 1 en **3 subzonas** diferentes de forma reconocible sin alterar la duración de 180 s hasta jefe: (1) aguas abiertas/introducción, (2) restos de barco y columnas con pasadizos, (3) plataforma/casco en ruinas y arena del jefe. Variar rocas, corales, cables, algas y boyas; la repetición de assets debe ser poco evidente.
- Incluir **corredores con techo/suelo**, rutas altas/bajas, obstáculos que deban esquivarse, una compuerta o hueco móvil telegrafiado, salientes y un campo de ruinas con rutas alternativas. No convertir la etapa en un juego de plataformas: el movimiento sigue siendo 8 direcciones con scroll horizontal automático.
- Distinguir capa decorativa (nunca colisiona) de sustrato sólido (siempre visible y colisiona) y peligro activo (señal previa y consecuencias). Evitar paredes invisibles, encierros y daños inevitables. Espacio libre adecuado a nave, hitbox y margen de reacción; analizar rutas con dificultad Fácil/Normal/Difícil.
- Tubícolas integrados a paredes, techo, suelo, rocas, casco o columnas. Su posición visible/hitbox/ataque se mueven junto al soporte. Si destruyes o atraviesas la estructura según mecánica elegida, la relación debe seguir siendo comprensible. Probar que nunca floten separados de su tubo.
- Mantener los **90 enemigos** y la cronología general W01, con minijefe Pisionidae alrededor de 60 s y alerta del jefe a 170 s. Cambiar formaciones y ubicaciones preservando presupuesto de enemigos, drops y economía; toda variación justificada.
- Tests: trayectoria real del jugador desde inicio hasta jefe, colisiones de casco/terreno, pausa/guardado/reintento, hitbox F3 y comprobación de huecos, reproducida en el **EXE exportado**. Si hay nuevos peligros, datos y pruebas de balance.

## 4. Bloque 04C — DISEÑO APROBABLE, NO IMPLEMENTAR TODAVÍA

### Jefes desafiantes, pero justos

- **No resolver la facilidad subiendo solo la vida.** Auditoría del minijefe Pisionidae y jefe Nereidae con métricas: tiempo de derrota por dificultad y arma inicial, daño recibido, zonas seguras, cobertura de ataques, duración efectiva de cada fase y pruebas de jugadores inmóviles.
- Minijefe: aparición telegráfica, persecución intermitente, disparos a la posición actual o pasada, embestida con aviso y recuperación visible; al menos un patrón que impida quedarse quieto sin riesgo.
- Nereidae: **tres fases realmente distintas** (persecución y mordida, abanicos/rastros y barrido de zonas, separación/partes móviles con puntos débiles); cambiar colocación y orientación, no solo cantidad de balas. Respetar el diseño y fases de la especificación, no inventar jefe nuevo.
- Introducir telegrafía clara (p. ej., 0,6–1,0 s ajustable) y al menos una vía segura de evasión por cada patrón. Balas enemigas visualmente diferenciables de las aliadas y de las monedas; tampoco permitir bloqueos totales contra las paredes del bloque 04B.
- Prueba anti-AFK: una nave **inmóvil durante 20–30 s** en varias posiciones no debe pasar todo el combate indemne por un punto seguro permanente. Prueba justa: una nave que esquiva correctamente debe poder superar el ataque sin recibir daño obligatorio.
- La dificultad crece mediante patrones, telegráficos, presión espacial y combinaciones, no mediante proyectiles invisibles, pérdidas de control, ataques inevitables o golpes fuera de pantalla.
- La salud, recompensas, daño, economía y duración deben verificarse respecto a `docs/specs/poliquetos-asesinos-v2.md`, `data/combat.json`, `data/bosses.json` y `data/boss_patterns.json` con pruebas, no cambiar valores sin reporte de balance.

## 5. Bloque 04D — PENDIENTE, NO IMPLEMENTAR TODAVÍA

- **Tienda y recompensas:** mostrar claramente costo, moneda disponible, mejora antes/después, equipo ya instalado, máximo de rangos, bloqueos por acto, compras/reembolsos reales y botón de continuar. Comprobar con mouse, teclado y mando.
- **Equipos oceanográficos:** todos los iconos representan instrumentos reconocibles; colores y textos legibles; distinguir pasivos de activos (solo sonar se propone activo en este encargo). Explicar función en una línea y dar pista en HUD cuando aplique.
- **Feedback de combate:** daño al jugador reconocible, invulnerabilidad temporal clara, puntos débiles, muertes, recogida de moneda, enemigos que se destruyen con efecto y sonido proporcionado.
- **Flujo completo:** completar W01 → resultados → tienda → guardado → continuar a W02, sin iniciar producción artística de W02. «Guardar y salir» debe funcionar y reabrir partida en el punto correcto.
- **Audio y rendimiento:** no reemplazar música existente sin autorización. Reutilizar SFX permitidos; probar 60 FPS en hardware objetivo; si falla, presentar mediciones y plan de mejora, no declarar cumplimiento ficticio.
- **Accesibilidad:** rebinding de Q/sonar, opción de reducir destellos/sacudida, subtítulos o iconos para señales importantes, diferencia Normal/Fácil/Difícil sin invulnerabilidad artificial en Pruebas.

## 6. Qué NO debe hacer Codex

1. No reemplazar Godot por HTML ni convertirlo en un prototipo estático.
2. No borrar nuevos recursos PNG ni degradarlos a figuras básicas de código.
3. No inventar una cuarta fase de Nereidae, alterar taxonomía, agregar mundos, cambiar 90 enemigos W01 o adelantar contenido del mundo 2.
4. No ocultar barras negras estirando horizontalmente la imagen, dejando enemigos fuera de la cámara o recortando el HUD.
5. No ofrecer un «sonar disponible» sin un efecto visible y comprobado.
6. No convertir organismos sedentarios en enemigos voladores flotantes.
7. No afirmar «todo probado» con solo `--headless`, capturas del editor o el EXE de Wine sin especificar limitaciones.
8. No avanzar a 04B–04D sin autorización explícita.

## 7. Formato de entrega de Codex

Entregar:

- Resumen de hallazgos y archivos modificados.
- PR/commit exactos de la fase **04A** únicamente.
- Demostración en video de pantalla completa real, sonar y auras.
- Capturas completas de los modos de pantalla y texto/controles legibles.
- Registro de pruebas automatizadas + manuales, indicando plataforma y resultados reales.
- Instaladores Normal y Pruebas con hashes SHA-256; indicar si falta verificar instalación/desinstalación en Windows físico.
- Lista priorizada para 04B y decisiones de diseño pendientes de aprobación.

**Puerta de aceptación:** el usuario debe probar 04A en su Windows y aprobarla antes de comenzar 04B. El resultado final de W01 no se declara terminado hasta superar también 04B–04D.
