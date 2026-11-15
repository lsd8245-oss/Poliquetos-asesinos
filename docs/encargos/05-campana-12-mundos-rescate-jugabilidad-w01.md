# Encargo 05 — Campaña de 12 mundos y reparación jugable del mundo 1

**Proyecto:** Poliquetos Asesinos v2 · Godot 4.6.3 · Windows 10/11 x64 · dos instaladores Normal/Pruebas.  
**Estado:** INSTRUCCIONES PARA CODEX, **NO IMPLEMENTADAS**.  
**Rama base a comprobar:** `fix/w01-04a-pantalla-sonar-auras` (no adivinar el commit; comprobar HEAD y estado limpio).  
**Esfuerzo recomendado:** **MUY ALTO** para la migración y física/oleadas/IA, con entregas acotadas y pruebas; ALTO para retoques puramente visuales posteriores.  
**Documento complementario obligatorio:** `docs/planificacion/lista_12_mundos_propuesta.md` y `lista_12_mundos_propuesta.json` (adjuntos).  
**Autoridad:** instrucciones actuales del usuario > normas técnicas sin conflicto > catálogo v2 anterior. La reorganización a 12 mundos y la **desactivación temporal de minijefes** sustituyen las decisiones anteriores incompatibles. **Los jefes finales permanecen activos**. No cambiar otras mecánicas sin justificar y aprobar.

> **ACLARACIÓN CRÍTICA DEL USUARIO:** «Me refería a quitar los **mini bosses**, no el **final boss**». Cualquier instrucción anterior que dijera «desactivar jefes finales» queda anulada. Los jefes finales se mantienen.

## 0. Diagnóstico a partir del video y del código: no repetir errores

**Video entregado:** `prueba 1(5).mp4` (≈2:13, 1280×732), capturas de evidencia incluidas.

- La superficie y el fondo son visualmente atractivos, pero las columnas y arcos ocupan mayormente una **capa decorativa**, no corredores que condicionen de manera medible el recorrido de la nave. En la grabación la nave puede volar por extensas zonas libres.
- Los tubícolas aparecen separados de superficies físicas; en `src/stages/stages.gd`, el movimiento `M5` los desplaza en X por scroll pero fija Y en 32/304 según el valor de origen. **No existe vinculación garantizada a la roca/tubo/techo real**. Cambiar el sistema, no solo reposicionar sprites visualmente.
- `data/waves/world_01.json` prevé 90 individuos repartidos a lo largo de ~180 s, con intervalos largos sin nuevos encuentros. La grabación muestra pocos rivales simultáneos y grandes vacíos. El conteo debe distinguir **individuos totales**, **enemigos activos simultáneos**, **tiempo sin actividad** y **densidad por sector**.
- El antiguo minijefe Pisionidae ocupaba gran parte del plano derecho con patrones previsibles y excesiva resistencia. **La decisión vigente es retirarlo temporalmente**, no mejorar ese encuentro ahora. La dificultad debe concentrarse en la etapa, el terreno y el jefe final Nereidae.
- La revisión anterior 04A implementó un sonar inicial `Q` / mando `Y`, 12 s de recarga y 4 s de visualización, pero **el usuario no percibe una utilidad real**. El beneficio debe ser medible durante los tramos con peligros, no limitarse a círculos decorativos o textos.
- **CORRECCIÓN DEL USUARIO (prioridad máxima):** retirar temporalmente **los minijefes**, no los jefes finales. Mantener los jefes finales de los 12 mundos, incluyendo Nereidae al cierre del mundo 1 y los encuentros finales del laboratorio, excepto **Epitoka**, que sale del diseño activo del laboratorio por decisión independiente. Preservar código y recursos de los minijefes como contenido histórico/inactivo sin invocarlos en campaña.

**No declarar resuelto ningún punto basándose únicamente en pruebas headless.** Requerimos sesiones exportadas, capturas y mediciones.

## 1. Migración estructural a 12 mundos (bloque 05A)

### 1.1 Matriz de números

| Antiguo | Nuevo | Mundo | Acto |
|---:|---:|---|---:|
| 1 | 1 | Superficie marina | 1 |
| 2 | 2 | Playas arenosas | 1 |
| 3 | — | Costa rocosa (eliminado como etapa) | — |
| 4 | 3 | Bosques de kelp | 1 |
| 5 | 4 | Arrecifes tropicales | 2 |
| 6 | — | Praderas de pastos marinos (eliminado como etapa) | — |
| 7 | 5 | Estuarios y fango | 2 |
| 8 | 6 | Sedimentos contaminados | 2 |
| 9 | 7 | Zona planctónica | 3 |
| 10 | 8 | Zona antártica | 3 |
| 11 | 9 | Restos de ballena | 3 |
| 12 | 10 | Campos hidrotermales | 3 |
| 13 | 11 | Zona hadal | 3 |
| 14 | 12 | El laboratorio | 4 |
| 15 | 13 (especial, no mundo principal) | Escape final | Epílogo |

La campaña consta de **12 mundos principales**, cuatro actos y un escape especial (ID técnico 13). No contar el escape como mundo 13 visible. Los jefes/minijefes de las dos etapas retiradas quedan fuera de la campaña y archivados sin borrar assets.

### 1.2 Dos comunes y un recurrente adicional por mundo

Estos son **tipos de enemigos**, no cantidades de individuos. Respetar íntegramente los catálogos en `docs/planificacion/lista_12_mundos_propuesta.md` y su JSON.

| Nuevo mundo | Nuevos comunes (exactamente 2) | Nuevo recurrente (exactamente 1) |
|---:|---|---|
| 1 | Sabellaria; Eulalia | Spionidae |
| 2 | Pectinaria; Diopatra | Pisionidae |
| 3 | Dodecaceria; Sphaerodoridae | Hesionidae |
| 4 | Oenone; Chaetopterus | Serpulidae |
| 5 | Arabella; Hediste diversicolor | Magelona |
| 6 | Capitella capitata (complejo); Polydora ciliata | Spionidae |
| 7 | Vanadis antarctica; Pelagobia longicirrata | Swima |
| 8 | Laetmonice producta; Austrolaenilla antarctica | Aphroditidae |
| 9 | Glycera; Neanthes visicete | Sphaerodoridae |
| 10 | Branchipolynoe; Thermopolynoe | Ophryotrocha |
| 11 | Macellicephala tricornis; Bathykermadeca hadalis | Bathykurila |
| 12 | Robot Centinela Oenone; Robot Artillería Diopatra | Capitella capitata (complejo) |

- Mantener íntegramente los **enemigos ya existentes** de mundos supervivientes. Reubicar los comunes rescatados de los dos mundos eliminados según la lista adjunta; no confundir un enemigo añadido con uno completamente nuevo (algunos ya tienen assets en otra etapa).
- Los dos robots nuevos del laboratorio han de tener mecánicas propias y PNG originales, no ser recolores indistinguibles.
- Cuando una especie es tubícola, cavadora o bentónica, respetar su relación con el sustrato. Los recurrentes no deben aparecer en lugares físicamente incoherentes.
- No inventar que los sprites, audio y patrones de las 36 nuevas asignaciones **ya existen**. Registrar `placeholder` hasta tener arte aceptado. En fase 05A solo migrar datos y contratos; producir arte terminado mundo a mundo.

### 1.3 Migrar todas las dependencias de numeración

Actualizar referencias por ID semántico y un **mapa de migración explícito**, nunca con búsqueda/reemplazo global de `w03`, `w06` o `w14` que pueda pisar datos históricos:

- `data/worlds.json`, `data/enemies.json`, `data/bosses.json`, `data/waves/world_NN.json`, escape, esquemas de datos, desbloqueos, dificultad, economía, tienda, selector de Pruebas, eventos, UI, textos, estadísticas y música **sin alterar contenido sonoro**.
- Assets y atlas `assets/`, claves `wNN_*` e inventario; reusar PNG existentes mediante alias o manifiesto si conviene, sin sobreescribir fuentes antiguas.
- Guardados en `user://`: hacer copia recuperable y **migración versionada** de partidas existentes. Para una partida en el antiguo mundo eliminado 3 o 6, no avanzar en silencio a un mundo posterior: definir política de destino seguro, informar y probar. Mantener Normal/Pruebas aisladas.
- Rebalancear economía tras reducir la campaña de 14 a 12 etapas: moneda total obtenible, costos, probabilidades y desbloqueo por acto. No modificar precios a ciegas.
- Probar progreso Normal hasta mundo 12, selección Pruebas de 1–12 más escape y todas las transiciones, incluidas las ramas en las que el usuario guarda y sale.

**Criterio de aceptación 05A:** contrato de 12 mundos principales + escape especial; IDs sin colisiones; selector y guardados migrados; sin rutas antiguas activas en campaña; **minijefes inactivos** y **jefes finales activos** con transiciones y recompensas funcionales; dos EXE verificados.

## 2. Desactivar MINIJEFES y mantener JEFES FINALES (parte 05A)

**Pedido corregido y definitivo para este encargo:** los **minijefes intermedios** no deben aparecer por ahora. Los **jefes finales sí se conservan, aparecen, atacan y deben derrotarse** para completar cada mundo.

- Crear una configuración explícita `miniboss_enabled=false` (o equivalente) para los 12 mundos; **no configurar `final_boss_enabled=false`**. No eliminar definiciones, ilustraciones, ataques, música ni archivos de minijefes: quedan inactivos y recuperables.
- Suprimir la generación de eventos `minijefe` en la campaña activa y sus escoltas, recompensas y bloqueos dependientes. Mantener las oleadas regulares, peligros y controles de progreso. Si `mini_defeated` era un requisito para activar la alerta de jefe, reescribir esa condición para que no dependa de un encuentro deshabilitado.
- **Mundo 1:** suprimir el encuentro `mini_w01_pision` de los 60 s; la etapa debe continuar con actividad normal en ese tramo y entrar al **jefe final Nereidae** (`boss_w01_nereis`) alrededor de su punto de alerta configurado, tras las oleadas previas. No forzar `mini_defeated=true` como atajo que falsee estadísticas; definir un estado propio de minijefe deshabilitado.
- **Al derrotar al jefe final:** resultados → recompensa → descanso/tienda/guardado → siguiente mundo. La economía debe contabilizar la victoria del jefe; no conceder recompensas de minijefes que no se combatieron.
- **Laboratorio, nuevo mundo 12:** conservar los combates de jefes finales previstos y la progresión hasta el escape; **retirar Epitoka de forma independiente** de la rotación activa. No inventar su reemplazo todavía. Reconfigurar el orden sin huecos, índices inválidos ni bloqueos, y conservar en archivo histórico el código y el arte de Epitoka.
- **Mundos eliminados:** los jefes y minijefes de los antiguos mundos 3 y 6 quedan fuera de la campaña, archivados y sin borrarse del repositorio. No trasladar sus jefes a otros mundos sin aprobación.
- Corregir HUD, selector, resultados y mensajes para mostrar «jefe final» solo cuando corresponda; eliminar indicadores o alertas de un minijefe que no existe.
- Probar una ruta completa del mundo 1 con **cero minijefes** y **un jefe final real**, incluyendo batalla, derrota, recompensa, tienda, guardar/salir y continuar. Repetir contratos para los 12 mundos y escape.

**Puerta de aceptación 05A:** se comprueban `mini_spawn_count=0`, `boss_spawn_count>=1` en mundo 1 y transición exitosa solo después de derrotar al jefe Nereidae. Las simulaciones no deben saltar el combate contra jefe ni otorgar victorias automáticas. Los demás mundos conservan sus jefes originales, salvo la excepción explícita de Epitoka.

## 3. Mundo 1: terreno físico y movimiento obligado (bloque 05B)

Una capa dibujada **no cuenta como terreno**. Son imprescindibles estructuras físicas sincronizadas con el desplazamiento visual.

### 3.1 Segmentos de superficie marina (180 s antes de salida)

Proponer y probar tres sectores visuales/jugables; los tiempos son bandas de diseño, ajustar al ritmo final:

1. **00:00–00:55 · Aguas abiertas y ruinas costeras:** pilastras, arcos semiderruidos, rocas bajas, restos de casco sumergido. Primer corredor moderado, tutorial de obstáculos y tubícolas colocados sobre superficies reales.
2. **00:55–02:00 · Zona de estructuras:** pasajes alternando techo/suelo, vigas rotas, boyas encadenadas, obstáculos deslizantes o compuertas abiertas/cerradas con aviso previo; sustituir el antiguo encuentro de minijefe por una secuencia de oleadas, terreno y peligros graduales.
3. **02:00–03:00 · Aproximación al jefe:** corredores alternados, arrecifes rocosos bajos, burbujas o corrientes moderadas, oleadas densas, despeje de espacio para la alerta y **entrada del jefe final Nereidae**. Resultados únicamente tras vencerlo.

**Geometría:** separar fondo decorativo / plano medio decorativo / colisiones navegables / objetos interactivos; definir segmentos de terreno en coordenadas de mundo y transformarlos a pantalla mediante scroll. Colocar los sprites sobre sus polígonos o tilemap de colisión. Descartar obstáculos invisibles o hitboxes rectangulares que no corresponden a la silueta visible. Sin sustituir el pixel art por grandes rectángulos programáticos.

**Jugabilidad:**

- Al menos 3 pasos en los que seguir la línea horizontal por defecto termine chocando con el entorno; el jugador debe desplazarse en Y o rodear objetos. Al menos un paso con bifurcación temporal superior/inferior, ambas factibles.
- Corredores seguros para una nave de ~48×24 px. Para el primer mundo usar despejes de **≥72–88 px** en pasajes normales y telegráficos de **≥0,8 s** ante amenazas móviles; son **valores propuestos de partida** para el playtest, no un reemplazo no verificado del hitbox de 10×6.
- El scroll nunca empuja a la nave dentro de una pared sin posibilidad de escape. Evitar atrapamientos en esquinas, daño cada frame y bloqueos de ruta por dos amenazas simultáneas inevitables.
- Colisión física con pared/boya/casco: resolver deslizamiento o choque con retroceso controlado, feedback de impacto y daño/invulnerabilidad según reglas del juego. F3 permite ver geometría; sin F3 no mostrar hitboxes.
- Hacer que el entorno varíe realmente de posición, orientación y forma. Nada de repetir el mismo arco cada pocos segundos como simple patrón de fondo. Vegetación, filamentos y burbujas pueden animarse, pero **no reemplazan** la geometría jugable.
- Probar que tanto jugar arriba como abajo genera situaciones diferentes, sin camino completamente seguro donde el jugador pueda quedarse inmóvil todo el tiempo.

### 3.2 Poliquetos tubícolas: anclaje real

Afecta de inmediato a `hydroides` (Serpulidae) y `fabric` (Fabriciidae), más `sabellaria` en la nueva lista del mundo 1; después aplicar a todos los M5 pertinentes por hábitat.

- Cada individuo tiene `anchor_id`, `surface_id`, `anchor_local`, `orientation`, `tube_sprite` o equivalente; el soporte debe existir en la geometría/sustrato visible. Sin soporte válido, el spawner **no crea ese organismo**, registra causa y reintenta un anclaje admisible (no lo dibuja flotando).
- En el scroll, mover el soporte como objeto mundo y calcular posición del organismo relativa al soporte, no escribir `y=32`/`304` como si fuesen suelo y techo universales.
- El organismo permanece en su tubo; el penacho/corona/tentáculos se extienden/retraen y disparan desde una abertura concreta. No usar el sprite completo como nave que atraviesa el agua. Algunos tubícolas pueden crecer en soportes artificiales si se ve el tubo adherido.
- Los sprites de tubo y criatura deben tener colisiones ajustadas y animaciones coherentes. Si se destruye el soporte, declarar una consecuencia comprensible (destruir, desprender y morir, o conservar fragmento anclado), sin animales levitando.
- Auditoría de **100 % de los tubícolas** del mundo 1 en grabaciones y pruebas: cero sin soporte visual y físico en el momento de aparecer.

## 4. Mundo 1: densidad, variedad y ritmo (bloque 05C)

La propuesta antigua de 90 enemigos ya no satisface la experiencia deseada: **el usuario ha pedido expresamente más actividad**. No basta con agregar dos especies a la lista si casi nunca se ven.

- **Objetivo provisional del mundo 1: 150–170 individuos normales durante unos 180 s** (partir de 160), distribuidos entre los **7 comunes + 3 recurrentes** del nuevo catálogo. El número debe quedar en JSON y en un balance reproducible, no disperso en código. No duplicar indiscriminadamente las recompensas; ajustar economía/tiendas para que más enemigos no otorguen dinero excesivo.
- Durante periodos de oleadas, objetivo de **6–12 enemigos activos** y picos de **12–16 pequeños**, condicionado a tamaño, terreno y proyectiles. Estos son **objetivos de playtest**, no obligaciones de mantener 16 enemigos durante todo el nivel.
- Salvo apertura (primeros 10 s), pelea contra jefe final, pausas intencionadas de recuperación y transición, evitar vacíos de **más de 5–7 s** sin actividad o amenaza ambiental. Registrar los tramos vacíos durante la simulación completa.
- Intercalar ataques desde sedimento, enemigos errantes desde derecha/abajo, grupos recurrentes y tubícolas anclados. Algunos llegan en formaciones asimétricas; no usar 160 clones de la misma criatura.
- Analizar cuántos aparecen **realmente** dentro del campo: no contabilizar como jugados los enemigos despawn fuera de pantalla, en soportes imposibles, atrapados en colisiones o matados inmediatamente por un fallo de spawner.
- El nivel nunca debe depender de un enemigo ya desaparecido para habilitar la siguiente oleada; evitar congelaciones por referencias a un minijefe inactivo.
- Revisar rendimiento a 640×360 / 1280×720 / 1920×1080 con densidad y terreno. Reducir overdraw, no borrar enemigos para simular FPS estables.
- **No alterar todavía los conteos de mundos 2–12 por un multiplicador global.** Proponer objetivos de densidad por hábitat y validar cada mundo cuando llegue su turno.

**Criterio:** CSV/log con conteo programado, aparecido visible, eliminado, despawn, pico simultáneo, segundos de inactividad y caída de frames.

## 5. Jefe final Nereidae: combate más desafiante y menos tedioso (parte 05C)

**El minijefe Pisionidae permanece deshabilitado en este encargo. El jefe final Nereidae debe aparecer y combatir.** El problema descrito por el usuario es que las batallas permiten quedarse inmóvil y se alargan artificialmente por la vida excesiva.

- Mantener la identidad Nereidae, sus recursos y sus fases existentes. Auditar las fases actuales antes de introducir patrones y comprobar cuáles ofrecen una amenaza real.
- Diseñar y validar **tres comportamientos claramente distinguibles** durante el combate final, con avisos legibles y espacios esquivables:
  1. **Carga serpenteante:** avance en curva con preparación visual y rutas seguras que exijan desplazarse verticalmente.
  2. **Barrido segmentado:** una parte del cuerpo/tentáculos ocupa temporalmente un carril; cambiar el carril del ataque tras un telegráfico, nunca bloquear todas las rutas.
  3. **Ataques dirigidos y división:** patrones de proyectiles apuntados a la posición previa de la nave y transición a su fase de división si el jefe ya la implementa, sin balas imposibles de esquivar.
- Las fases deben cambiar la coreografía y no solo el número de proyectiles. Las hitboxes y los puntos débiles deben corresponder a lo que se ve.
- **Duración orientativa del jefe final en Normal:** aproximadamente **60–100 s de combate humano real** con armamento inicial razonable y puntería imperfecta; es un objetivo de prueba, no una obligación rígida. Medir DPS efectivo, porcentaje de aciertos y ventanas de exposición antes de ajustar la vida existente. No trasladar al jefe valores de HP previstos para el minijefe ni prolongar combate mediante invulnerabilidad excesiva.
- La dificultad debe provenir de tomar decisiones, esquivar y aprovechar aperturas; **no de multiplicar HP**. Mantener diferencias entre Fácil, Normal y Difícil, con señales y oportunidades reales de esquiva.
- Probar estrategia de nave inmóvil en posiciones alta, media y baja y compararla con un jugador móvil. Si permanecer estático permite superar sistemáticamente las fases, el patrón no cumple el objetivo.
- Durante el combate, el escenario debe ofrecer espacio suficiente para esquivar. No permitir que terreno móvil + jefe creen golpes inevitables.
- Al morir el jefe, ejecutar efectos, resultados, recompensa, tienda, guardado y tránsito al siguiente mundo. Nada de terminar el mundo solo porque se alcanzó una marca de tiempo.
- **Minijefes de todos los mundos:** quedan archivados e inactivos, sin cambio de HP, ataques, animaciones ni reintroducción durante 05C.

## 6. Sonar que aporte ventaja táctica (parte 05D)

**Estado actual comprobado en rama 04A:** `Q`/mando `Y`, recarga 12 s, visualización de unos 4 s, rango 320 px, sin daño. Estas cifras pueden preservarse salvo prueba que justifique ajuste.

El sonar debe **informar antes de la amenaza**, no limitarse a resaltar enemigos que ya vemos. Establecer efectos de inteligencia táctica (NO dañinos):

1. Identificar **cavadores/organismos ocultos** y marcar su ubicación y tiempo aproximado de emergencia con 2–3 s de antelación en el radio de alcance.
2. Revelar **colisiones y peligros del terreno que se aproximan**, al menos una sección por delante, mostrando brevemente los bordes navegables y un aviso de trayecto peligroso. No revelar toda la etapa ni automatizar el pilotaje.
3. Marcar boyas, compuertas y rocas móviles antes de que se crucen con la nave; aviso por posición y color/tipo, sin saturar la pantalla.
4. Si no hay amenazas próximas, mostrar **«Sin amenazas detectadas»** en vez de un pulso indistinguible de la nada. Sonido corto, animación de barrido y estado HUD «Q SONAR / 12–0 s» legibles.
5. Incluir al menos una zona del mundo 1 **diseñada para aprovechar el sonar**: un camino con peligro parcialmente oculto y opción real de anticiparlo mediante Q. Medir diferencia entre usar/no usar sonar en una prueba humana.

**No confundir sonar con CTD**, que conserva la función de mostrar datos y puntos débiles; no convertirlo en arma gratuita ni en radar infalible. Si el equipo es realmente poco útil tras el playtest, proponer una segunda mecánica activa, pero pedir aprobación antes de implementar funciones ofensivas.

## 7. Interfaz, accesibilidad, efectos y calidad de vida

- Preservar las dos opciones fullscreen de 04A (Rellenar / Píxel perfecto) y sus guardados. No reintroducir bordes negros en Rellenar ni estirar los píxeles con deformación no uniforme. Probar 16:9 y 16:10.
- La barra de progreso debe mostrar la **llegada al jefe final** y su aparición real. Quitar el marcador del minijefe temporalmente desactivado y asegurar que su ausencia no impida avanzar.
- Mantener HUD compacto pero legible y con iconos oceanográficos diferenciados; indicar los controles de sonar, bombas, armas y pausa en menú/ayuda.
- Respuesta clara de colisión con terreno; vibración/cámara discreta con opción de reducir efectos; distinguir al recibir daño de efectos ambientales. No perder la ubicación de la nave entre muchos proyectiles.
- Evitar elementos repetidos (arcos, columnas, medusas, algas clonadas) y halos permanentes sin función, especialmente con mayor densidad. Animar el entorno sin convertirlo en una distracción opaca.
- Audio actual intocable, salvo que se solicite expresamente. No alterar las pistas de los jefes finales, que permanecen activos.

## 8. Plan de ejecución y puertas de aceptación: una entrega por bloque

| Bloque | Qué se implementa | Evidencia imprescindible | Esfuerzo |
|---|---|---|---|
| **05A** | Migración 12 mundos + 2 comunes/1 recurrente por mundo en catálogos + minijefes temporalmente inactivos + jefes finales activos + transiciones/guardados | Diff, inventario, tests de IDs, selección/guardado y recorridos sin bloqueo | **MUY ALTO** |
| **05B** | Geometría navegable del mundo 1, corredores, boyas/cascos y tubícolas con anclaje | Video real con 3 desvíos obligados y 0 tubícolas flotantes | **MUY ALTO** |
| **05C** | 160 enemigos aprox. con mayor densidad, oleadas variadas y jefe final Nereidae mejorado (duración orientativa 60–100 s) | CSV de spawn/TTL/FPS, videos del jefe final con nave inmóvil y móvil | **MUY ALTO** |
| **05D** | Sonar táctico con peligros ocultos, ruta próxima, HUD y prueba A/B | Video que muestre utilidad práctica y telemetría de cooldown | **ALTO** |

**Regla de oro:** NO implementar todo de golpe ni pasar a mundo 2. El usuario solicita este plan global, pero cada bloque se integra por separado en una rama descendiente de la última aceptada. Primero **05A**, se prueban 2 instaladores y el flujo completo **sin minijefes pero con jefe final**, se espera revisión del usuario; luego 05B, 05C y 05D.

### Pruebas mínimas y criterios de rechazo

1. `python3 scripts/test-native.py` y suites Godot de contratos/motor/guardado; actualizar pruebas cuyo objetivo cambió de 14 mundos y 90 enemigos, sin borrar test por conveniencia.
2. Probar los dos **EXE Windows exportados**, preferiblemente en Windows real y, si no hay acceso, reportar claramente la limitación y usar Wine + PE/PCK desde directorio aislado. Verificar CRC NSIS, hashes y rutas del instalador; ejecutar no solo la escena del editor.
3. Video(s) de partida **sin cheats** mostrando niveles: 00:10, zona de estructuras sin minijefe, 02:00, entrada del jefe final y su derrota. Capturas de geometría con F3 y otras sin F3. Videos en Normal y Pruebas y captura del menú de selección 1–12.
4. Repetir prueba **inmóvil** en 3 posiciones, juego con esquiva y juego usando sonar. Si quedarse quieto supera sistemáticamente la etapa/jefe final, los patrones están rechazados.
5. Pruebas de colisión: ascenso/descenso, esquivar 3 obstáculos, contacto prolongado con pared, soporte de tubícolas, respawn, bombas y cambio de zona sin teleport.
6. Guardar/salir y reanudar en mundo 1 y desde progreso antiguo que apuntaba a un mundo 3/6 eliminado. Mantener backup, no sobrescribir silenciosamente.
7. Validar economía y resultados con jefes finales y sin minijefes: ingreso no duplicado, tienda accesible, mejoras aplicadas al siguiente mundo, créditos conservados y ninguna transición hacia un minijefe inactivo y ninguna omisión del jefe final activo.
8. Rendimiento con terreno+oleadas+FX. Medir FPS medios y p95, además de recuentos de enemigos activos. Si no logra 60 FPS estables en la máquina objetivo, informar y perfilar, nunca ocultar datos.

**Entregables por bloque:** `entregas/Poliquetos-Normal-Instalar.exe`, `entregas/Poliquetos-Pruebas-Instalar.exe`, SHA-256, informe verificable en `docs/verificacion/`, matriz cambios, videos/capturas, y `docs/v2-progreso.md` actualizado. No declarar arte final por haberlo importado. Solicitar aprobación antes de pasar a otro bloque.

## 9. Cosas que NO debes hacer

- No regresar a HTML, no reescribir el motor desde cero y no descartar todo el trabajo gráfico ya aprobado.
- No dejar a los tubícolas aparentemente anclados con una línea falsa mientras la física sigue moviéndolos libremente.
- No añadir únicamente rectángulos invisibles de daño; el terreno debe ser visible, transitable y bien explicado.
- No sustituir **variedad y dificultad** por enemigos de HP exagerado, proyectiles imposibles de esquivar o incremento descontrolado de spawn.
- No desactivar los jefes finales ni reintroducir minijefes en la campaña activa; no introducir el nuevo jefe del laboratorio sin diseño aprobado.
- No dejar el reloj detenido o la campaña bloqueada esperando un minijefe inexistente; tampoco saltar el combate final por accidente.
- No decir que el sonar «funciona» solo porque Q responde o hay una animación; se requiere una ventaja táctica observable.
- No cambiar simultáneamente los doce mundos sin revisar rendimiento, colisiones, arte, datos y guardados del primero.

## 10. Notas de diseño que requieren seguimiento

- El usuario ya planteó sustituir Epitoka por un futuro jefe mecánico (nave circular con tentáculos o nave gigante). **No fabricar ese jefe ni sus patrones ahora**; conservar ambas ideas para una etapa posterior.
- La eliminación de dos mundos y la retirada temporal de minijefes implican menos tiempo de campaña y menor economía total. Informar con números antes/después, no asumir que los precios previos siguen balanceados.
- La ficha biológica de los nuevos poliquetos es una **propuesta de gameplay**: verificar distribución, taxonomía y coherencia ecológica antes de generar descripciones científicas como si fueran hechos locales documentados.
