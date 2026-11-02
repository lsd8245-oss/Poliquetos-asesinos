# Encargo 04A — ecología y propuesta de anclajes W01

**Estado: auditoría de fuentes y propuesta para 04B, sin implementación ni aprobación de 04B.** Base inspeccionada: `7dcad1c5a864305803d96aeddfeaeea8182c6a01`, rama `fix/w01-04a-pantalla-sonar-auras`, 2 de noviembre de 2026. Los cambios de pantalla/sonar/auras de 04A se documentan aparte. Este informe no modifica oleadas, colisiones, criaturas, arte B1 ni datos de otros mundos.

Fuentes: [encargo 04](../../encargos/04-diagnostico-espacial-ecologia-dificultad-w01.md), [spec §3.2, §5.8–5.9](../../specs/poliquetos-asesinos-v2.md), [procedimientos §2](../../procedimientos-v2.md), [decisiones](../../decisiones.md), [estado por entrega](../../v2-progreso.md), `data/enemies.json`, `data/worlds.json`, `data/waves/world_01.json`, `src/stages/stages.gd`, `src/visuals/w01_environment.gd`, `src/core/game.gd` y `src/core/main.gd`. Los ejemplos antiguos de IDs/dimensiones del spec no sustituyen los IDs y PNG cargados hoy.

## Evidencia examinada y alcance de las conclusiones

Se abrieron las cuatro fotografías del usuario mediante el visor de imágenes:

| Evidencia | Observación verificable | Límite |
|---|---|---|
| [01, ventana Windows](../../evidencias/encargo04/01_bordes_negros_windows.jpg) | Título/barra de tareas visibles y área de juego central pequeña; dos tubícolas aparecen en alturas opuestas. | Una foto no acredita fullscreen real ni DPI/configuración exacta. |
| [02, hábitat](../../evidencias/encargo04/02_enemigos_y_habitat.jpg) | Columnas, algas y fondo ocupan la zona inferior; no hay un corredor cerrado visible. | La foto sola no prueba colisiones; su ausencia de resolución sólida se verifica en el código. |
| [03, tubícola y sonar](../../evidencias/encargo04/03_tubicola_sonar.jpg) | Dos coronas con halo azul; la superior está separada del relieve, la inferior se superpone visualmente a ruinas. HUD «SONAR LISTO». | Superponer píxeles no constituye un vínculo al soporte. No deducir el ID individual solo por esta foto. |
| [04, Nereidae](../../evidencias/encargo04/04_jefe_nereidae.jpg) | Barra de fase 1 y silueta blanca de impacto. | No permite medir dificultad ni demuestra por sí sola una zona segura permanente. |

No se ha ejecutado una prueba de terreno en este subtrabajo documental. Las posiciones siguientes se derivan de datos y funciones, no son una nueva captura de juego.

## Inventario de los actores afectados

En `data/enemies.json` hay **18 IDs con `tipo=tubicola`, todos M5/F3**, y una torreta robótica M5/F3. No existe otro M5 fuera de esta lista. «Tubícola» es la clasificación operativa del catálogo; no es una afirmación sobre todas las especies de cada familia. La tabla §5.8.3 del spec es una agrupación de juego y no autoriza generalizaciones taxonómicas nuevas.

| ID exacto | Familia/nombre que figura en datos | Tipo | Mundos | `sprite_set` por mundo |
|---|---|---|---|---|
| `hydroides` | Hydroides · Serpulidae | tubicola | 1, 14 | `w01_enemy_hydroides`, `w14_enemy_hydroides` |
| `fabric` | Fabriciidae | tubicola | 1, 14 | `w01_enemy_fabric`, `w14_enemy_fabric` |
| `serp` | Serpulidae | tubicola | 3, 10, 12, 14 | `w03_enemy_serp`, `w10_enemy_serp`, `w12_enemy_serp`, `w14_enemy_serp` |
| `spirorbis` | Spirorbis · Serpulidae | tubicola | 4, 14 | `w04_enemy_spirorbis`, `w14_enemy_spirorbis` |
| `myxicola` | Myxicola · Sabellidae | tubicola | 4, 14 | `w04_enemy_myxicola`, `w14_enemy_myxicola` |
| `spirobranchus` | Spirobranchus giganteus · Serpulidae | tubicola | 5, 14 | `w05_enemy_spirobranchus`, `w14_enemy_spirobranchus` |
| `sabellastarte` | Sabellastarte · Sabellidae | tubicola | 5, 14 | `w05_enemy_sabellastarte`, `w14_enemy_sabellastarte` |
| `diopatra` | Diopatra · Onuphidae | tubicola | 6, 14 | `w06_enemy_diopatra`, `w14_enemy_diopatra` |
| `chaetopterus` | Chaetopteridae · Chaetopterus | tubicola | 6, 14 | `w06_enemy_chaetopterus`, `w14_enemy_chaetopterus` |
| `sabellaria` | Sabellaria · Sabellariidae | tubicola | 6, 14 | `w06_enemy_sabellaria`, `w14_enemy_sabellaria` |
| `pectinaria` | Pectinaria · Pectinariidae | tubicola | 6, 14 | `w06_enemy_pectinaria`, `w14_enemy_pectinaria` |
| `terebellides` | Terebellides · Trichobranchidae | tubicola | 7, 14 | `w07_enemy_terebellides`, `w14_enemy_terebellides` |
| `owenia` | Owenia · Oweniidae | tubicola | 8, 14 | `w08_enemy_owenia`, `w14_enemy_owenia` |
| `perkinsiana` | Perkinsiana · Sabellidae | tubicola | 10, 14 | `w10_enemy_perkinsiana`, `w14_enemy_perkinsiana` |
| `amphar` | Ampharetidae | tubicola | 10, 14 | `w10_enemy_amphar`, `w14_enemy_amphar` |
| `riftia` | Siboglinidae · Riftia pachyptila | tubicola | 12, 14 | `w12_enemy_riftia`, `w14_enemy_riftia` |
| `paralvinella` | Paralvinella · Alvinellidae | tubicola | 12, 14 | `w12_enemy_paralvinella`, `w14_enemy_paralvinella` |
| `amphisamytha` | Amphisamytha · Ampharetidae | tubicola | 12, 14 | `w12_enemy_amphisamytha`, `w14_enemy_amphisamytha` |
| `mech_sabel` | Torreta Sabélida | robotico | 14 | `w14_enemy_mech_sabel` |

Los otros IDs W01 son `euphrosine` (escamoso, M7/F2, 48×48), `pision` (otro, M4/F1, 32×32), `lacy` (otro, M4/F1, 32×32), `syll` (enjambre, M2/F1, 24×24) y `phyll` (errante, M3/F2, 32×32). M4 es entrada vertical/diagonal, no anclaje sedentario; no se cambia su ecología por pertenecer al mismo mundo. La proximidad a sedimento propuesta para Pisionidae gigante es dirección escénica del encuentro, pendiente de validar, no un cambio de familia o IA en 04A.

Para Hydroides y Fabriciidae se cargan las animaciones `w01_enemy_hydroides_move` y `w01_enemy_fabric_move`: **48×48, cuatro cuadros, 8 fps**. Hay dos cuadros `_hit` a 60 fps. Rutas: `assets/sprites/w01/w01_enemy_{hydroides|fabric}_{move|hit}_{NN}.png`; manifiesto `placeholder` y estado artístico de revisión integrado. El ejemplo de procedimientos de Hydroides 32×32 no describe estos PNG actuales.

## Posición real W01: la formación no es el anclaje

`spawn_wave()` genera toda la formación en el mismo evento. **`separacion_seg=0.3` no se consume para espaciar los nacimientos.** `linea_vertical` ignora el `y` del evento. `ambos_lados` significa borde alto/bajo; no dos lados horizontales. Los pares siguientes son centros del actor en píxeles lógicos, antes del primer movimiento:

| Evento / UID | Datos de oleada | Centros iniciales `(x,y)` | Y que M5 impone al mover |
|---|---|---|---|
| índice 0, t=10; `wave_0_0…3` | `hydroides`, 4, `linea_vertical`, y=60, portadora roja | `(660,30)`, `(660,122)`, `(660,214)`, `(660,306)` | `32,32,32,32`: quedan superpuestos |
| índice 2, t=24; `wave_2_0…4` | `fabric`, 5, `v`, y=168 | `(724,123.2)`, `(692,145.6)`, `(660,168)`, `(692,190.4)`, `(724,212.8)` | `304,304,32,304,304`; pares comparten X/Y |
| índice 18, t=148; `wave_18_0…6` | `hydroides`, 7, `ambos_lados`, y=276 | `(660,30)`, `(660,306)`, `(692,30)`, `(692,306)`, `(724,30)`, `(724,306)`, `(756,30)` | todos `32`; tres pares comparten X/Y |
| índice 20, t=162; `wave_20_0…5` | `fabric`, 6, `linea_vertical`, y=110, portadora azul | `(660,30)`, `(660,85.2)`, `(660,140.4)`, `(660,195.6)`, `(660,250.8)`, `(660,306)` | `32,304,304,304,304,32`: dos grupos superpuestos |

Los decimales son los valores matemáticos de la función; la representación interna es flotante. La regla exacta que produce esa distribución es `e.pos.y = 304 if fmod(float(e.origin.y), 2) > 0 else 32`. No utiliza una superficie, la orientación del tubo ni el `y` de un soporte. X disminuye `scroll_px_s * local_dt`, con `local_dt` reducido si hay ralentización: incluso la supuesta adherencia al scroll puede desacoplarse si el enemigo se ralentiza y el fondo continúa a 60 px/s. En 04B el soporte debe mandar la transformación; ralentizar el ataque no puede desplazar el pie.

Existe además **un Hydroides escolta real**, fuera del presupuesto regular: al t=60 el código toma los dos primeros `world.unicos`, y crea `escort_0=hydroides` en `(660,70)` y `escort_1=euphrosine` en `(700,250)`. M5 lleva a `escort_0` a Y=32. El JSON del evento declara dos Euphrosine con vida/tamaño específicos, pero `step()` no lee ese objeto `escoltas`. Se registra esta discrepancia; **04A no la corrige ni altera conteos**. Proponer un anclaje para el Hydroides existente evita omitirlo; elegir en 04B entre conservar el comportamiento o respetar `event.escoltas` requiere una decisión explícita.

## Por qué el fondo dibujado no resuelve el hábitat

`w01_environment.gd` es composición PNG sin estado de simulación ni colisiones. Sus estructuras usan profundidad **0.3** y se cruzan por fundido cada 900 px de scroll (15 s), ciclando tres motivos; algas/cadenas usan 0.6 y rocas inferiores 1.0. Las rocas visibles se repiten con módulo 2398 px y las estructuras con módulo 2880 px. Son un decorado repetible, no tres subzonas navegables persistentes.

Ningún enemigo almacena `support_id`, punto local ni normal de superficie. Las estructuras a 0.3 se moverían a otra velocidad que M5; las rocas a 1.0 tampoco tienen un punto compartido con el tubo. Los peligros `boyas`/`cascos` son rectángulos temporales: `step_hazards()` comprueba si el **centro** de la nave está dentro y aplica daño, sin resolver penetración o impedir atravesarlos. El nombre `hazards.solid` no implica resolución de sólido. No existe todavía colisión contra estas columnas/cascos dibujados.

## Propuesta de mapa de anclajes para 04B

**Todo lo siguiente es conceptual y pendiente de aprobación. No se crea un archivo de datos cargable.** Coordenadas de mundo: origen `(0,0)` arriba a la izquierda, Y positiva hacia abajo, altura 336. Transformación única: `pantalla = mundo − (scroll,0)`, sin parallax para terreno jugable. Al nacer un grupo, `scroll≈60*t`; se conserva cada hora de evento y se redistribuyen sus miembros en X a 64 px para eliminar superposiciones. Esto cambia posiciones futuras, no el presupuesto. Los soportes deben existir antes de nacer sus habitantes y mientras sigan visibles.

Convención de normal: `(0,-1)` suelo/repisa, `(0,1)` techo, `(-1,0)` cara izquierda de pared. Los ID `a_*` siguientes son propuestas, distintos del UID de enemigo existente.

| Anclajes propuestos y habitantes | Punto(s) mundial(es) del pie | Soporte visible propuesto | Normal |
|---|---|---|---|
| `a_h10_0…3` → `wave_0_0…3` | `(1260+64*n,304)`, n=0…3 | `rock_01`: roca baja, tramo X=1220…1500, superficie Y=304 | `(0,-1)` |
| `a_f24_0…2` → `wave_2_0…2` | `(2100+64*n,54)`, n=0…2 | `hull_01`: casco suspendido conectado al techo, X=2060…2270, cara inferior Y=54 | `(0,1)` |
| `a_f24_3…4` → `wave_2_3…4` | `(2292+64*(n-3),290)`, n=3…4 | `column_01`: basa/repisa conectada al suelo, X=2260…2390, superficie Y=290 | `(0,-1)` |
| `a_escort60` → `escort_0` si se conserva el Hydroides actual | `(4260,292)` | `sediment_02`: roca de borde en entrada del pecio, X=4220…4300 | `(0,-1)` |
| `a_h148_0…3` → `wave_18_0…3` | `(9540+64*n,292)`, n=0…3 | `hull_03_floor`: cubierta baja del pecio, X=9500…9770, superficie Y=292 | `(0,-1)` |
| `a_h148_4…6` → `wave_18_4…6` | `(9796+64*(n-4),44)`, n=4…6 | `hull_03_roof`: viga superior unida al techo, X=9760…9960 | `(0,1)` |
| `a_f162_0…2` → `wave_20_0…2` | `(10380+64*n,300)`, n=0…2 | `arena_floor`: plataforma de entrada, X=10340…10550 | `(0,-1)` |
| `a_f162_3…5` → `wave_20_3…5` | `(10572,70+64*(n-3))`, n=3…5 | `arena_column`: columna derecha, X=10572…10610, unida arriba; cara izquierda | `(-1,0)` |

Este mapa representa **22 regulares y un escolta condicional**, sin nuevos individuos. En t=10/24/148/162 la primera X de cada grupo equivale a 660 en pantalla y el resto entra después por separación espacial. La columna propuesta de t=162 permanece a X de pantalla 372 cuando el scroll se detiene a 10200; por eso el diseño 04B debe despejar la arena antes de la alerta o situar este soporte fuera del volumen de combate. **No aprobar el mapa como ruta final mientras no se resuelva esta interferencia**; recolocar los anclajes/soportes finales es preferible a cortar el tubo o eliminar enemigos silenciosamente. Véase la puerta de cronología y arena en [siguientes bloques](siguientes-bloques.md).

### Pie, transformación y conducta propuestos

Los PNG existentes se conservan. Inspección de alfa: Hydroides tiene último píxel opaco en fila 45, con solape de base X=21…24 entre los cuatro cuadros; Fabriciidae, fila 46, con solape X=20…30. Candidatos técnicos a revisar: pivotes **Hydroides `(23,45)`**, **Fabriciidae `(25,46)`**, en lienzo 48×48. Se debe comprobar continuidad visual de tubo en cada cuadro; estos puntos no son metadata ya integrada ni pivotes aprobados. Usar el centro de rectángulo actual o su borde de 48 px deja margen transparente entre tubo y soporte.

En 04B: `pie_mundo = transformacion_soporte * anclaje_local`; cada vértice visible/hitbox/origen de disparo se obtiene desde ese mismo pie y orientación. El soporte con normal de techo rota el tubo hacia abajo y el de pared hacia agua abierta; no invertir solo el sprite dejando balas/hitboxes arriba. Añadir pruebas por cuadro, orientación, ralentización, pausa y reintento. La propuesta inicial usa sustrato **indestructible**; destruir soportes exigiría otra regla explícita para el organismo y persistencia de esa destrucción.

Conductas propuestas por actor de juego: Hydroides extiende/retrae corona y dispara desde la boca del tubo; Fabriciidae extiende filamentos y se refugia. Mantener el presupuesto F3 actual hasta que 04B defina ventanas de exposición; introducir invulnerabilidad oculta sería un cambio de dificultad que debe medirse. Los IDs errantes conservan navegación/ráfagas acordes a su ficha; no se convierten todos en habitantes de tubo. Los otros 16 IDs tubícolas y la torreta solo reciben inventario en 04A: su revisión por hábitat queda fuera de W01.

## Presupuesto y pendientes antes de programar 04B

- Mantener **90 regulares**: 36 antes del minijefe, 54 desde t=120; los escoltas/minijefe/jefe están aparte. Mantener IDs, drops de grupo y eventos. Los 22 tubícolas regulares forman parte de esos 90.
- Conservar t=60 minijefe, t=170 alerta y el contrato nominal **180 s hasta jefe** de `worlds.json`; la ejecución actual tiene una diferencia temporal detallada en el documento siguiente. Este diseño no la «corrige» por redacción.
- Decidir la discrepancia de escoltas, el despeje de arena, si se aceptan tubos orientados por rotación del PNG B1, y la regla de colisión/deslizamiento. La cartografía y los pivotes anteriores son propuestas de trabajo.
- Faltan assets de terreno jugable con silueta/cara de contacto aprobadas, variantes de esquina/techo/suelo/columna, compuerta animada y metadata de colisión/anclajes. Los PNG B1 de fondo pueden permanecer como decoración; no están certificados como tiles de terreno sólido. No se reemplazan ni degradan en este encargo.
- Aceptación de 04A y autorización separada de 04B siguen pendientes. Sonar 04A puede señalar peligros existentes; no acredita que estos anclajes físicos ya existan.
