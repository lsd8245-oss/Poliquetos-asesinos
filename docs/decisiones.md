# Decisiones del rediseño v2

## Autoridad y alcance

La [especificación recibida](specs/poliquetos-asesinos-v2.md) reemplaza el PDF anterior para el rediseño. Las instrucciones directas del usuario siguen teniendo prioridad: dos ediciones HTML independientes, entrega sin ZIP y canciones pendientes. El usuario confirmó usar las propuestas de la sección 14 el 31 de octubre de 2026.

Esta entrega implementa la **fase 0**, como exige la sección 13. No representa un juego v2 terminado ni una mejora visual ya jugable. El documento original se conserva íntegro; sus ejemplos se incluyen en los esquemas como ejemplos, no como datos cargados por el juego actual.

## Motor, assets y distribución

- Conservar JavaScript y Canvas. Canvas será el compositor de PNG; no se usará para dibujar arte final. No se añade otro motor ni empaquetador.
- Desarrollo con datos, módulos y assets separados según la sección 15.3; la futura construcción de las ediciones deberá incorporarlos al HTML para mantener el funcionamiento offline. El motor actual continúa en el HTML canónico hasta la integración de las fases correspondientes.
- Las carpetas de assets están vacías a propósito. Los PNG provisionales, atlas, manifiesto y fuente bitmap pertenecen a la fase 1. El arte final se produce aparte según la sección 2; no llamar «final» a gráficos procedurales ni a rectángulos provisionales.
- Normal: progresión y economía habituales. Pruebas: acceso a todos los mundos/etapas, armas y skins; dinero ilimitado para comprar mejoras y equipo, que empiezan pendientes salvo el sonar inicial. La excepción de selección libre en Pruebas prevalece sobre la progresión lineal normal de la v2.
- No regenerar ni presentar como nuevas las ediciones HTML en la fase 0, porque su contenido no ha cambiado.

## Datos y contratos

- `data/legacy_inventory.json` es una fotografía reproducible del motor existente: 119 tipos, 14 mundos, roles y participantes de cada encuentro. Incluye también tipos que siguen definidos pero ya no aparecen en la campaña.
- Las estadísticas registradas son las bases de `TYPES`, **no** las estadísticas efectivas de cada aparición. `spawnEnemy` y sus envolturas aplican escalas de acto, sector, modo y jefe. El inventario conserva esa distinción y no usa estas cifras para balancear la v2.
- Los sprites actuales son atlas Canvas generados en ejecución. Se registra su clave y renderizador; no se inventan rutas PNG que no existen.
- JSON Schema 2020-12 en `data/schemas/`. `worlds`, `enemies`, `bosses`, `cosmetics` y `audio` serán listas de registros; `shop`, oleadas, escape, atlas y manifiesto serán objetos. Es una decisión técnica de implementación, ya que el anexo presenta registros individuales.
- Los esquemas establecen los formatos iniciales del anexo y se ampliarán en la fase propietaria de cada sistema. No sustituyen la verificación de DPS, economía, tiempos o rendimiento.
- El validador comprueba además marcos y animaciones del atlas, cantidad de precios por rango, correspondencia mundo/archivo de oleadas y referencias internas del inventario.
- Python/jsonschema se utiliza solo para validar durante el desarrollo; jugar seguirá requiriendo únicamente un navegador.

## Correspondencia con la nueva especificación

- Los 65 únicos orgánicos (cinco por mundo 1–13) y todos sus recurrentes coinciden con la tabla 4.2; se mantienen los identificadores históricos y los nombres científicos existentes. El inventario por mundo permite revisar la correspondencia sin cambiar taxonomía silenciosamente.
- Los jefes orgánicos de 4.1 están presentes, incluidos los tres de contaminación y los dos hadales. El jefe Phyllodocidae usa el tipo `phyll` y la clave visual `leafqueen`; Macellicephaloides jefe usa `polyn`/`hadalsovereign`. No confundir esos alias con enemigos ausentes.
- El legado tiene seis robots normales y un cuarteto mecánico seguido de epitoquia, científico y Eunice. La v2 propone **otros seis tipos robóticos** (R1–R6) y **tres** robots en el primer encuentro. Se conserva la realidad del legado en el inventario; el reemplazo se realizará en las fases 8–9, sin afirmar que ya coincide con contenido nuevo todavía inexistente.
- Los minijefes gigantes son contenido nuevo. No se añaden al inventario como si ya existieran; se prepararán sus datos y assets en las fases 1, 5 y 8.
- Mantener las grafías de jefes Nereidae, Capitelidae y Polinoidae que exige 4.1; los IDs nuevos pueden seguir la convención del anexo (`boss_w01_nereididae`, etc.).
- La vida de Nereidae será inicialmente **1.750** por la tabla 6.3; los **2.350** del ejemplo JSON de 15.1 ilustran un formato. Prevalece la tabla de balance. Se aplica el mismo criterio al resto de ejemplos.
- La suma de la tabla 3.4 da **5.400 s (90 min)** objetivo y **4.212 s (70 min 12 s)** con jefes al 40 %, antes de precisar entrada/derrota y transiciones. Debe medirse el tiempo real en la fase 10, no declarar cumplida la duración por esta suma.
- Escape: propuesta aceptada de 300 s, tres tramos y 90 enemigos (30 + 40 + 20). Los puntos de control cada 90 s no coinciden todos con las fronteras de los tramos; son dos cronologías distintas.

## Guardados y música pendientes

- La sección 8 pide JSON en un directorio de usuario. Un HTML abierto en el navegador no puede escribir libremente en ese directorio. Para la fase 7 se propone conservar guardado local versionado y añadir exportación/importación JSON de tres ranuras con copia recuperable. Es una adaptación técnica pendiente de implementación, no una función ya disponible.
- Preservar las partidas antiguas y separar el formato nuevo de ambos modos; no sobrescribir guardados del juego anterior con una campaña incompatible.
- La sección 11 queda documentada, pero las composiciones, canciones y muestras continúan excluidas por la indicación directa previa. No producir pistas silenciosas ni sustituir audio existente en esta fase. El contrato `audio.schema.json` no modifica el sonido del juego.


## Cambio solicitado el 1 de noviembre: Windows nativo

El usuario pidió expresamente rehacer el resto de las fases como juego normal de computadora, sin versión web, y confirmó Windows. Se cambia a Godot 4.6.3 porque ahora el destino es una aplicación nativa. Esto sustituye la restricción anterior de mantener HTML/JavaScript; se explicó antes de implementar. Se preserva el HTML como legado y las dos ediciones pasan a ser ejecutables/instaladores.

- Guardado real en user://, con tres ranuras y .bak, en lugar de la adaptación web propuesta anteriormente. Normal/Pruebas tienen subdirectorios independientes.
- Instaladores NSIS con juego nativo y PCK incorporado, sin navegador ni ZIP. Los ejecutables grandes de desarrollo quedan en build/; solo se entregan los instaladores comprimidos y sus hashes.
- Los efectos son sonidos originales de la nueva aplicación; no se han creado ni sustituido canciones. Audio de etapa/jefe y fundidos musicales se mantienen pendientes.
- Se conservan las cifras originales de HP en vida_base; vida contiene el ajuste medido. Se publican las hipótesis de presupuesto y los resultados. La existencia de replays remunerados y burbujas de 100 monedas significa que 17.900/21.480 son ingresos nominales del recorrido principal, no un techo absoluto de toda partida. No se inventa una prohibición de esos ingresos para forzar el porcentaje de compras.
- La medición automática no acredita una partida humana de 90/70 minutos ni todos los posibles presupuestos derivados de repetir mundos. Esos criterios quedan como validación pendiente, explícitamente.
- Se utiliza la misma simulación y balance en ambas ediciones; Pruebas solo cambia acceso, selección, cosméticos y dinero. No hay estadísticas ni invulnerabilidad automáticas.
- La interfaz del instalador es nativa de NSIS; el juego usa PNG y bitmap. Solo la visualización F3 dibuja rectángulos de depuración.

## Incorporación documental del 1 de noviembre: reglas para los siguientes encargos

Esta actualización incorpora literalmente los dos adjuntos del usuario: `AGENTS.md` y `docs/procedimientos-v2.md`. No inicia ninguna fase ni modifica el juego. La especificación completa `docs/specs/poliquetos-asesinos-v2.md` permanece sin cambios.

La instrucción directa de este encargo establece que la especificación v2 es la fuente principal ante contradicciones de diseño. Las siguientes conciliaciones son de lectura y planificación, no correcciones ya realizadas en código o arte:

| Tema | Diferencia encontrada | Aplicación para el próximo encargo |
|---|---|---|
| Plataforma y entregas | Los adjuntos exigen JavaScript/Canvas y dos HTML; las decisiones históricas posteriores al spec y la rama `juego-nativo-v2` registran Godot/Windows por solicitud anterior. | Se conservan las instrucciones HTML actuales y ambos productos existentes. Esta integración documental no autoriza convertir, eliminar ni sustituir la aplicación nativa. El encargo de implementación deberá identificar explícitamente su plataforma y rama base; no interpretar un historial de Godot como fase HTML aceptada. |
| Autoridad de diseño | AGENTS ordena autoridades según normas de entrega/diseño. | La instrucción directa actual resuelve cualquier duda: para mecánicas, cifras, familias, mundos y fases prevalece el spec completo; procedimientos no lo reemplaza. |
| Etiquetas de placeholders | Spec §2 exige nombre del asset sobre el placeholder; los adjuntos limitan IDs técnicos a F3 y piden nave limpia. | No cambiar el spec ni los PNG en esta entrega. En el próximo alcance se distinguirán etiquetas exigidas por el spec de overlays de depuración, exclusivamente F3, sin tapar controles. Si se propone eliminar también las etiquetas exigidas por el spec, será una excepción de diseño que debe aprobarse expresamente; no se afirma compatibilidad literal de estas frases. |
| Tamaño de Hydroides | Procedimientos ofrece un ejemplo 32×32; la implementación nativa actual usa un actor mediano 48×48. | El ejemplo no cambia automáticamente la categoría del enemigo ni su hitbox. Consultar §5.8.1 y dimensiones/datos del manifiesto antes del encargo de arte. El spec contempla pequeños 24–32 y medianos 48–64; mantener cualquier decisión justificada en datos. |
| Paletas | Procedimientos añade cuatro colores guía por mundo; spec §4.1 define la atmósfera y paletas narrativas. | Los colores guía son auxiliares. Ante contradicción, preservar la identidad visual del spec, especialmente superficie luminosa y mundos profundos oscuros. No recalcular ni recolorear assets en esta entrega. |
| Animaciones y daño | El ejemplo de arte menciona un cuadro de daño; spec §2 exige destello blanco de dos cuadros. | Prevalecen los dos cuadros del spec; el ejemplo no redefine esa regla. |
| Mínimo de contenido y prueba | Procedimientos resume fase2 como disparo y enemigo de prueba; spec exige ocho niveles de disparo. Añade guardado del checkpoint en fase4, mientras fase7 desarrolla el guardado persistente. | No reducir los ocho niveles; en fase4 verificar restauración del checkpoint y reservar la persistencia completa de tres ranuras para el alcance de fase7. |
| Orden y aceptación | Los adjuntos toman `rediseno-v2-fase-0` como referencia histórica; la rama actual contiene código hasta fase10. | El estado debe releerse por rama/commit. No tratar commits, pruebas históricas o una solicitud anterior de avanzar como aprobaciones visuales actuales. Una sola fase por próximo encargo y aprobación explícita antes de avanzar. |
| Música | El spec incluye canciones, voces, fundidos y marcadores silenciosos; los adjuntos y la indicación del usuario mantienen ese trabajo en pausa. | No sustituir, reprocesar ni crear música/muestras musicales. Conservar lo existente. La infraestructura de audio no autoriza reabrir las canciones. |
| Dependencias y comandos | Procedimientos menciona jsonschema como requisito actual, pero requirements-dev.txt también contiene Pillow. Los comandos HTML no prueban el motor Godot. | Consultar los requisitos reales. Ejecutar los comandos indicados para el legado y datos, sin presentarlos como validación nativa ni visual. Añadir pruebas específicas de la plataforma de la fase cuando se autorice implementarla. |

Se mantienen Normal/Pruebas, compras pendientes salvo sonar, dinero ilimitado solo en Pruebas, ausencia de mejoras/invulnerabilidad automáticas, guardados/preferencias separados y protección de partidas incompatibles. Conservar las notas históricas anteriores permite auditar el cambio de instrucciones; esta sección describe el alcance documental actual.

## Encargo 01 — conciliación nativa y piloto gráfico (posterior a f60abfb)

La nueva instrucción adjunta confirma Godot 4.6.3 y Windows como producto activo. Sustituye los mandatos HTML/Canvas de AGENTS/procedimientos únicamente en plataforma, entregas, guardados y pruebas. Se conserva el historial anterior para auditoría y la especificación completa byte a byte. El informe documental de f60abfb es histórico; su alternativa de implementar fase1 HTML no es el próximo alcance vigente.

Entrega final futura: `entregas/Poliquetos-Normal-Instalar.exe` y `entregas/Poliquetos-Pruebas-Instalar.exe`, con instalación/configuración/guardados independientes. El piloto actual solo concilia documentos y produce cuatro propuestas conceptuales en `docs/arte/piloto-w01/`; no reconstruye esos instaladores ni integra recursos. Los dos cambios se registran en commits separados.

Hydroides: `data/enemies.json` define mediano 48×48, y `src/stages/stages.gd` usa esas dimensiones; el PNG y el manifiesto actuales son 32×32, escalados al actor por el renderizador. El boceto se prepara a 48×48 para la presentación real, sin modificar ninguno de esos datos ni hitboxes. La discrepancia queda para una futura integración aprobada.

Herramienta autorizada disponible: imagegen, solo para conceptos originales; Pillow se limita a recorte, preparación de paleta, alfa, escalado nearest y hojas comparativas según autoriza el encargo. La reducción automática no acredita pixel art final. Se registrará procedencia y estado concepto/no aprobado, separado del manifiesto de producción. No se añaden mecánicas, mundo2, canciones ni efectos. No se acepta retrospectivamente ninguna fase. Se mantiene F3 para depuración sin cubrir el combate por instrucción expresa del piloto.

## Integración artística W01 autorizada tras el piloto

El usuario indicó «está bien», reiteró los cinco únicos, dos recurrentes, Pisionidae gigante y Nereidae del spec, y después «OK entonces prosigue». Se conserva la dirección artística del piloto y se integra como lote revisable en `arte/integracion-godot-w01`, desde `d6beb99`, sin cambiar mecánicas ni continuar al mundo2. La nave científica es la recomendación aplicada; el resto de variantes conceptuales queda conservado.

El estado `placeholder` del contrato se conserva para arte integrado en revisión; metadata PNG `art_stage=integrated-review` y `docs/arte/integracion-w01/procedencia.json` distinguen las ilustraciones de los rectángulos antiguos. No se marca el lote entero como final ni se declara completo el hito mundo1.

Decisiones técnicas: leer el ancho real de las capas1280 sin deformarlas a640; separar PNG cabeza/cuerpo/mandíbulas y frente/cola de Nereidae sobre la geometría existente; mantener los dos cuadros blancos y los pivotes. Reutilizar huecos de filas en el atlas para conservar el límite2048×2048, sin regenerar otros mundos. El runner nativo refresca importaciones porque la caché de Godot mostraba PNG antiguos; al comprobar píxeles importados se ignora solo RGB completamente transparente, que Godot modifica con fix_alpha_border.

La revisión independiente detectó poses errantes demasiado delgadas para los rectángulos de contacto existentes. Se regeneran curvadas y se añade una regresión de ocupación del encuadre; no se cambia tamaño, contacto, daño ni IA. La prueba de división utiliza las proporciones reales de los datos, además de capturas de Patterns.sync_parts.

El render por regiones transparentes conserva la captura de control píxel a píxel, pero la última medición de carga no llega a60FPS en llvmpipe; no se declara cumplido rendimiento. La verificación de clic sobre Salir encontró referencias de audio pendientes al cerrar: se detienen/liberan los reproductores y se espera su liberación antes de salir, sin cambiar archivos de audio. Ambas salidas se incorporan al runner nativo. El lote conserva límites artísticos explícitos (HUD/efectos/skins anteriores y acabado de las piezas cortadas en fase3), pendientes de aceptación.
