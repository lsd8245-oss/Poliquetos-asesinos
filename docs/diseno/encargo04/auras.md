# 04A: inventario y semántica de señales W01

Base auditada: `7dcad1c5a864305803d96aeddfeaeea8182c6a01`, rama `fix/w01-04a-pantalla-sonar-auras`. Alcance: presentación de estados existentes; sin modificar vida, daño, oleadas, botín, colisiones ni PNG B1. La documentación siguiente distingue la fuente anterior de la composición 04A.

## Evidencia del usuario y límites

Se inspeccionaron los JPG conservados en `docs/evidencias/encargo04/`. En `03_tubicola_sonar.jpg` hay dos organismos tubícolas con aros azules, el HUD indica CTD «NO INST.» y el reloj M1 marca 02:43. La oleada de Fabriciidae a 162 s es portadora azul y el render anterior aplica un aro azul a cualquier `enemy.carrier == "azul"`: hay concordancia temporal y visual con un marcador de botín, no una prueba de escudo ni CTD. Una imagen fija no permite demostrar duración, invulnerabilidad ni identidad interna de cada actor. En `02_enemigos_y_habitat.jpg`, a 00:52, el grupo del borde derecho no muestra esos aros; la oleada de Phyllodocidae de 52 s no es portadora. Los JPG no demuestran el funcionamiento del sonar.

Las imágenes del usuario son evidencia del problema anterior. No son capturas de esta corrección. Las capturas comparativas ejecutadas de 04A y sus limitaciones se registran en el informe de verificación de la entrega; este inventario por sí solo no certifica legibilidad sobre fondos claros/oscuros ni ejecución Windows.

## Inventario de fuentes, condición, duración y significado

| Origen y estado real | Condición y duración existente | Aspecto anterior | Composición 04A / significado |
| --- | --- | --- | --- |
| `stages.gd::spawn_wave`, `world_01.json`: grupo con botín | `carrier` no vacío en todos los miembros vivos de la oleada; desde aparición hasta morir o salir del escenario | `w01_fx_bubble_burst` de tamaño 120% del cuerpo, rojo/verde/azul, repitiéndose sin límite de tiempo propio | Icono PNG del arma a 10×10 px en la esquina superior derecha, con texto breve `TIRO`, `MISIL` o `BOMBA`. Estático, forma y color originales; texto acompaña con rojo/verde/azul. Es botín de grupo, no escudo. |
| `stages.gd::move_enemies`, Euphrosine M7 | `warning == true` después de 1 s de aproximación y durante 0,5 s de preparación; después acelera a 250 px/s | Chispa amarilla sobre todo el cuerpo | Chispa amarilla localizada de 20×20 px en la parte frontal; dura exactamente el estado de aviso. Se reserva el pulso intenso para la proximidad del ataque. |
| `patterns.gd::_charge`, minijefe Pisionidae y Nereidae fase 2 | `_charge.wait > 0`, normalmente 0,5 s de telegrafía; termina cuando acaba la espera | Peligro PNG rectangular con `delay`; no asigna `enemy.warning`, por lo que no tenía aviso local del actor | Chispa amarilla local mientras existe esa espera real. El peligro de trayectoria existente se conserva. Durante entrada o bloqueo de fase no se muestra un aviso de carga pendiente. |
| `bosses.gd::damage/update`, cambio de fase | `lock > 0`, 3 s de invulnerabilidad de fase, decrementado por simulación | Opacidad alterna 0,35/0,8 a 12 cambios/s | Sólo opacidad suave del propio sprite (0,60–0,76); sin otro aro. Con reducción de destellos, opacidad fija 0,72. No indica un blanco vulnerable. |
| `patterns.gd::_flags/sync_parts`, puntos débiles del minijefe/jefe | CTD instalado **y** `flags.weak_exposed == true`, con `flags.weak_points`; cada punto sigue posición real. Nereidae fase 3 tiene dos puntos según sus partes. No se muestran durante `lock`, `entry`, `hidden` o `flags.invisible` | Chispa cian de 12×12, mismo PNG que preparación de ataque; `weak_exposed` ausente se interpretaba como verdadero | Pequeño icono PNG del CTD (10×10), cian tenue, centrado en cada punto expuesto; cuadro estable, claramente distinto de chispa y botín. Campo ausente se interpreta como no expuesto. Sin CTD no hay marcador. |
| `game.gd::hit_enemy`, daño recibido por enemigo | `flash > 0`, 0,04 s; decae en `step_effects` | Sprite `_hit` cuando existe y no se reducen destellos; chispa de impacto adicional de presentación durante 0,18 s | Se conserva el impacto B1, que es un evento de daño, sin añadir un halo de estado. |
| `game.gd::damage_player`, nave golpeada | PNG de escudo durante 0,2 s; invulnerabilidad de 1 s tras daño o 2 s tras reaparición; `invulnerability` decae en simulación | `w01_fx_shield_burst`, parpadeo del sprite de nave; reducción de destellos baja alfa y elimina alternancia | Se conserva. Es protección temporal de la nave tras daño, no botín enemigo. |
| `weapons.gd::bomb`, explosiones y muerte | Bomba/explosión ordinaria 0,5 s; muerte de nave usa 1,2 s de explosión y 0,5 s de fundido | PNG de bomba/explosión; radio visual existente | Se conserva B1. Son eventos de combate, no estados permanentes del enemigo. |
| `weapons.gd::step`, Niskin comprado | Pulso cada 20 s; `kind == "pulse"`, 2 s y radio 140; ralentiza enemigos | `w01_fx_bubble_burst` alrededor de la nave durante ese evento | Se conserva la mecánica y arte del equipo comprado. No es sonar ni un adorno permanente; ya no se reutiliza este aro para botín enemigo. |
| `combat_presentation.gd::step`, recogida y disparo aliado | Recogida 0,3 s cuando suben créditos; fogonazo 0,08 s cuando se dispara | `w01_fx_collect_burst`, `w01_fx_muzzle_burst` | Se conserva B1. Son eventos transitorios alrededor de la nave, con alfa reducida cuando corresponde. |
| `stages.gd::spawn_hazard`, boyas/cascos y cargas | `hazard.delay > 0`: aviso con alfa 0,22; después peligro con alfa 0,55. W01 programa boyas a 25/130 s y cascos a 37/138 s durante 10 s, con aviso de 0,5 s | PNG `w01_ui_hazard_idle` sobre su rectángulo lógico | Se conserva. Señal de zona de peligro, no anclaje ni nueva geometría sólida de 04B. |
| `w01_environment.gd`, burbujas/plancton/caústicas | Decoración ambiental con opacidad baja; no lee estados del actor | PNG de fondo independientes de actores | Se conserva B1. No existen auras decorativas independientes que deban rodear permanentemente a una criatura; se retira la lectura ambigua del aro de botín. |

Código compartido presente pero **sin fuente activa en las siete especies regulares de W01**: M6 oculta el actor y da 0,5 s de aviso de emergencia en el fondo; el módulo mantiene exclusivamente ese aviso mientras está oculto. Flags de arena, nieve, invisibilidad de otros perfiles y armadura Polynoidae pertenecen a otros mundos y no se atribuyen a W01. Las siete especies W01 usan M5, M7, M5, M4, M4, M2 y M3, respectivamente. El blindaje configurado de Euphrosine no genera un aro ni es el origen de los aros azules de Fabriciidae.

### Botín de grupo: no prometer un objeto por criatura

`spawn_wave` copia el mismo `carrier` a todos los miembros de una oleada portadora. `game.gd::kill_enemy` entrega un solo objeto al alcanzar `wave_state.killed == wave_state.count`; un miembro que escape puede impedir completar la recompensa. El icono identifica pertenencia a ese grupo. No se modifica esta regla ni se añade botín por actor.

| Aparición | Grupo | Indicador y recompensa de grupo |
| --- | --- | --- |
| 10 s | 4 Hydroides | PNG disparo, `TIRO` (rojo) |
| 31 s | 5 Pisionidae | PNG misil, `MISIL` (verde) |
| 45 s | 7 Syllidae | PNG bomba, `BOMBA` (azul) |
| 127 s | 6 Pisionidae | PNG disparo, `TIRO` (rojo) |
| 141 s | 7 Euphrosine | PNG misil, `MISIL` (verde); su carga puede coexistir con el marcador |
| 162 s | 6 Fabriciidae | PNG bomba, `BOMBA` (azul) |

## Contrato del módulo e integración

`src/visuals/state_indicators.gd` extiende `RefCounted` y no conserva estado ni toca diccionarios de simulación.

- `describe(enemy, ctd, time, reduce_flashes=false) -> Array[Dictionary]`: devuelve `kind`, `key`, `rect`, `time`, `tint`; el botín añade `text`, `text_pos`, `text_tint`. Los únicos tipos son `loot`, `warning`, `weak`. El render usa sólo PNG existentes y glifos del PNG de la fuente bitmap. Las coordenadas de botín y su leyenda se limitan a 640×336.
- `draw(canvas, assets, descriptors)`: compone esos PNG y texto a través de `PoliAssets.sprite/text`, sin primitivas artísticas. Se dibuja después del cuerpo para no ocultar la pequeña insignia. En la rama de actor oculto se llama antes de omitir el cuerpo y únicamente se obtiene el aviso de emergencia.
- `actor_tint(enemy, time, reduce_flashes=false) -> Color`: aplica la opacidad existente, incluyendo invisibilidad, y atenúa suavemente el bloqueo de fase. No devuelve ni dibuja otro PNG de invulnerabilidad.

El reloj proporcionado debe ser el de simulación (`game.total_time`), que no avanza durante pausa/reanudación; no usar el reloj de animación de menús. No hay cuenta atrás visual independiente que pueda terminar antes/después del estado real. `warning` y `_charge.wait` se leen directamente. La variante reducida fija el cuadro de chispa y limita alfa a 0,35; el punto débil es estable y limita alfa a 0,65. El botín es estable en ambas variantes.

No se crean assets: los recursos reutilizados conservan su estado del manifiesto (actualmente `placeholder`, incluidos los iconos y efectos), sin presentarlos como nuevo arte final aprobado. Ningún PNG B1 se reescribe. El módulo no muestra IDs, hitboxes, HP ni campos internos; F3 conserva su vía de diagnóstico separada.

## Verificación acotada

`native-tests/state_indicators_test.gd` se incorpora automáticamente a `scripts/test-native.py` por el patrón `*test.gd`. Comprueba criatura normal sin decoración, tres formas de botín, esquinas/límites de pantalla, aviso M7 y espera de carga de jefe, fin de aviso, debilidad con/sin CTD y exposición explícita, bloqueo/entrada/invisibilidad, actor oculto, estados muertos/inactivos, PNG distintos por significado, reducción de destellos, composición bitmap y ausencia de escrituras a la simulación. Repetir con el mismo reloj da descriptores idénticos durante pausa.

Prueba directa ejecutada el 2026-11-02 con Godot 4.6.3 Linux headless:

```sh
XDG_DATA_HOME=/tmp/04a-aura-user XDG_CONFIG_HOME=/tmp/04a-aura-config \
XDG_CACHE_HOME=/tmp/04a-aura-cache godot --headless --path . \
  --script native-tests/state_indicators_test.gd
```

Resultado real: `STATE INDICATORS PASS: loot, warning, CTD weakness, lock, reduced flashes and read-only pause clock`, salida 0, sin errores de script. La ejecución inicial sin XDG escribible falló al crear el directorio de usuario restringido; la prueba se repitió correctamente con directorios temporales aislados. Esta comprobación valida contratos de presentación y existencia de PNG; la integración completa y capturas comparativas se verifican por separado en la entrega 04A.
