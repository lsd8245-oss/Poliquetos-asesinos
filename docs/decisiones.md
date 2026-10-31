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
