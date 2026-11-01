# Auditoría B1 de los marcadores visibles

Base inspeccionada: `d31d3406f07868942bbd3f594bee78d0f12d63b7`, rama `pulido/w01-combate-vfx-b1`. Se abrieron las cuatro capturas originales con el visor y se cotejaron el manifiesto, los PNG decodificados, `scripts/generate-assets-v2.py::placeholder`, `src/core/main.gd::_draw_game/_draw_bullet/_draw_hud` y las emisiones de `src/core/game.gd`.

El motor ya avanza y dispara; esta auditoría no diagnostica una simulación detenida. Los rótulos son píxeles de los PNG provisionales: pulsar F3 no los elimina. El generador anterior rellenaba el rectángulo completo con el color del tipo y escribía el ID; balas menores de 16 px no llevaban letras, pero seguían siendo rectángulos macizos. La revisión artística conserva `estado/status=placeholder` y usa `art_stage=integrated-review` hasta aprobación explícita del usuario. Esto distingue estado de aprobación de contenido visual.

## Correspondencia con las capturas originales

Las coordenadas siguientes son aproximadas en el fotograma de 640×360. Un ítem de 16 px ilegible no permite identificar de forma honesta su variante exacta: la causa y el conjunto de rutas sí se pueden demostrar siguiendo el despacho del renderer.

| Captura / señal observable | Clave y ruta de origen | Causa comprobada | Recurso de sustitución B1 | Validación necesaria |
|---|---|---|---|---|
| [01](../../evidencias/w01-2026-11-01/01-objetos-repetidos.png), [02](../../evidencias/w01-2026-11-01/02-proyectiles-y-placeholders.png), [03](../../evidencias/w01-2026-11-01/03-minijefe-efectos.png), [04](../../evidencias/w01-2026-11-01/04-jefe-y-legibilidad.png): puntos/cuadrados amarillos a lo largo de trayectorias | `w01_bullet_shot_move`, `w01_bullet_enemy_move`; `assets/sprites/w01/w01_bullet_{shot,enemy}_move_01.png` | Ambos PNG son amarillo opaco. `_draw_bullet` los escala al `size` real del proyectil y usa el mismo reloj global. El fotograma aislado no identifica la procedencia de cada punto. | PNG aliado con punta/estela celeste; enemigo orgánico de otra silueta; atlas conserva las claves. | Contratos de alfa/paleta/siluetas y prueba real disparo aliado/enemigo. |
| 02: rectángulo naranja de aproximadamente 48×48 en (205,178), texto `W01_FX_...` | `w01_fx_explosion_burst`; `assets/fx/w01_fx_explosion_burst_01.png` | `_draw_game` dibuja todos los efectos en 48×48, aunque el PNG original de explosión mide 64×64. `game.gd` emite `kind=explosion` al morir un enemigo. El bloque se ajusta a ese render y al prefijo visible. | Explosión transparente de 8 cuadros con expansión/disipación; tamaño de dibujo adaptado al tipo de efecto sin cambiar daño. | Animación PNG distinta y captura de una baja con la misma ruta de juego. |
| 02: pequeños bloques grises con letras, p. ej. (122,160), (229,142), (309,169), (470,160); 03: otros cerca de (219,100), (243,198), (54,278) | `w01_ui_item_{coin,shot,missile,bomb,shield,score,life,magnet}_idle`; `assets/ui/w01_ui_item_<tipo>_idle_01.png` | `_draw_game` mapea rojo→shot, verde→missile, azul→bomb, amarillo→shield y weapon→su arma. Todos los PNG de 16×16 tenían el mismo fondo gris azulado y etiqueta diminuta. No se atribuye una variante ilegible a una posición concreta. | Ocho iconos propios animados, transparentes y distinguibles. | Recogida real/fixture etiquetado de cada tipo; contratos de forma, paleta y cuadros. |
| 02: bloques rojos que rodean al animal en la derecha (cerca de 530,30 y 565,270); 03: bloques amarillo/verde en formación a la derecha | `w01_fx_bubble_burst`; `assets/fx/w01_fx_bubble_burst_01.png` | La aureola de portadora no es parte del PNG del animal: `_draw_game` dibuja bubble alrededor de `enemy.pos`, a `size*1.2`, y multiplica su PNG naranja opaco por el tinte de `enemy.carrier`. Así aparece un cuadrado con el animal delante. | Aro de burbujas transparente de portadora; conservar el color de recompensa y el animal existente. | Captura de portadora con halo, animal y recompensa legibles; sin rellenar el interior. |
| 03: rótulo translúcido superior en torno a (435,46); banda grande cerca de (268,100), procedencia exacta pendiente | `w01_ui_hazard_idle`; `assets/ui/w01_ui_hazard_idle_01.png` | `_draw_game` estira el marcador 64×16 al `hazard.rect` real y lo tiñe con alfa 0.22/0.55. El rótulo también se estira. El evento `cascos` de 138 s y 64×48 encaja con el rótulo superior a 02:22. La banda central grande supera las dimensiones de los riesgos W01 presentes en este checkout; no se ha demostrado que el exportado de la grabación use exactamente estos recursos/datos. Su atribución completa requiere reproducción del payload original; no se declara resuelta solo por parecerse a este marcador. | PNG de peligro reconocible sin ID técnico; distinguir aviso/activo y objeto dañino/decoración. | Cotejo con rectángulo F3 y prueba sin F3; no esconder el riesgo. Rastrear la banda central en el payload original si reaparece. |
| 01–04: iconos microscópicos blancos/grises en franja inferior | `w01_ui_item_{shot,missile,bomb,coin}_idle`; rutas individuales de la tabla inferior. `w01_ui_panel_idle`, `assets/ui/w01_ui_panel_idle_01.png` | `_draw_hud` reutiliza los ítems provisionales a 12×12. `assets.panel` escala un PNG 640×360 al HUD de 640×24, comprimiendo su rótulo. | Iconos originales y panel limpio; franja de 24 px, equipos en paneles propios semitransparentes. | Capturas reales ×1/×2/×3, texto y estado legibles. |
| 01–04: pareja grande de boyas/cadenas repetida | `w01_bg_layer4_idle`; `assets/backgrounds/w01/w01_bg_layer4_idle_01.png` (junto a las otras tres capas) | Arte ya integrado, no bloque técnico. El mismo tile 1280×336 se desplaza y repite; no hay sectores ni fase individual en el render de base. | Módulos/sectores costeros, ruinas y aproximación; movimiento local de cadenas/algas, cuatro capas conservadas. | Video continuo ≥30 s, tres vistas diferenciables, bordes sin costura y cronología intacta. |
| 04: barra/nombre/fase Nereidae en parte superior | Texto bitmap y `_pixel` a través de PNG blanco `w01_ui_pixel_idle`, `assets/ui/w01_ui_pixel_idle_01.png` | Indicador funcional, no etiqueta placeholder. La barra se pinta dentro de x80–560, nombre desde y4; requiere contraste sobre agua y zona segura. | Marco/contraste y presentación de entrada, conservando nombre/fase/HP. | Fixture de jefe etiquetado y captura real sin cortes. |

Las cajas de contorno rojo/cian/amarillo y el texto `F3 HITBOX ...` son depuración de `main.gd`: ya están protegidos por `if hitboxes`. No se confunden con los bloques opacos descritos arriba. Las especies, Pisionidae gigante y las piezas de Nereidae ya tienen PNG transparentes: B1 conserva sus píxeles y su taxonomía.

## Inventario de rutas de sustitución

La siguiente lista completa la cobertura de todas las familias de disparo/FX/ítems W01 que puede seleccionar el render, incluso cuando una captura fija no muestra una instancia inequívoca. El sufijo `_01` representa el primer cuadro; los restantes conservan el mismo prefijo.

| Clave | Ruta PNG | Problema de base → sustitución prevista |
|---|---|---|
| `w01_bullet_shot_move` | `assets/sprites/w01/w01_bullet_shot_move_01.png` | Barra amarilla maciza → punta/estela aliada |
| `w01_bullet_enemy_move` | `assets/sprites/w01/w01_bullet_enemy_move_01.png` | Cuadrado amarillo → forma orgánica enemiga |
| `w01_bullet_missile_move` | `assets/sprites/w01/w01_bullet_missile_move_01.png` | Rectángulo amarillo → cuerpo mecánico/propulsor |
| `w01_bullet_laser_move` | `assets/sprites/w01/w01_bullet_laser_move_01.png` | Rectángulo amarillo → haz de nivel existente |
| `w01_bullet_homing_move` | `assets/sprites/w01/w01_bullet_homing_move_01.png` | Rectángulo amarillo → cápsula dirigida |
| `w01_bullet_bounce_move` | `assets/sprites/w01/w01_bullet_bounce_move_01.png` | Cuadrado amarillo → orbe rebotante |
| `w01_bullet_bomb_move` | `assets/sprites/w01/w01_bullet_bomb_move_01.png` | Cuadrado amarillo → icono de bomba; no inventa proyectil nuevo |
| `w01_fx_explosion_burst` | `assets/fx/w01_fx_explosion_burst_01.png` | Bloque naranja rotulado → explosión |
| `w01_fx_bomb_burst` | `assets/fx/w01_fx_bomb_burst_01.png` | Bloque naranja rotulado → onda de bomba |
| `w01_fx_hit_burst` | `assets/fx/w01_fx_hit_burst_01.png` | Bloque naranja rotulado → impacto |
| `w01_fx_bubble_burst` | `assets/fx/w01_fx_bubble_burst_01.png` | Bloque naranja teñido → burbujas/halo |
| `w01_fx_spark_burst` | `assets/fx/w01_fx_spark_burst_01.png` | Cuadrado naranja → chispa/aviso |
| `w01_fx_trail_burst` | `assets/fx/w01_fx_trail_burst_01.png` | Rectángulo naranja → propulsión/estela |
| `w01_fx_flash_burst` | `assets/fx/w01_fx_flash_burst_01.png` | Bloque naranja rotulado → destello |
| `w01_ui_item_coin_idle` | `assets/ui/w01_ui_item_coin_idle_01.png` | Etiqueta gris → moneda |
| `w01_ui_item_shot_idle` | `assets/ui/w01_ui_item_shot_idle_01.png` | Etiqueta gris → disparo |
| `w01_ui_item_missile_idle` | `assets/ui/w01_ui_item_missile_idle_01.png` | Etiqueta gris → misil |
| `w01_ui_item_bomb_idle` | `assets/ui/w01_ui_item_bomb_idle_01.png` | Etiqueta gris → bomba |
| `w01_ui_item_shield_idle` | `assets/ui/w01_ui_item_shield_idle_01.png` | Etiqueta gris → escudo |
| `w01_ui_item_score_idle` | `assets/ui/w01_ui_item_score_idle_01.png` | Etiqueta gris → puntuación |
| `w01_ui_item_life_idle` | `assets/ui/w01_ui_item_life_idle_01.png` | Etiqueta gris → vida |
| `w01_ui_item_magnet_idle` | `assets/ui/w01_ui_item_magnet_idle_01.png` | Etiqueta gris → imán |
| `w01_ui_hazard_idle` | `assets/ui/w01_ui_hazard_idle_01.png` | Etiqueta estirada → señal de peligro |
| `w01_ui_panel_idle` | `assets/ui/w01_ui_panel_idle_01.png` | Panel rotulado → panel limpio |
| `w01_ui_panel_selected_idle` | `assets/ui/w01_ui_panel_selected_idle_01.png` | Panel rotulado seleccionado → panel limpio |
| `w01_ui_hud_idle` | `assets/ui/w01_ui_hud_idle_01.png` | Recurso provisional no usado por HUD de base → material HUD integrado |

`main.gd` actualmente selecciona `laser` para haz, `missile` para misil y `homing/bounce` según las propiedades reales de bala enemiga. La bomba existente aplica daño instantáneo de área y emite una explosión con radio; el nombre de un PNG no prueba que esa ruta lo utilice. Hay que comprobar la integración de `bomb_burst` y la duración de la animación frente a la vida útil del efecto (las bajas duraban 0.5 s, pero 8 cuadros a 12 fps duran 0.667 s). El mismo problema afecta al `hit` de 0.2 s. No basta con añadir ocho cuadros al disco.

## Pruebas y límites de esta auditoría

`native-tests/test_b1_visual_contracts.py` incorpora seis pruebas. Comprueba hashes SHA-256 de los 40 archivos de datos, 41 recursos de audio, nueve scripts de simulación/datos/tienda/guardado/audio/armas/etapas/jefes y 84 PNG de criaturas W01 contra la base, sin necesitar git durante la ejecución. El fixture está en `native-tests/b1_preserved_sha256.json`. Comprueba alfa binaria, hasta 16 colores por familia de actor, huecos reales dentro de la silueta, metadatos de revisión, variación entre cuadros, diferencia de siluetas y hojas FX distintas. También comprueba los diez módulos ambientales nuevos: RGBA, alfa binaria, tamaño acotado y movimiento real en los seis animados; y prueba independientemente que todos los rectángulos del atlas W01 están dentro de 2048×2048 y no se solapan. No modifica los contratos existentes para que acepten marcadores.

La ejecución inicial aislada de las primeras cuatro pruebas sobre los PNG anteriores produjo **24 fallos esperados**: las 22 familias seguían siendo marcadores, las siluetas aliada/enemiga eran iguales y las hojas FX se reutilizaban; la prueba de preservación pasó. Registro: [contratos-antes.log](logs/contratos-antes.log). No se ejecutó una importación/suite completa mientras otros procesos escribían arte. Tras integrar los PNG y el atlas, la ejecución aislada de las seis pruebas pasó: **6 pruebas, OK, 0.266 s**. Registro: [contratos-despues.log](logs/contratos-despues.log). La selección inicial del fixture incluía accidentalmente las dos balas `bullet_enemy` por contener `_enemy_`; se corrigió el filtro por categoría antes de registrar este resultado. El fixture preserva 174 archivos (40 datos + 41 audio + 9 scripts + 84 PNG de criaturas), y permite reemplazar las balas enemigas autorizadas.

Las pruebas no hacen OCR: el rechazo del aviso del generador antiguo y de sus rectángulos no demuestra por sí solo que no exista ninguna letra técnica dibujada. Tampoco demuestran animación natural, lectura del HUD, alineación de hitboxes, calidad del fondo, visibilidad del punto débil, respuesta de mandos o rendimiento Windows. La aceptación B1 requiere inspección del ejecutable exportado, capturas ×1/×2/×3, video continuo ≥30 s, mediciones de frame time, los dos instaladores y hashes. Estas comprobaciones están pendientes al redactar la auditoría y deben consignarse con sus resultados reales en el informe de entrega. No se declara arte final aprobado ni aceptación de B1/B2–B4.

## Corrección adicional encontrada al grabar el EXE

El recurso portador inicial ya tenía centro transparente, pero un borde azul oscuro de8×8 se ampliaba a120% del tamaño del enemigo y, al multiplicarse por el tinte rojo/verde, parecía un mosaico opaco. Se rechazó la captura Windows intermedia y se preparó nuevamente desde el original imagegen: PNG32×32, perla neutra, centro/exterior con alfa0,10colores claros y12–15% de ocupación. Así el tinte del ítem se conserva sin panel oscuro. Fragmento, hashes y atlas se actualizaron; hubo una reconstrucción adicional de los dos instaladores. `native-tests/carrier_alpha_probe.py` verifica el caso que la prueba genérica de transparencia no detectaba.
