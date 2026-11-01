# Poliquetos Asesinos — procedimientos de desarrollo v2 para Codex

**Estado:** guía de ejecución, no sustituto de la especificación de diseño. **Repositorio:** `lsd8245-oss/Poliquetos-asesinos`. **Rama de referencia comprobada:** `rediseno-v2-fase-0`. **Base de diseño obligatoria:** [`docs/specs/poliquetos-asesinos-v2.md`](specs/poliquetos-asesinos-v2.md). **Reglas permanentes:** [`AGENTS.md`](../AGENTS.md).

Este archivo es la versión **recortada y operativa** del documento «Poliquetos Asesinos: procedimientos para crear el juego», especialmente sus apartados **3.2, 3.4, 4, 6 y 7**. Describe **cómo** ejecutar y aceptar cada fase. El spec establece **qué** juego hay que construir. Conservar los archivos de la v2 y los juegos anteriores hasta que cada reemplazo esté comprobado.

## 0. Diagnóstico y estado de partida (obligatorio antes de programar)

- En la rama `rediseno-v2-fase-0` se registró **solo la fase 0**, con inventario heredado, contratos de datos, directorios de arte y el spec. El directorio `src/` del nuevo motor aún estaba vacío en el estado revisado. Revisar de nuevo el commit real antes de iniciar; un video mostrando otro motor debe provenir de una rama o un estado distintos.
- `docs/v2-progreso.md` documenta las pruebas de la fase 0. **Volver a ejecutarlas**: no dar por verificado un resultado de una sesión anterior sin indicar esa limitación.
- La especificación v2 fusionada prevalece sobre el PDF introductorio incompleto: **mundo 14 = 250 enemigos, 5:30 hasta el jefe**, seguidos de cuatro jefes; campaña objetivo de **1 h 30 min** y escape final de **5 min**. No mezclar los 178 enemigos del PDF antiguo.
- El producto final previsto son **dos HTML autocontenidos**, Normal y Pruebas. Solo una fase aprobada puede considerarse terminada; los rectángulos con etiquetas son un estado `placeholder`, no un juego artísticamente concluido.
- La música está **en pausa por decisión del usuario**. No sustituirla, reprocesarla ni crear nuevas pistas sin una nueva instrucción explícita.

## 1. Biblia de estilo aplicable a todo el proyecto (origen: §3.2)

Las decisiones siguientes se aplican a la nave, poliquetos, minijefes, jefes, objetos, menús y efectos:

| Regla | Aplicación y comprobación |
|---|---|
| Rejilla | Dibujar a escala 1:1 para **640×360** píxeles. Los píxeles deben quedar enteros y nítidos; escalado con vecino más cercano. |
| Silueta | Cada familia de poliqueto debe reconocerse con el sprite como silueta monocroma. Si se confunde con otra familia, corregir el arte. |
| Contorno | **1 px oscuro**, tomado de la propia paleta, evitando negro puro uniforme. |
| Luz y sombreado | Luz desde **arriba y a la izquierda**; entre **3 y 5 tonos** por color, sin degradados suaves. |
| Paleta | **Máximo 16 colores por sprite**, ajustados a la paleta del mundo. La paleta de un fondo puede ser más rica, pero debe respetar el contraste y la estética de píxel. |
| Legibilidad | Balas enemigas brillantes (amarillo, naranja, rosa, cian cuando se distinga del fondo); fondos más oscuros o menos saturados que actores y proyectiles. |
| Animación | Enemigos: **2–4 cuadros**, **8–12 fps**, ondulación característica; sin interpolación que suavice los píxeles. |
| Propiedad intelectual | No copiar ni calcar sprites, diseños, músicas o personajes de juegos comerciales de referencia. |

### 1.1 Paletas base por mundo (tomadas del documento de procedimientos)

Son los cuatro colores guía, no la paleta completa de cada sprite. No cambian los mundos definidos en la especificación v2.

| Mundo | Fondo oscuro | Fondo medio | Luz | Acento de criatura |
|---|---|---|---|---|
| 01 Superficie marina | `#0B3C5D` | `#1F8FC4` | `#BDF3FF` | `#FF7A59` |
| 02 Playas arenosas | `#0E5A66` | `#E8CF8E` | `#FFF3C4` | `#E0603A` |
| 03 Costa rocosa | `#26323D` | `#5C7A8C` | `#F2A65A` | `#7FA650` |
| 04 Bosques de kelp | `#0B3B2E` | `#2E8B57` | `#E9C46A` | `#E76F51` |
| 05 Arrecifes tropicales | `#0A2A6B` | `#00A6D6` | `#FF4FA3` | `#FF8A3D` |
| 06 Praderas de pastos marinos | `#0F4D3A` | `#5BC85B` | `#D8F27A` | `#F25C54` |
| 07 Estuarios y fango | `#3B3224` | `#7A6B3A` | `#D8B26E` | `#6B8E4E` |
| 08 Sedimentos contaminados | `#1D1030` | `#4B7F2A` | `#B7E34A` | `#9B4DCA` |
| 09 Zona planctónica | `#050B2A` | `#123C8C` | `#5CFFE0` | `#B388FF` |
| 10 Zona antártica | `#0B2C4A` | `#8EC9E8` | `#F4FBFF` | `#A8E6CF` |
| 11 Restos de ballena | `#1A1417` | `#8C8478` | `#D9CDB6` | `#B3261E` |
| 12 Campos hidrotermales | `#120707` | `#5A1A0F` | `#FF7A1A` | `#FFD23F` |
| 13 Zona hadal | `#02030A` | `#1A1240` | `#3FE0FF` | `#6A5CFF` |
| 14 Laboratorio | `#1C2430` | `#6F7F8F` | `#E6EEF2` | `#39FF88` |

Para peligro y alarma en todos los mundos usar **rojo `#FF3B30` y amarillo `#FFD23F`**. Los fondos de cada mundo tienen **3–4 capas** de parallax; no convertir todas las etapas en un mismo mar oscuro.

## 2. Especificación técnica y contrato de entrega de arte (origen: §3.4)

Codex **no dibuja el arte final**. Construye el cargador, las reglas de animación, los atlas y el manifiesto para que un artista pueda sustituir los PNG sin editar JS.

1. **Formato y nombres:** recibir PNG con canal alfa real y sin antialiasing. Convención `w{NN}_{tipo}_{nombre}_{accion}_{NN}.png`. Ejemplo: `w01_enemy_serpulidae_idle_01.png`. Mantener correspondencia exacta con `assets/assets_manifest.json`.
2. **Animaciones:** entregar cuadros individuales de dimensiones idénticas y el mismo punto de anclaje en la animación; idealmente el cuerpo ocupa ~70 % del cuadro. Ejemplo: `idle_01`, `idle_02`, `attack_01`, etc. Codex ensambla el atlas con un script reproducible; **el artista no debe empaquetar atlas a mano**.
3. **Hitboxes:** se definen en JSON/JS de datos, **no quedan dibujadas dentro del sprite**. F3 activa hitboxes y, cuando corresponda, IDs técnicos, solo en modo de depuración.
4. **Fondos:** por mundo, **3 o 4 capas** repetibles sin costura, ancho de **640 px o múltiplo** y alto de **336 px como mínimo**. De la más lejana a la más cercana: `w01_bg_layer1_idle_01.png` … `w01_bg_layer4_idle_01.png`. Las capas cercanas pueden tener alfa.
5. **Jefes articulados:** cabeza, cuerpo y apéndices/mandíbulas animables deben entregarse como piezas PNG separadas. Sus hitboxes y articulaciones se definen en datos; consultar el patrón de cada jefe en el spec.
6. **Tipografía:** fuente bitmap con `á é í ó ú ü ñ Á É Í Ó Ú Ñ ¿ ¡` y ASCII. No mostrar un texto si queda fuera del sprite o del panel; etiquetas técnicas solo con F3.
7. **Manifiesto:** `assets/assets_manifest.json` registra ID, mundo, tipo, dimensiones, frames, fps, ruta, estado `placeholder|final`, procedencia/licencia y observaciones. Cambiar el estado a `final` **solo si se ha revisado el PNG y se ve funcionando**.
8. **Atlas:** crear `assets/atlas/wNN.json` y `wNN.png`, comprobar coordenadas y límites, evitar frames solapados y rutas ausentes. Incluir pruebas automáticas para referencias cruzadas del manifiesto.
9. **Integración:** los PNG de producción se alojan en `assets/sprites/<mundo>/`, fondos en `assets/backgrounds/<mundo>/`; efectos e interfaz en `assets/fx/` y `assets/ui/`. El proceso de compilación debe incrustarlos en las dos ediciones HTML finales para juego individual offline.

**Ejemplo mínimo del encargo de un enemigo de prueba — Hydroides (Serpulidae), mundo 01:**

- ID de conjunto `w01_enemy_serpulidae`; **32×32 px** por cuadro.
- Reposo: 2 cuadros a 8 fps; ataque: 3 cuadros a 10 fps; daño: 1 cuadro; destrucción: 6 cuadros a 12 fps.
- Anatomía: tubo calcáreo, corona branquial, opérculo. Exageración monstruosa: penacho que se abre como una boca, sin perder la identificación de Serpulidae.
- Paleta guía: `#0B3C5D`, `#1F8FC4`, `#BDF3FF`, acento interior `#FF7A59`; evitar penacho amarillo intenso que se confunda con balas.

**Prueba de entrega:** sustituir un único PNG de prueba y ver que cambia en pantalla sin alterar JS; verificar en 640×360, atlas válido, anclaje sin saltos y F3 funcional. No declarar «arte final» si sigue siendo un rectángulo temporal.

## 3. Trabajo de Codex por fases (origen: §4)

### 3.1 Protocolo de una fase

**ANTES**

1. Leer `AGENTS.md`, el spec completo, este archivo, `docs/decisiones.md` y `docs/v2-progreso.md`.
2. Identificar el **commit y la rama** que realmente contienen el código a modificar. Comprobar cambios sin confirmar y partir de la última fase aprobada. Si el usuario adjunta un video de otra rama, localizar esa rama/commit antes de corregir nada.
3. Seleccionar **solo la fase N** de la sección 13 del spec. Abrir una rama `rediseno-v2-fase-N`; no implementar la N+1.
4. Enunciar entregables, archivos afectados, pruebas previstas y componentes expresamente fuera de alcance. Dejar los valores numéricos en datos JSON, no dispersos en JS.

**DURANTE**

5. Implementar pequeños cambios comprobables con tests. Mantener módulos, JSON, manifest y assets alineados; no inventar PNG definitivos ni sustituir audio. Si faltan assets, usar placeholders marcados como tales.
6. Añadir pruebas de comportamiento, errores y regresión. Si una función guarda estado o compra, incluir test de la operación real, no solo de que el botón se renderiza.
7. Reproducir manualmente el flujo correspondiente en navegador antes de decir «corregido». Comparar capturas a 640×360 y 1920×1080. Si se cambia el menú o la tienda, probar clics **en todas** las opciones.

**AL CERRAR**

8. Ejecutar comandos de la sección 5 y conservar el resultado completo. Generar los HTML **desde la fuente canónica**, nunca parchear los generados a mano.
9. Entregar referencia de rama/commit, archivos cambiados, capturas, instrucciones de prueba, pendientes, y las diferencias entre lo implementado y lo que aún es placeholder.
10. Esperar aprobación del usuario antes de empezar la fase siguiente.

### 3.2 Plantilla de encargo para copiar a Codex

```text
Repositorio: lsd8245-oss/Poliquetos-asesinos
Rama de partida: [última rama aceptada, con commit verificado]
Rama de trabajo: rediseno-v2-fase-[N]

Lee primero AGENTS.md, docs/specs/poliquetos-asesinos-v2.md,
docs/procedimientos-v2.md, docs/decisiones.md y docs/v2-progreso.md.

OBJETIVO ÚNICO: ejecutar la FASE [N], sección 13 del spec v2:
[nombre y alcance exactos de la fase].

ENTREGABLES:
- [archivo/función/asset 1]
- [archivo/función/asset 2]
- [prueba de aceptación específica]

FUERA DE ALCANCE: fases posteriores, música y sustitución de arte final
no suministrado. No reinterpretar los valores del spec.

REGLAS: PNG en el manifiesto, Canvas como compositor y no como artista;
lienzo 640×360, pixel perfect, sin suavizado; datos en JSON;
Normal y Pruebas independientes, guardados separados, sin internet
para jugar individualmente.

VERIFICACIÓN: ejecuta node --test,
python3 scripts/validate-v2-data.py --self-test y
python3 scripts/build-editions.py. Abre el juego realmente en Chromium;
prueba a 640×360 y 1920×1080, incluye capturas.

RESPUESTA: rama, commit, lista de cambios, pruebas con resultados
reales, pasos para probar, problemas pendientes y necesidad de
aprobación antes de iniciar la fase siguiente.
```

### 3.3 Si el video muestra un prototipo que falla: corrección independiente

El documento de procedimientos identifica defectos de presentación y guardado. Si persisten en la **rama correcta**, abrir una rama de corrección separada y verificar concretamente:

- **IDs superpuestos:** los nombres técnicos del placeholder se muestran una sola vez y **solo con F3**; nunca deben tapar el menú, el título o a otro enemigo.
- **Nave:** no dibujar texto dentro del sprite de 48×24; en modo normal solo el placeholder limpio hasta que llegue el PNG definitivo.
- **Guardado:** iniciar partida limpia si no existe guardado; restaurar guardado válido; manejar datos de una versión anterior y datos corruptos sin bloquear el inicio. Escribir pruebas para cada caso.
- **HUD:** íntegramente dentro de 640×360 (24 px de alto en el juego), sin rótulos recortados; mantener un margen visual de 8 px para contenido interno.
- **Ruido encima de botones:** localizar el elemento que lo produce, impedir que tape texto o intercepte clics; probar teclado y ratón.

Adjuntar **antes/después** de cada defecto y los resultados de tests. No iniciar otra fase durante el arreglo.

### 3.4 Entregables y criterios específicos por fase (resumen de §4.4)

| Fase | Objetivo único | Prueba de aceptación obligatoria |
|---|---|---|
| **0** | Inventario de 119 tipos, 14 mundos, esquemas de datos. **Registrada como terminada** en la rama de referencia. | `node scripts/inventory-legacy.cjs` + validador sin errores; no modificar el inventario sin motivo. |
| **1** | Cargador de PNG/atlas, manifiesto, fuente bitmap, lienzo 640×360 y F3. | Sustituir 1 PNG sin modificar código; pantalla pixel-perfect en dos resoluciones, sin desbordes. |
| **2** | Nave, controles, disparo, daño, colisiones, enemigo de prueba, parallax y HUD. | Jugar 2 min y probar movimiento/muerte; medir rendimiento con 200 balas, objetivo 60 FPS. |
| **3** | Armas de 8 niveles, misiles automáticos, bombas y burbujas de ítem. | Cada mejora cambia la forma/DPS conforme a tablas 5.3–5.6. |
| **4** | Etapa leída de oleadas JSON, movimientos M1–M8, disparos F0–F5, peligros y checkpoint. | Mundo 1: 90 enemigos, 40/60 %, minijefe, guardado del checkpoint, alerta a 2:50. |
| **5** | Jefes/minijefes segmentados, ataques anunciados, fases, puntos débiles. | Enfrentar un jefe de 3 fases; ninguna fase se salta; ataques fuertes avisan antes de golpear. |
| **6** | Economía/tienda, compra, reembolso, equipo por acto, resultados/descanso. | `balance_sheet.csv`, `shop_sheet.csv`; totales 17.900/21.480 de ingresos y 30.450 de costos; compras reales en Pruebas. |
| **7** | Portada, menú, opciones, pausa, muerte, guardado, skins, astillero, rejugar. | Guardar, cerrar y reabrir; recuperar partida, mejorar y reintentar sin errores. |
| **8** | Datos y contenido de mundos 1–13. | Verificar número de enemigos, duración, minijefe y jefe de cada mundo del spec. |
| **9** | Mundo 14: 250 enemigos, cuatro jefes encadenados, escape de 5 min. | Recorrer laboratorio y escape completos conservando estado entre descansos. |
| **10** | Sistema de audio **sin sustituir música**, efectos, rendimiento y balance final. | Juego entero cronometrado, objetivo 1 h 30 min, hábil ≈1 h 10 min; medir 60 FPS y 200 proyectiles. |

Las cifras exactas y excepciones están en el spec. Esta tabla es una puerta de aceptación, no reemplaza sus secciones 3, 5, 6, 7 y 13.

## 4. Integración de cada lote de arte (origen: §6)

1. Recibir PNG de **un lote** con IDs y tamaños del manifiesto. Comprobar paleta, 16 colores por sprite, contornos, transparencia, dimensiones, anclajes, ciclos, licencia y que el asset sea original.
2. Crear rama separada `arte-mundo-NN` desde la última rama jugable aprobada. Copiar los PNG a su ruta correcta, sin alterar la progresión ni el sonido.
3. Ejecutar el generador de atlas (si todavía no existe, implementarlo en fase 1), verificar que ningún frame desborde el atlas, actualizar `assets/assets_manifest.json` y pasar a `final` **solo** los cuadros efectivamente incorporados.
4. Ejecutar validación y compilación (sección 5), abrir **la edición Pruebas** y saltar al mundo correspondiente mediante el selector.
5. Jugar el mundo o una secuencia completa representativa. Activar F3 para comprobar hitbox; verificar que la imagen no se pixele de forma irregular, no salte de posición ni se tape con UI.
6. Registrar fallos por **ID exacto** (`w01_enemy_serpulidae_attack_02.png`), captura, síntoma y persona/proceso que debe repararlo. Rehacer el atlas y repetir la prueba tras la corrección.
7. Solicitar aprobación del usuario. Solo entonces integrar ese lote a la rama jugable.

| Síntoma visible | Responsable principal / corrección |
|---|---|
| Sprite borroso | PNG mal escalado (**arte**) o suavizado de render (**código**). Comprobar ambos. |
| Animación que «salta» | Cuadros mal anclados o de tamaño diferente (**arte/atlas**). |
| Bala confundida con criatura | Revisar contraste/paleta (**arte**). |
| Daño sin contacto aparente | Ajustar hitbox/datos y comprobar colisión (**código/datos**). |
| Costura en fondo repetido | Bordes de imagen (**arte**); confirmar también posición/scroll (**código**). |
| Letras o paneles recortados | Ajuste de interfaz/espaciado, clics bloqueados (**código**). |
| PNG invisible | Verificar ID, ruta y manifiesto (**integración/código**). |

**Hito decisivo:** aprobar el **mundo 1 totalmente dibujado y jugable** (fases 1–5 + assets finales de ese mundo) **antes de invertir recursos en los otros 13**. El ejemplo completo incluye fondo de 4 capas, poliquetos únicos/recurrentes, minijefe Pisionidae y jefe Nereidae. Ningún placeholder debe quedar visible en ese mundo al aprobar el hito.

## 5. Pruebas automáticas, visuales e hitos (origen: §7)

### 5.1 Comandos por entrega

```sh
node --test
python3 scripts/validate-v2-data.py --self-test
python3 scripts/build-editions.py
```

Si la fase cambia el inventario heredado, ejecutar además:

```sh
node scripts/inventory-legacy.cjs
```

No ejecutar el extractor indiscriminadamente si ello sustituye un inventario modificado sin revisión. Si hay dependencias de pruebas pendientes, preparar el entorno con `python3 -m pip install -r requirements-dev.txt` (el requisito actual del repositorio es `jsonschema`). Las herramientas de desarrollo **no se incluyen en los HTML distribuidos**.

### 5.2 Pruebas manuales innegociables

- Abrir Normal y Pruebas; revisar menú, opciones, navegación con teclado y ratón, pausa, reintento y vuelta al título según la fase disponible.
- Comparar capturas a **640×360** (resolución lógica) y **1920×1080**; mirar tipografía, superposiciones, clipping, brillo de balas y estados de foco.
- En Pruebas, saltar al mundo/sector que se quiere verificar **y comprobar que realmente arranca en esa etapa**, no solo que cambia el texto del selector.
- Probar el sistema de guardado con **sin guardado / válido / antiguo / corrupto** si ese sistema está involucrado. Los dos modos no deben pisarse.
- Tienda: visitar **todas** las categorías incluso si no hay dinero; ninguna capa de efectos puede bloquear clics; al comprar debe cambiar el estado del inventario y persistir según el spec; reembolso limitado a la misma visita.
- Medir estabilidad con **50 enemigos y 200 balas** cuando el motor ya lo soporte. No afirmar 60 FPS estables si no se midió sobre una ejecución real.
- Capturar evidencia reproducible. No sustituir screenshots o pruebas reales por comentarios «probablemente funciona».

### 5.3 Hitos de aprobación del usuario

| Hito | Momento | Decisión que debe tomar el usuario |
|---|---|---|
| 1 | Prueba de estilo con 3 assets reales | Aprobar estética y método antes de producir cientos de sprites. |
| 2 | Fase 2 completada | Aprobar sensación de control, movimiento y disparo antes de crear contenido. |
| 3 | Mundo 1 completo (fases 1–5 + arte final) | Aprobar ritmo, combates, animaciones y estilo comparados con las referencias. |
| 4 | Fase 6 | Aprobar balance económico, equipo y funcionamiento real de las compras. |
| 5 | Fase 8 | Aprobar mundos 1–13 jugables de inicio a fin. |
| 6 | Fase 10 | Aprobar duración real, rendimiento y sensación del juego completo. |

### 5.4 Formato obligatorio del informe de Codex al finalizar un encargo

```text
FASE: N — [nombre]
RAMA / COMMIT: [valor real]
CAMBIOS: [archivos afectados y propósito]
ASSETS: [cuántos final / placeholder; IDs relevantes]
TESTS AUTOMÁTICOS: [comando -> resultado observado]
PRUEBA MANUAL: [navegador, dimensiones, acciones y resultado]
CAPTURAS: [rutas/enlaces a capturas reales]
CÓMO PROBAR: [pasos concretos para Normal y Pruebas]
PENDIENTES / LIMITACIONES: [no ocultar]
APROBACIÓN: pendiente del usuario; no iniciar fase N+1
```

**Regla final:** un prototipo con sprites temporales, sin arte real y con pantallas rotas **no es el juego terminado**. Entregar correctamente una fase significa que sus pruebas pasan, su comportamiento se comprueba y sus límites están documentados.
