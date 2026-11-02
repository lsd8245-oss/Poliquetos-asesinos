# Encargo 04 — diseño revisable de 04B, 04C y 04D

**Propuesta documental; estos bloques no están autorizados ni implementados.** Base auditada `7dcad1c5a864305803d96aeddfeaeea8182c6a01`. La entrega actual sigue limitada a 04A. El arte B1, música existente, familias, 90 enemigos regulares W01, precios, vidas, daño y progreso se conservan. [Inventario y mapa de anclajes](ecologia-y-anclajes.md).

## Cronología que debe preservarse y discrepancia que debe resolverse

`data/worlds.json` declara W01: duración hasta jefe **180 s**, scroll **60 px/s**, minijefe **60 s**, ventana de 60 s y alerta **170 s**. `world_01.json` contiene 14 oleadas que suman 90 (36+54), con eventos regulares entre 10 y 162 s; no contiene un evento de nacimiento del jefe a 180.

| Hito | Datos / spec | Ejecución real según fuentes actuales |
|---|---|---|
| Minijefe | t=60, `mini_w01_pision` | Nace al alcanzar 60; si sigue vivo a120 no se borran las oleadas siguientes. |
| Alerta | t=170, `boss_w01_nereis` | `stages.step()` cambia a `alert` si `world_time>=170` y `mini_defeated`; el evento JSON `alerta_jefe` no es el disparador directo. |
| Scroll | 60 px/s; arena fija durante jefe | Solo avanza en `playing`; se detiene también en `alert`, en scroll≈10200 si el mini ya murió. |
| Entrada del jefe | duración nominal180 | `bosses.step()` espera 6 s (`combat.timings.alert`) y crea el jefe; entrada de3 s. Sin retraso del mini, nace≈176 s de simulación y combate activo≈179 s, con tolerancia de paso. |
| HUD durante jefe | barra usa duración180 como denominador | `world_time` permanece≈170; no pasa a180 automáticamente, aunque transcurra tiempo de encuentro. |

**170 es la alerta, 180 es la duración nominal del contrato; no son valores intercambiables.** Ni la foto en02:43 ni una referencia anterior a170 autoriza sustituir la duración de180. El spec §3.2 también describe alerta6 s y entrada aparte: requiere conciliar qué mide exactamente «hasta jefe». 04A no cambia ninguno de estos números ni el flujo. Si el minijefe dura más de170, la alerta/scroll final se retrasan.

Antes de fijar la arena04B, decidir: conservar la ejecución actual y documentar sus relojes, o ajustar en una entrega explícitamente aprobada el comienzo/entrada para cumplir un instante contractual concreto. No desplazar las oleadas ni ampliar la etapa como consecuencia implícita del terreno. El mapa debe funcionar con el scroll real congelado10200 y también contemplar retraso del mini; diseñar únicamente para scroll10800 (180×60) dejaría soportes mal colocados.

## 04B — terreno, anclajes y navegación

### Enfoques y propuesta técnica

1. **Mapa de piezas en coordenadas del mundo con colisión explícita (recomendado, pendiente).** Conserva compositor PNG/Godot y reloj actual; cada instancia de terreno tiene identidad estable, silueta, polígono local y anclajes. Permite comprobar rutas, soporte y checkpoints reproducibles. Exige producir/verificar piezas adecuadas.
2. Máscaras deducidas del alfa de los fondos existentes. Menor trabajo artístico inicial, pero las capas0.3/0.6, transparencias, fundidos y detalles de algas no definen un borde de contacto justo; habría que separar y revisar manualmente las máscaras. No se recomienda derivar sólidos automáticamente de B1.
3. Peligros rectangulares que dañan al atravesarlos. Es la infraestructura actual de boyas/cascos; sirve para peligros, pero no satisface paredes ni corredores. No se propone como solución de04B.

Propuesta de tres subzonas **narrativas de recorrido**, distintas del ciclo decorativo15 s existente:

| Subzona | Reloj de etapa / scroll nominal | Geometría y lectura propuesta |
|---|---|---|
| Introducción litoral | 0–60 s /0–3600 | Agua amplia, rocas bajas y un casco corto de techo; aprender a leer superficie sólida y tubo sin cerrar la ruta central. |
| Pecio y columnas | 60–120 s /3600–7200 | Minijefe junto a sedimentos, pasillos de suelo/techo, bifurcación alta/baja, pilares separados y una compuerta anunciada. Mantener espacio de escape del minijefe vivo al reanudar oleadas. |
| Plataforma en ruinas y aproximación | 120–170 s /7200–10200 | Ruinas con salientes y alternativas; salida progresiva a arena despejada antes de alerta. El contrato nominal sigue180, sin añadir10 s de oleadas. |

Los rangos siguientes son **borrador de geometría**, no datos cargados ni recorrido probado:

| Tramo mundial X | Límites o pieza propuesta | Ruta que debe conservarse |
|---|---|---|
| 0–1100 | Suelo Y=316, sin techo jugable | Agua abierta; ninguna colisión añadida en spawn `(80,168)`. |
| 1220–1500 | Roca con superficie Y=304 | Paso superior completo; alberga grupo Hydroides10. |
| 2060–2390 | Casco de techo hastaY54 y basa desdeY290 | Hueco central de236 px entre bordes; alberga Fabric24. |
| 3600–4500 | Suelo sedimentario Y=292, techo máximoY32 | Zona del minijefe con260 px de altura; no estrangular la pelea. |
| 4700–5150 | TechoY72 y sueloY264, con rampas visuales | Paso central192 px; enlace gradual desde zona anterior. |
| 5300–5550 | Bloque interior X=5360…5424, Y=128…208; sin techo/suelo intrusivos | Dos rutas por encima/debajo; no cerrar simultáneamente con disparos. |
| 5800–5840 | Compuerta propuesta, apertura centralY104…232 | Hueco mínimo128 px siempre disponible; avisar≥1 s antes de reducirlo, sin cierre total. |
| 6200–6900 | Salientes alternos, techo máximoY64/suelo mínimoY272 | Recuperación208 px y bifurcaciones que vuelven a unirse. |
| 7400–8200 | Ruinas bajas/altas sin cortarY96…240 | Aumento de mezcla de enemigos con ruta central144 px. |
| 9500–9960 | CubiertaY292/viga de techoY44 del mapa de anclajes | Paso248 px; salida con tiempo de reacción. |
| 10180–10840, ventana de arena a scroll10200 | **Pendiente:** retirar/recolocar todos los sólidos de ruta del volumen visible antes de alerta | El grupo Fabric162 sigue vivo; no retirar su soporte solo para limpiar la arena. Reubicar el conjunto, abrir una arena compatible o definir cierre de encuentro visible. No autorizar geometría definitiva hasta resolverlo. |

La compuerta no debe encerrar la nave entre borde izquierdo y pieza que avanza; la apertura es espacio libre real, no textura transparente sobre un collider. No aplicar nuevos cambios de velocidad o empujes del scroll a la nave.

### Contrato conceptual de datos (sin nuevos JSON de producción)

Futuro esquema propuesto; los nombres son orientativos, pendientes de aprobación:

| Entidad | Campos requeridos | Invariantes |
|---|---|---|
| Mapa | `world_id`, `map_version`, `scroll_units=px`, `pieces[]`, `anchors[]`, `route_checks[]` | Reproducible por versión/semilla, independiente del framerate; no duplicar calendario de oleadas. |
| Pieza | `id`, `world_origin`, `sprite_id`, `draw_layer`, `collision_polygon_local`, `kind`, `motion`, `persistent_state` | `kind=decor|solid|active_hazard`; sólido siempre visible, sin parallax ni fundido; una sola transformación para visual y colisión. |
| Anclaje | `id`, `support_id`, `local_foot`, `normal`, `orientation`, `enemy_uid`, `sprite_foot`, `muzzle_local` | Pie sobre borde del soporte, referencia existente y única; boca de disparo/hitbox transformadas junto al PNG. |
| Compuerta | `id`, `world_origin`, `phase_seed`, `telegraph`, `open_clearance`, `cycle` | Apertura mínima verificable en todo ciclo; reloj congelado en pausa; no usar tiempo del sistema. |
| Checkpoint futuro | `map_version`, `scroll`, `world_time`, `event_cursor`, `terrain_changes`, `gate_phase`, `anchor_occupants`, `claimed_drops`, `safe_player_position` | Restaurar el mismo estado o reconstrucción determinista equivalente; validar versión/IDs y evitar monedas duplicadas. |

Propuesta inicial: soportes indestructibles y compuerta determinista; así no se crea una regla nueva de caída del tubo. Si se desea terreno destructible, decidir antes cómo sobreviven/caen los ocupantes, qué IDs se persisten y qué rutas permanecen abiertas. No eliminar una criatura del presupuesto al destruir su pared sin definir baja/drop y reintento.

### Resolución de colisión y análisis de rutas

La nave actual se limita por el tamaño visual48×24 a X=24…616/Y=12…324; la hitbox de daño declarada es10×6. Elegir y documentar la envolvente de terreno: **recomendación pendiente** de impedir que el casco visual penetre (48×24), manteniendo la hitbox pequeña para proyectiles. Usar colisión continua/barrido entre posición anterior y deseada contra sólidos, resolver hasta contacto y deslizar tangencialmente. Considerar la velocidad relativa del sólido de60 px/s incluso con nave inmóvil; no dejar que el sólido la atraviese por falta de entrada del jugador. La regla de contacto/daño/aplastamiento debe aprobarse y probarse: no introducir muertes instantáneas por rutina.

Comprobar el mapa en el espacio del centro de la nave, expandiendo obstáculos por la semiextensión de la envolvente elegida. Un hueco visual128 px, con casco24 px alto y margen propuesto12 px a cada lado, deja80 px para el centro. Con hitbox pequeña sería distinto; no afirmar «hueco seguro» solo por medir el arte. Los anclajes no deben añadir invisible colisión fuera del tubo representado.

Propuesta de margen de reacción: obstáculo anunciado al menos1 s y a≥180 px horizontales útiles cuando se requiera mover100 px verticales. A velocidad base160 px/s ese desplazamiento tarda0.625 s; el margen adicional debe cubrir lectura y selección de ruta. Son metas de diseño para validar con estadísticas reales, no balance ya medido.

Verificador futuro: muestrear tiempo a1/60 s y espacio con resolución≤2 px o barridos exactos; construir estados alcanzables por movimiento8 direcciones normalizado, scroll y compuerta. Incluir trayectorias desde `(80,168)` y cada checkpoint con velocidad mínima legal, tamaños reales y posición temporal de todos los peligros. Registrar al menos una ruta completa y bifurcación alta/baja; buscar estados sin salida en la zona visible y borde izquierdo. Un grafo geométrico no basta para certificar justicia contra balas: reproducir luego la ruta con ataques reales y validar en PE exportado.

Fácil/Normal/Difícil usan geometría propuesta idéntica inicialmente; dificultad actual modifica daño0.7/1/1.3, velocidad de balas0.9/1/1.1 y vida de jefe0.85/1/1.15. No inventar huecos distintos ni invulnerabilidad para Pruebas. Verificar ruta en las tres dificultades, sin blindaje artificial; sumar presión de minijefe superviviente y formaciones de t120/t127. La aceptación exige maniobrar y poder evitar daño, no solo sobrevivir consumiendo escudo.

### Checkpoints, pausa y persistencia: estado actual y trabajo futuro

Hoy `make_checkpoint()` guarda en memoria `time`, `cursor`, `mini_defeated`, `regular_spawned`, `regular_kills` y `world_collected`; se activa al morir el mini y, en Fácil, al iniciar alerta. `retry()` recrea la partida con ese diccionario y conserva IDs de drops reclamados. Se vacían enemigos/peligros; no hay snapshot de soportes ni ocupantes. `start()` reconstruye scroll como `world_time*scroll_px_s`.

`PoliSave` escribe JSON versionado2, tres ranuras separadas `user://normal/slot_N.json` y `user://pruebas/slot_N.json`, backups `.bak`, validación y recuperación. **Eso no acredita reanudación intraetapa:** `main._start(profile, loaded)` llama `game.start(profile)` sin pasar checkpoint; `make_checkpoint()` no lo copia al perfil. El descanso sí se marca `resume=rest` y se guarda automáticamente. No afirmar que «Guardar y salir» vuelve al mismo tramo hasta probar y conectar explícitamente ese contrato en04B/04D.

Propuesta: reconstruir terreno estático desde mapa/versionado; persistir solo cambios y relojes necesarios. Restaurar un checkpoint debe recrear los soportes visibles y sus ocupantes definidos para él, sin repetir drops ni omitir enemigos del presupuesto. Precisar si el checkpoint es retroceso a un instante limpio o snapshot exacto de batalla; no mezclar ambos modelos. No migrar ni sobreescribir destructivamente partidas antiguas: campos opcionales con validación y fallback de inicio/descanso seguro, conservando copia.

Pruebas de aceptación04B: pie unido en todos los cuadros/orientaciones; F3 con contorno alineado al borde PNG; barridos a30/60/120 Hz; nave quieta contra sólido móvil; esquinas/diagonales; suelo/techo/pared; ralentización; pausa y cuenta atrás sin salto; morir/reintentar antes/después del mini; salvar/cerrar/cargar con compuerta en cada fase; versión antigua/desconocida; ausencia de duplicación de botín; ruta completa y vídeo en ambos PE. Primero ejecutar tests actuales para fijar regresión, luego casos de geometría. No usar solo headless como aprobación visual.

### Assets faltantes y puerta de04B

Existen PNG B1 `w01_bg_coast_rocks_idle`, `w01_bg_coast_pillars_idle`, `w01_bg_ruin_arch_idle` y `w01_bg_wreck_truss_idle`, además de algas/cadenas/agua y fauna. Son decoración integrada en revisión, no un kit sólido aprobado. Se conserva todo ese material.

Faltan para realizar el mapa: PNG originales de suelo/techo/laterales/esquinas de roca y casco con bordes legibles; columnas/repisa con caras de montaje; variantes de rotura y transición entre agua abierta/pecio/plataforma; compuerta con cuadros de aviso/apertura; máscaras o polígonos revisados contra esos PNG; metadata de pivote/base/boca y orientación para cada tubo; atlas/manifiesto y composición de arena compatibles. La prueba de rotación de B1 puede determinar si hacen falta variantes de tubo para techo/pared; no producirlas ni alterar los PNG actuales antes de revisión.

Puerta: aprobación04A en Windows del usuario, autorización04B y revisión de mapa/rutas/arena/colisión/persistencia/arte. Este documento no sustituye esas decisiones.

## 04C — desafío verificable de Pisionidae y Nereidae

Estado existente: `mini_w01_pision` tiene vida975, tamaño128×96, M4/F1 y dos fases100–50–0. Nereidae `boss_w01_nereis` tiene vida2319 (`vida_base=1750` conservada), tamaño180×120, tres fases100–66–33–0, cabeza×2/cuerpo×0.5, objetivo90 s y mínimo36 s de datos. No se modifica ningún valor en04A ni se presenta `vida_base` como vida actual.

Ya hay patrones reales: minijefe usa perfil `mini` con intervalos2.5/2.0, movimiento M4 y embestida telegrafiada en la ruta genérica; Nereidae tiene ráfaga apuntada fase1, carga+abanico fase2 y dos partes con persecución/anillos fase3. `patterns.gd` y `bosses.gd` implementan partes, bloqueo de3 s en transiciones y limpieza de balas. El informe del usuario motiva medir su cobertura; no afirmar que estos patrones faltan por completo ni que el mínimo36 s está garantizado para toda build humana.

Diseño propuesto, pendiente: auditar primero las trayectorias actuales y registrar zonas sin presión; ajustar secuencia/objetivos/cobertura/recuperación, conservando las fases del spec. No resolver con aumento aislado de HP.

| Encuentro/fase | Presión propuesta | Telegrafía y salida exigida |
|---|---|---|
| Pisionidae | Alternar aproximación corta desde sedimento, disparo a posición actual/pasada y embestida con pausa de recuperación; impedir quedarse a la izquierda fuera de todas las líneas. | Aviso visible0.6–1.0 s como propuesta ajustable; bloquear objetivo antes del golpe, sin seguimiento instantáneo. Debe existir escapatoria lateral/vertical compatible con terreno. |
| Nereidae1 | Ondulación vertical y ráfaga de3 a puntos de jugador muestreados; cambiar altura para cubrir seguros permanentes. | Señal de cabeza/corona; hueco entre trayectorias y pausa de ráfaga verificables. |
| Nereidae2 | Faringe y embestida horizontal con aviso, abanico5 desde parapodios y barrido secuencial de zonas. | Marcar carril antes del avance; dejar uno contiguo libre. No combinar dos ataques que cubran simultáneamente toda salida. |
| Nereidae3 | Dos partes con persecución y anillos12; alternar origen/tiempo, mostrar puntos débiles de cada parte. | Huecos recorribles y límite de aproximación al borde; impedir pinza inevitable entre partes y pared. Sin cuarta fase. |

Matriz futura: cada dificultad, arma inicial y build financiable alta, sin daño de prueba; mismos patrones en Normal/Pruebas con compras explícitas. Medir tiempo por fase/total, daño recibido, disparos evitables, coordenadas de seguros y cadencia efectiva. Prueba anti-AFK: mantener nave sin movimiento20–30 s en `(80,84)`, `(80,168)`, `(80,252)`, `(320,84)`, `(320,168)`, `(320,252)` y puntos seguros encontrados; empezar en varias fases del ciclo. Ninguna posición debe permitir pasar el combate completo indemne de forma permanente. En prueba complementaria, una trayectoria que esquiva debe poder evitar cada patrón sin daño obligatorio; matar al jugador inmóvil no certifica justicia.

Separar movimiento de presión de estadísticas: guardar una línea base y comparar con HP/daño/recompensas intactos. Si el mínimo36 s o economía requiere otro cambio, reportar medición y proponerlo por separado. Medir también minijefe vivo al reanudarse t120, entrada3 s, bloqueo3 s por transición y arena04B; no confundir tiempo invulnerable con dificultad útil. Registrar vídeo humano real y trayectorias en PE; no usar simulación con un millón de daño o invulnerabilidad como evidencia de balance.

## 04D — tienda, recompensas, guardado y cierre W01

Ya existe tienda funcional: `PoliShop.purchase/refund` valida visita/token, acto, dinero, máximo y equipo comprado; reembolso solo de transacciones de la visita abierta. Perfil Normal empieza0 créditos, Pruebas999999999; ambos empiezan únicamente con sonar instalado y mejoras rango0. La Draga/red pertenecen al acto1; los demás equipos se bloquean por acto en Normal. Pruebas puede comprarlos, no los equipa automáticamente. No reescribir el sistema para hacer el menú más claro.

Plan de pruebas04D sobre funcionamiento existente y mejoras futuras autorizadas:

| Caso | Comprobación funcional y visual |
|---|---|
| Todas las categorías | Costo, saldo, descripción1 línea, efecto antes/después, instalado/máximo/bloqueado; recorrer todas con mouse, teclado y mando. Ningún FX absorbe clics. |
| Compra real | Comparar perfil/estadística antes y después, saldo exacto, rango/equipo, efecto en combate; saldo insuficiente y compra duplicada no mutan datos. |
| Reembolso | Misma visita restaura costo/efecto; cerrar/reabrir bloquea reembolso anterior; varios rangos se revierten en orden; tokens/perfiles cruzados rechazados. |
| Ediciones | Pruebas mantiene dinero ilimitado y compra pendiente; Normal no recibe desbloqueos ni equipos de Pruebas; tres ranuras/preferencias separadas. |
| Equipos | Instrumento reconocible, texto activo/pasivo correcto; sonar activoQ configurable y12/4 aprobados para04A se reutiliza, CTD conserva vida/puntos débiles. No etiquetar todos los equipos como activos. |
| Guardados | Ausente, válido, antiguo, corrupto con `.bak` válido/inválido, versión futura, importación de otra edición, fallo de escritura; preservar datos originales y mensajes de error claros. |
| Continuidad | CompletarW01→resultados→descanso/tienda→guardar→cerrar→cargar→continuarW02 conservando monedas/mejoras/equipo; repetir sin comprar y tras reembolso. AccederW02 no autoriza producir su arte. |
| Guardar y salir intraetapa | Definir primero el contrato pendiente descrito en04B; verificar tiempo/posición/estado de mini, eventos, terreno y drops al reabrir. Hoy el serializador por sí solo no demuestra esa continuidad. |
| Feedback/accesibilidad | Daño, invulnerabilidad, debilidad, muerte y moneda distinguibles; reducir destellos/sacudidas respeta señales; rebinding válido con conflictos y mando; sin invulnerabilidad automática enPruebas. |
| Rendimiento y audio | Medir FPS/tiempos con50 enemigos/200 balas y escenas de ruinas/jefe/tienda en equipo objetivo; conservar música y SFX existentes autorizados. No extrapolar llvmpipe a Windows físico. |

Validación futura: `python3 scripts/test-native.py` y `--render` cuando haya pantalla; suites existentes de tienda/guardado/flujo más interacción en los dos EXE e instalación/desinstalación Windows real. Capturas640×360/1280×720/1920×1080 y resoluciones de pantalla04A; log con plataforma/DPI/mando reales. La validación de fuentes de este documento no ejecuta ni acredita estas pruebas.

Orden propuesto:04A aceptada→04B autorizada y comprobada→04C autorizada y medida→04D autorizada y recorrido integral. El mundo1 solo podrá declararse terminado tras esas aceptaciones; no se inicia ahora ninguno de estos bloques.
