# Poliquetos Asesinos: especificación de rediseño completo (v2, fusionada)

Versión del 31 de octubre de 2026. Autor: Diego. Documento único que reemplaza al PDF anterior y a la especificación base. Contiene las secciones 1 a 4 del PDF (con los tiempos actualizados) y las secciones 5 a 15, que antes faltaban.

---

## 1. Resumen y alcance

Se rediseña por completo **Poliquetos Asesinos** como un shoot 'em up lateral de 16 bits, lineal, con una etapa larga por mundo y Darius Gaiden como referencia principal. Solo se conservan los poliquetos normales y los jefes poliquetos; todo lo demás se reemplaza según este documento.

**Duración total del juego (requisito):** **1 h 30 min** de juego efectivo en el recorrido objetivo, sin contar menús de descanso, tienda ni pantallas de muerte. Un jugador hábil con la mejor build lo termina en unos **1 h 10 min** (ver sección 3.4).

### Cómo usar este documento con Codex

1. Trabajar por fases, en el orden de la sección 13. No implementar todo de una vez.
2. Cada fase termina con sus criterios de aceptación cumplidos antes de pasar a la siguiente.
3. No cambiar el motor ni el stack actual del proyecto salvo que sea imprescindible; si lo es, explicar por qué antes de hacerlo.
4. Todo lo que este documento deja abierto está listado en la sección 14. Preguntar antes de inventar; si no hay respuesta, usar el valor por defecto indicado allí.
5. Todos los valores numéricos viven en archivos de datos (sección 15), nunca dentro del código.

### Qué se mantiene y qué se reemplaza

| Se mantiene | Se reemplaza |
|---|---|
| Poliquetos normales de cada mundo (sección 4) | Todo el arte dibujado en código: pasa a sprites de pixel art |
| Jefes poliquetos y los nombres de sus canciones (sección 6) | 10 niveles por mundo: pasa a 1 etapa por mundo |
| Orden de los actos y mundos, con el laboratorio como Acto 4 | Economía, tienda y mejoras |
| Nombre del juego: Poliquetos Asesinos | Zona de juego, HUD, menús, pantalla de muerte, portada |
| Música de los niveles normales (versión instrumental de la canción del jefe) | |

### Cambios de esta versión respecto al PDF anterior

| Tema | Antes | Ahora |
|---|---|---|
| Duración hasta el jefe, mundos 1 al 13 | 3:00 a 4:30 | 3:00 a 4:30 (sin cambios) |
| Duración hasta el jefe, laboratorio | 4:00 | 5:30 |
| Enemigos del laboratorio | 178 | 250 (para que la etapa del laboratorio sea más intensa) |
| Duración total del juego | no definida | 1 h 30 min objetivo y 1 h 10 min para un jugador hábil |
| Pelea de jefe | sin tiempo objetivo | tiempo objetivo por jefe (1:30 a 3:00) y regla de tiempo mínimo del 40 % |
| Tienda | no definida | 17 visitas, economía y precios completos (sección 7) |

---

## 2. Referencias de diseño y reglas de arte

El juego debe verse y jugarse como un shoot 'em up real de 16 bits, no como gráficos dibujados con código. La referencia principal es Darius Gaiden (arcade, 1994): nave pequeña contra criaturas marinas gigantes.

**Regla legal:** se copian mecánicas, estructura y estilo visual general. No se copian sprites, nombres, música ni diseños de esos juegos. Todo el contenido es original.

| Juego de referencia | Qué se toma |
|---|---|
| Darius Gaiden (principal) | Estilo de combate, jefes que son criaturas marinas enormes, armas que mejoran con ítems, escudo que se desgasta |
| Bio-Hazard Battle (Mega Drive) | Ambientación orgánica: carne, tentáculos, enemigos que parecen bichos vivos |
| Axelay (SNES) | Fondos en capas con sensación de profundidad, jefes formados por partes animadas |
| Thunder Force IV (Mega Drive) | Cada etapa con paleta y escenario muy distintos entre sí |
| Super R-Type (SNES) | Monstruos biomecánicos, para el Acto 4 (laboratorio) |
| Gradius III (SNES) | Jefes por partes y patrones de oleada |
| Fantasy Zone y Xenon 2 Megablast | Monedas que se recogen en la etapa y tienda entre fases |

### Reglas de arte (obligatorias)

1. **Prohibido** dibujar sprites, fondos o interfaz con primitivas de canvas, CSS o SVG generadas por código. Todo gráfico es un archivo PNG (spritesheet o atlas) cargado como asset.
2. **Resolución interna fija de 640×360 px**, escalada solo por múltiplos enteros (×2 = 1280×720, ×3 = 1920×1080). Suavizado de imagen desactivado (vecino más cercano). Sin blur. Si la ventana no es múltiplo entero, se centra la imagen con barras negras.
3. **Sprites:** contorno oscuro de 1 px, sombreado a mano de 3 a 5 tonos por color, máximo 16 colores por sprite, sin degradados lisos.
4. **Fondos:** 3 a 4 capas con scroll horizontal en parallax (velocidades relativas aproximadas 0,1 / 0,3 / 0,6 / 1,0), cada capa repetible sin costuras.
5. **Animación:** enemigos con 2 a 4 cuadros a 8 a 12 fps; explosiones de 6 a 8 cuadros; destello blanco de 2 cuadros al recibir daño.
6. **Tamaños orientativos:** nave del jugador 48×24 px; enemigos pequeños 24 a 32 px; medianos 48 a 64 px; minijefes 96 a 128 px; jefes 160 a 400 px (Eunice ocupa la mitad de la pantalla, sección 6).
7. **Efectos:** temblor de pantalla en explosiones grandes, partículas de pocos píxeles, burbujas, chispas. Pocos y con cuadros dibujados, no generados por funciones.
8. **Tipografía:** fuente bitmap de estilo pixel para todo el texto del juego. Debe incluir los caracteres `á é í ó ú ü ñ Á É Í Ó Ú Ñ ¿ ¡` además de ASCII.
9. **Organización de assets:** `assets/sprites/<mundo>/`, `assets/backgrounds/<mundo>/`, `assets/ui/`, `assets/fx/`. Nombres como `w01_enemy_serpulidae_move_01.png`. Un atlas JSON por mundo.
10. **Codex no es el generador del arte final.** Debe construir el motor para cargar los assets desde atlas y dejar marcadores de posición genéricos (formas planas con el nombre del asset) para que el juego funcione mientras el arte se produce aparte. Reemplazar un PNG por el arte final no debe requerir cambios de código.

### Reglas adicionales de assets (añadidas en v2)

- **Convención de nombres:** `w{NN}_{tipo}_{nombre}_{accion}_{NN}.png`, con `tipo` ∈ `enemy`, `mini`, `boss`, `bullet`, `bg`, `fx`, `ui`. Para el mundo 14, `w14`; para el nivel de escape, `w15`.
- **Atlas por mundo:** `assets/atlas/w01.json` más su PNG (`w01.png`). Formato en la sección 15.2.
- **Manifiesto de assets:** Codex genera `assets/assets_manifest.json` con la lista completa de assets que hay que producir por mundo (nombre, tamaño en px, número de cuadros, fps, estado `placeholder` o `final`). Es la lista de trabajo del artista.
- **Placeholders:** rectángulo plano del tamaño del asset, color distinto por tipo (enemigo rojo, jefe morado, bala amarilla, fondo gris) y el nombre del asset escrito encima con la fuente bitmap. Con una tecla de depuración (F3) se muestran las hitboxes.
- **Recurrentes entre mundos:** un enemigo recurrente comparte comportamiento entre mundos, pero cada mundo tiene su propio PNG (paleta y detalle propios). En los datos es un solo tipo con un `sprite_set` por mundo.
- **Capas de fondo:** cada capa es un PNG repetible de 640 px de ancho (o múltiplo) y 336 px de alto como mínimo.

---

## 3. Estructura del juego

El juego es lineal: **4 actos, 14 mundos, una etapa por mundo**, siempre en el mismo orden. No hay rutas, ramas ni selección de mundo (salvo volver a jugar uno ya superado, sección 8). Al terminar el mundo 14 viene el nivel de escape (sección 12) y el final.

### 3.1 Actos y mundos

| Acto | Mundos |
|---|---|
| Acto 1 | 1 Superficie marina · 2 Playas arenosas · 3 Costa rocosa · 4 Bosques de kelp |
| Acto 2 | 5 Arrecifes tropicales · 6 Praderas de pastos marinos · 7 Estuarios y fango · 8 Sedimentos contaminados |
| Acto 3 | 9 Zona planctónica · 10 Zona antártica · 11 Restos de ballena · 12 Campos hidrotermales · 13 Zona hadal |
| Acto 4 | 14 El laboratorio |

### 3.2 Estructura de cada etapa (mundos 1 al 13)

El escenario avanza con scroll horizontal automático a **velocidad constante de 60 px/s**. La nave se mueve libremente por toda la zona de juego. Sea `T` la duración hasta el jefe de la tabla 3.3 (incluye al minijefe). Línea de tiempo:

| Tramo | Cuándo | Contenido |
|---|---|---|
| 0. Aproximación | 0:00 a 0:10 | Solo escenario, sin enemigos. Aparece el nombre del mundo. |
| 1. Oleadas iniciales | 0:10 hasta `T/2 − 30 s` | El **40 %** de los enemigos de la etapa, en formaciones. |
| 2. Minijefe | `T/2 − 30 s` hasta `T/2 + 30 s` (ventana de 60 s) | Un poliqueto grande del mundo que no es el jefe final. Sin oleadas normales, solo 2 escoltas pequeñas. Al derrotarlo se activa un **punto de control**. |
| 3. Oleadas intensas | `T/2 + 30 s` hasta `T − 10 s` | El **60 %** restante, con mezcla de tipos y más presión. |
| 4. Alerta y jefe | `T − 10 s` en adelante | Aviso "ALERTA" de 6 s, entrada del jefe y **cambio a la canción con voz**. La pelea tiene fases (sección 6). |

Reglas:
- Si el minijefe sigue vivo al terminar su ventana de 60 s, no se retira: las oleadas intensas se reanudan igual (más presión) y el punto de control se activa cuando muera.
- La alerta del jefe **no empieza** hasta que el minijefe haya muerto y se haya alcanzado `T − 10 s`.
- Durante la pelea con el jefe el scroll se detiene (arena fija) salvo que el jefe indique lo contrario en sus datos.
- Los enemigos "de la etapa" no incluyen a los escoltas del minijefe, al minijefe ni a los jefes.

### 3.3 Enemigos y tiempos por mundo

Cantidad de enemigos por etapa: son la suma de los niveles de la versión anterior, para respetar que cada mundo tenga más poliquetos que el anterior. Codex reparte los enemigos en **oleadas de 4 a 12 enemigos** (los de enjambre, como Syllidae, pueden llegar a 20). El número de oleadas es orientativo (enemigos ÷ 8, redondeado hacia arriba).

| Mundo | Enemigos | Tramo 1 (40 %) | Tramo 3 (60 %) | Oleadas aprox. | Hasta el jefe (T) | Minijefe entra | Oleadas se reanudan | Alerta de jefe |
|---|---|---|---|---|---|---|---|---|
| 1 | 90 | 36 | 54 | 12 | 3:00 | 1:00 | 2:00 | 2:50 |
| 2 | 125 | 50 | 75 | 16 | 3:00 | 1:00 | 2:00 | 2:50 |
| 3 | 135 | 54 | 81 | 17 | 3:00 | 1:00 | 2:00 | 2:50 |
| 4 | 135 | 54 | 81 | 17 | 3:00 | 1:00 | 2:00 | 2:50 |
| 5 | 135 | 54 | 81 | 17 | 3:30 | 1:15 | 2:15 | 3:20 |
| 6 | 150 | 60 | 90 | 19 | 3:30 | 1:15 | 2:15 | 3:20 |
| 7 | 150 | 60 | 90 | 19 | 3:30 | 1:15 | 2:15 | 3:20 |
| 8 | 162 | 65 | 97 | 21 | 3:30 | 1:15 | 2:15 | 3:20 |
| 9 | 162 | 65 | 97 | 21 | 4:00 | 1:30 | 2:30 | 3:50 |
| 10 | 200 | 80 | 120 | 25 | 4:00 | 1:30 | 2:30 | 3:50 |
| 11 | 200 | 80 | 120 | 25 | 4:00 | 1:30 | 2:30 | 3:50 |
| 12 | 245 | 98 | 147 | 31 | 4:00 | 1:30 | 2:30 | 3:50 |
| 13 | 285 | 114 | 171 | 36 | 4:30 | 1:45 | 2:45 | 4:20 |
| 14 | 250 | 100 | 150 | 32 | 5:30 | 2:15 | 3:15 | 5:20 |

Los mundos 1 a 13 conservan las duraciones del PDF original; solo el laboratorio se alarga (de 4:00 a 5:30). Los **eventos de escenario** (peligros de la tabla 5.9) no cuentan como enemigos.

### 3.4 Duración total del juego

| Bloque | Hasta el jefe | Jefe (objetivo) | Total objetivo | Total mínimo (jugador hábil) |
|---|---|---|---|---|
| Mundo 1 | 3:00 | 1:30 | 4:30 | 3:36 |
| Mundo 2 | 3:00 | 1:30 | 4:30 | 3:36 |
| Mundo 3 | 3:00 | 1:30 | 4:30 | 3:36 |
| Mundo 4 | 3:00 | 1:45 | 4:45 | 3:42 |
| Mundo 5 | 3:30 | 1:45 | 5:15 | 4:12 |
| Mundo 6 | 3:30 | 1:45 | 5:15 | 4:12 |
| Mundo 7 | 3:30 | 2:00 | 5:30 | 4:18 |
| Mundo 8 | 3:30 | 2:15 | 5:45 | 4:24 |
| Mundo 9 | 4:00 | 2:00 | 6:00 | 4:48 |
| Mundo 10 | 4:00 | 2:00 | 6:00 | 4:48 |
| Mundo 11 | 4:00 | 2:00 | 6:00 | 4:48 |
| Mundo 12 | 4:00 | 2:00 | 6:00 | 4:48 |
| Mundo 13 | 4:30 | 2:30 | 7:00 | 5:30 |
| Mundo 14 (laboratorio, 4 jefes) | 5:30 | 8:30 (1:30 + 2:00 + 2:00 + 3:00) | 14:00 | 8:54 |
| Nivel de escape | 5:00 | | 5:00 | 5:00 |
| **Total** | | | **1 h 30 min** | **1 h 10 min** |

**Regla de tiempo mínimo:** el tiempo hasta el jefe es fijo (el scroll es automático), así que el jugador hábil solo ahorra tiempo en las peleas de jefe. La pelea de jefe no debe poder resolverse en menos del **40 % del tiempo objetivo** con la mejor build posible en ese mundo (por ejemplo, el jefe del mundo 1, con objetivo de 1:30, no debe morir antes de 0:36). Codex debe verificarlo en la fase 10 con una build máxima y, si un jefe muere antes, subir su vida (tabla 6.3). Además, cada cambio de fase de jefe tiene 3 s de invulnerabilidad con animación, de modo que ninguna fase se puede saltar.

### 3.5 Mundo 14: el laboratorio

Una etapa normal de **250 enemigos y 5:30** seguida de **cuatro jefes en cadena**: 4.1 robóticos, 4.2 epitoca, 4.3 científico, 4.4 Eunice aphroditois. Después de cada jefe hay **punto de control y pantalla de descanso** (con tienda y guardado). Al final, el nivel de escape (sección 12).

Composición de enemigos del laboratorio: 140 poliquetos robóticos (6 tipos únicos, definidos en 5.8.4) más 110 poliquetos aleatorios de los mundos anteriores como recurrentes, con paleta del laboratorio (grises metálicos y verde neón). Los aleatorios se eligen con una semilla fija por partida, para que los reinicios sean consistentes.

Línea de tiempo del laboratorio (4 sectores):

| Sector | Tiempo | Escenario | Enemigos |
|---|---|---|---|
| A. Esclusas y pasillos | 0:10 a 1:15 | Compuertas, tubos, luz clínica blanca | 45 |
| B. Salas de tanques | 1:15 a 2:10 | Tanques con criaturas, luz verde de pantallas | 55 |
| Minijefe: Sala de contención | 2:15 a 3:15 | Cámara circular con alarma | Minijefe |
| C. Servidores y pantallas | 3:15 a 4:15 | Pantallas, láseres, cintas transportadoras | 75 |
| D. Núcleo con alarma roja | 4:15 a 5:20 | Luz roja pulsante, compuertas que se cierran | 75 |

### 3.6 Muerte

Al morir, el jugador reaparece **en el mundo en que murió**, no al inicio del juego: en el último punto de control del mundo (inicio de la etapa, o después del minijefe), con lo comprado conservado y el arma al nivel con que entró al mundo. En el laboratorio, los puntos de control están después del minijefe y después de cada jefe. Detalles de la pantalla de muerte en la sección 9.

---

## 4. Mundos

Cada mundo debe verse claramente distinto de los demás. Antes los mundos eran casi iguales y todos "mares oscuros"; ahora cada uno tiene su propia paleta, su escenario y su atmósfera, con fondos en 3 o 4 capas (sección 2). Solo los mundos profundos (9, 12, 13) son oscuros.

### 4.1 Aspecto, minijefe y jefe de cada mundo

| Mundo | Paleta y escenario | Minijefe (versión gigante de) | Jefe final y canción |
|---|---|---|---|
| 1 Superficie marina | Celestes y turquesas brillantes, sol, olas, espuma, boyas y cascos de barcos | Pisionidae (Piso) | Nereidae. Nereida Vuelve a Desgarrar |
| 2 Playas arenosas | Amarillo arena y agua turquesa poco profunda, conchas, rocas pequeñas, sol alto | Arenicolidae (Arenicola) | Capitelidae. Capitélido del Arenal |
| 3 Costa rocosa | Grises azulados y verde musgo, acantilados, mareas, atardecer naranja | Oenonidae (Oenone) | Polinoidae. Polinoideo de Hierro |
| 4 Bosques de kelp | Verdes y ámbar dorado, rayos de luz verticales, frondas gigantes | Myxicola (Sabellidae) | Terebellidae. Reina de los Tentáculos |
| 5 Arrecifes tropicales | Magenta, naranja coral y azul zafiro muy saturados, corales y peces de fondo | Spirobranchus giganteus | Hermodice carunculata. Gusano de Fuego |
| 6 Praderas de pastos marinos | Verdes lima y esmeralda, luz filtrada, hojas largas que ondulan | Glyceridae (Glycera) | Phyllodocidae (gusano hoja). En proceso (sugerencia: Hoja entre las Hojas) |
| 7 Estuarios y fango | Marrones y verde oliva turbio, neblina ámbar, raíces de manglar | Trichobranchidae (Terebellides) | Orbiniidae. Orbiniidae, sal de ahí |
| 8 Sedimentos contaminados | Verdes tóxicos y morados, manchas de petróleo, barriles, basura, niebla química | Lumbrineridae (Lumbrineris) | Capitella capitata, Streblospio benedicti y Cirriformia tentaculata (tres jefes juntos). Zona muerta |
| 9 Zona planctónica | Azul profundo con partículas luminosas cian y verde, bioluminiscencia | Lopadorhynchidae | Tomopteridae. En proceso |
| 10 Zona antártica | Blancos y azules glaciares, icebergs, aurora, cielo despejado | Flabelligeridae (Flabegraviera) | Eulagisca gigantea. En proceso |
| 11 Restos de ballena | Grises óseos y rojos orgánicos, esqueleto gigante, luz tenue cálida | Chrysopetalidae | Osedax. Osedax |
| 12 Campos hidrotermales | Negro con rojos y naranjas incandescentes, chimeneas, magma, humo | Paralvinella | Alvinella pompejana. En proceso |
| 13 Zona hadal | Negro casi total con acentos violeta y cian tenue, poca información visual, presión y silencio | Aphroditidae (Aphrodita) | Macellicephaloides grandicirra y Riftia pachyptila. En proceso |
| 14 El laboratorio | Grises metálicos, blanco clínico, verde neón de pantallas, tubos y tanques, luz roja de alarma | Poliqueto robótico grande | Cuatro jefes (sección 6) |

Se respeta la escritura del juego (Nereidae, Capitelidae, Polinoidae). En nomenclatura científica serían Nereididae, Capitellidae y Polynoidae. Las columnas de minijefe y de paleta son propuestas; el usuario las puede cambiar.

### 4.2 Poliquetos de cada mundo

Esta lista es la que ya existe y no se modifica. Cada familia o género es un tipo de enemigo con su sprite propio. Un recurrente que aparece en varios mundos reutiliza el comportamiento y cambia de paleta y detalle según el mundo.

| Mundo | Únicos (5) | Recurrentes |
|---|---|---|
| 1 | Serpulidae (Hydroides), Euphrosinidae (Euphrosine), Fabriciidae, Pisionidae (Piso), Lacydoniidae | Syllidae, Phyllodocidae |
| 2 | Arenicolidae (Arenicola), Magelonidae (Magelona), Sigalionidae (Sthenelais), Saccocirridae (Saccocirrus), Goniadidae (Goniada) | Spionidae, Nephtyidae, Glyceridae |
| 3 | Dodecaceria (Cirratulidae), Oenonidae (Oenone), Arabellidae (Arabella), Sphaerodoridae, Histriobdellidae | Syllidae, Spionidae, Phyllodocidae, Serpulidae, Hesionidae |
| 4 | Spirorbis (Serpulidae), Myxicola (Sabellidae), Spintheridae, Trochochaetidae (Trochochaeta), Ctenodrilidae | Syllidae, Phyllodocidae, Cirratulidae |
| 5 | Spirobranchus giganteus (Serpulidae), Sabellastarte (Sabellidae), Eulepethidae, Acoetidae, Pholoidae (Pholoe) | Syllidae, Phyllodocidae, Hesionidae |
| 6 | Glyceridae (Glycera), Onuphidae (Diopatra), Chaetopteridae (Chaetopterus), Sabellariidae (Sabellaria), Pectinariidae (Pectinaria) | Syllidae, Nephtyidae, Hesionidae |
| 7 | Paraonidae (Aricidea), Trichobranchidae (Terebellides), Questidae (Questa), Fauveliopsidae, Protodrilidae (Protodrilus) | Spionidae, Nephtyidae, Glyceridae |
| 8 | Opheliidae (Ophelia), Cossuridae (Cossura), Pilargidae (Sigambra), Lumbrineridae (Lumbrineris), Oweniidae (Owenia) | Glyceridae, Dorvilleidae |
| 9 | Pontodoridae (Pontodora), Lopadorhynchidae, Typhloscolecidae, Poeobiidae (Poeobius), Iospilidae | Syllidae (como estolones nadadores), Alciopidae |
| 10 | Flabelligeridae (Flabegraviera), Aphelochaeta (Cirratulidae), Maldanidae, Sabellidae (Perkinsiana), Ampharetidae | Spionidae, Serpulidae, Alciopidae |
| 11 | Hesionidae (Hesiocaeca), Nautiliniellidae, Chrysopetalidae, Flabelligeridae (Brada), Bathykurila (Polynoidae) | Cirratulidae, Dorvilleidae (Ophryotrocha) |
| 12 | Riftia pachyptila, Paralvinella, Branchinotogluma (Polynoidae), Amphisamytha (Ampharetidae), Hesiolyra (Hesionidae) | Serpulidae, Cirratulidae, Dorvilleidae |
| 13 | Acrocirridae (Swima), Aphroditidae (Aphrodita), Scalibregmatidae, Sternaspidae (Sternaspis), Macellicephaloides (Polynoidae) | Nephtyidae, Glyceridae, Dorvilleidae, Alciopidae, Cirratulidae |
| 14 | 6 tipos distintos de poliquetos robóticos (definidos en 5.8.4) | Poliquetos aleatorios de los mundos anteriores |

**Distribución de los enemigos dentro de un mundo (regla por defecto):** los 5 únicos suman el 60 % de los enemigos del mundo (12 % cada uno) y los recurrentes se reparten el 40 % restante en partes iguales. Los únicos aparecen desde la primera oleada; los recurrentes, desde el 25 % de la etapa.

---

## 5. Combate: nave, armas, escudo, ítems y enemigos

### 5.1 Zona de juego

- Resolución 640×360. Zona de juego **640×336**; la barra de HUD ocupa los 24 px inferiores (sección 10).
- La nave no puede salir de la zona de juego. El scroll no la empuja.

### 5.2 Nave del jugador

| Parámetro | Valor |
|---|---|
| Sprite | 48×24 px (placeholder: rectángulo con nombre) |
| Hitbox | 10×6 px centrada (se muestra con F3) |
| Movimiento | 8 direcciones, sin inercia |
| Velocidad base | 160 px/s (+8 % por rango de la mejora Velocidad) |
| Invulnerabilidad tras daño | 1,0 s con parpadeo |
| Invulnerabilidad al reaparecer | 2,0 s |

### 5.3 Disparo principal (mantener botón)

Nivel 1 a 8, dentro de la partida. DPS base de cada nivel, sin mejoras permanentes:

| Nivel | Forma | DPS base |
|---|---|---|
| 1 | 1 proyectil recto | 10 |
| 2 | 2 proyectiles paralelos | 13 |
| 3 | 3 proyectiles (recto y 2 en diagonal leve) | 16 |
| 4 | 3 proyectiles, mayor cadencia | 20 |
| 5 | 4 proyectiles en abanico, perfora 1 enemigo | 24 |
| 6 | 4 proyectiles, perfora 2 | 29 |
| 7 | 5 proyectiles en abanico, perfora 2 | 34 |
| 8 | 5 proyectiles + rayo central grueso, perfora 3 | 40 |

### 5.4 Misiles (automáticos)

| Nivel | Forma | DPS base |
|---|---|---|
| 1 | 1 torpedo que cae en arco hasta el fondo y avanza pegado al suelo | 4 |
| 2 | Igual, más rápido | 6 |
| 3 | 2 torpedos (hacia arriba y hacia abajo) | 8 |
| 4 | 2 torpedos con explosión de área pequeña | 10 |
| 5 | 2 torpedos teledirigidos | 12 |
| 6 | 3 torpedos teledirigidos | 14 |
| 7 | 3 torpedos teledirigidos con área | 17 |
| 8 | 4 torpedos teledirigidos con área | 20 |

### 5.5 Bombas (botón X)

- Máximo 2 bombas al inicio, +1 por rango de la mejora Bombas (máximo 5). Enfriamiento de 1,5 s entre bombas.
- Cada bomba limpia las balas enemigas dentro de su radio y daña a los enemigos.
- Contra jefes y minijefes el daño de bomba se multiplica por 0,5.

| Nivel | Radio | Daño | Nivel | Radio | Daño |
|---|---|---|---|---|---|
| 1 | 80 px | 50 | 5 | 200 px | 230 |
| 2 | 100 px | 80 | 6 | 240 px | 300 |
| 3 | 120 px | 120 | 7 | 280 px | 380 |
| 4 | 160 px | 170 | 8 | Pantalla completa | 500 |

### 5.6 Ítems (burbujas)

| Ítem | Color | Efecto |
|---|---|---|
| Disparo | Roja | Sube el disparo principal un nivel |
| Misil | Verde | Sube los misiles un nivel |
| Bomba | Azul | Sube las bombas un nivel y repone 1 bomba |
| Escudo | Amarilla | Repone el 25 % del escudo máximo |
| Moneda chica | Dorada | Vale 5 monedas |
| Moneda grande | Dorada grande | Vale 25 monedas |

Reglas de aparición:
- **Oleadas portadoras:** en cada mundo hay 6 oleadas portadoras (enemigos con brillo de color). Si se destruye toda la oleada, suelta su burbuja. Reparto: 2 rojas, 2 verdes, 2 azules.
- **Escudo:** 3 burbujas amarillas por mundo, repartidas en los tramos 1, 3 y justo antes de la alerta del jefe.
- **Jefes:** el jefe final no suelta burbujas de arma; el minijefe suelta 1 burbuja del tipo que más falte.
- Si el arma ya está en nivel 8, la burbuja correspondiente se convierte en 100 monedas.
- Las burbujas que salen de la pantalla se pierden. Flotan hacia la izquierda a 30 px/s.
- Los niveles de arma **se conservan entre mundos**. Al morir se vuelve al nivel con el que se entró al mundo (sección 9).

### 5.7 Escudo (en vez de barra de vida)

- Escudo base 100, +20 por rango de la mejora Escudo máximo (hasta 200).
- La vida no se regenera salvo con la mejora Regeneración (tras 5 s sin recibir daño: +1, +2 o +3 por segundo según el rango) o con la burbuja amarilla.
- Daño que recibe el jugador (valores por mundo `n`):

| Fuente | Fórmula | Mundo 1 | Mundo 13 |
|---|---|---|---|
| Bala enemiga | 10 + 0,5 × (n − 1), redondeado hacia abajo | 10 | 16 |
| Contacto con enemigo | 20 + (n − 1) | 20 | 32 |
| Contacto con jefe | 30 + 2 × (n − 1) | 30 | 54 |
| Peligro de escenario | 20 | 20 | 20 |

- Al llegar a 0: explosión de 1,2 s y pantalla de muerte (sección 9).

### 5.8 Enemigos

#### 5.8.1 Vida y tamaño

Con `DPSref(n) = 30 + 6 × (n − 1)` (daño por segundo esperado del jugador en el mundo `n`):

| Categoría | Tamaño | Vida |
|---|---|---|
| Enjambre | 24 px | `ceil(DPSref ÷ 20)` |
| Pequeño | 24 a 32 px | `ceil(DPSref ÷ 10)` |
| Mediano | 48 a 64 px | `3 × ceil(DPSref ÷ 10)` |
| Escoltas de minijefe | 32 a 48 px | `2 × ceil(DPSref ÷ 10)` |

Ejemplo: mundo 1 → pequeño 3, mediano 9. Mundo 13 → pequeño 11, mediano 33.

#### 5.8.2 Balas enemigas

- Tamaño 6×6 px, siempre en colores muy brillantes (amarillo, rosa, cian) aunque el fondo sea oscuro (mundos 9, 12 y 13).
- Velocidad: `90 × (1 + 0,04 × (n − 1))` px/s (mundo 13 ≈ 133 px/s).
- Máximo 200 balas enemigas simultáneas en pantalla (reciclar con pool de objetos).

#### 5.8.3 Patrones y reglas por tipo corporal

**Patrones de movimiento** (se asignan en `enemies.json`):

| Código | Patrón |
|---|---|
| M1 | Recto de derecha a izquierda |
| M2 | Sinusoidal (amplitud 40 px) |
| M3 | Persecución lenta hacia la altura del jugador |
| M4 | Entrada desde arriba o abajo y luego recto |
| M5 | Anclado al fondo, techo o pared (se mueve con el scroll) |
| M6 | Emerge del suelo con aviso de 0,5 s y se queda 3 s |
| M7 | Embestida: se detiene, tiembla 0,5 s y carga en línea recta |
| M8 | Órbita en círculo alrededor de un punto |

**Patrones de disparo:**

| Código | Patrón |
|---|---|
| F0 | No dispara |
| F1 | Bala recta cada 2 s |
| F2 | Bala apuntada al jugador cada 2,5 s |
| F3 | Abanico de 3 balas cada 3 s |
| F4 | Anillo de 8 balas cada 4 s |
| F5 | Ráfaga de 3 balas apuntadas |

**Asignación por defecto según el tipo corporal** (Codex la usa para rellenar `enemies.json` y marca cada asignación como `revisar`):

| Tipo | Familias | Movimiento | Disparo | Notas |
|---|---|---|---|---|
| Errantes | Nereididae, Phyllodocidae, Nephtyidae, Glyceridae, Goniadidae, Hesionidae, Lumbrineridae, Oenonidae, Arabellidae, Dorvilleidae, Pilargidae | M2, M3 | F2 | Ondulan al avanzar |
| Enjambre | Syllidae, Spionidae, Cirratulidae (filamentos), Ctenodrilidae, Protodrilidae | M1, M2 | F0, F1 | Oleadas de 12 a 20 |
| Tubícolas y sedentarios | Serpulidae, Sabellidae, Fabriciidae, Terebellidae, Trichobranchidae, Chaetopteridae, Sabellariidae, Pectinariidae, Onuphidae, Oweniidae, Ampharetidae, Riftia, Paralvinella | M5 | F3, F4 | Fijos al escenario, los arrastra el scroll |
| Cavadores | Arenicolidae, Capitellidae, Opheliidae, Orbiniidae, Cossuridae, Maldanidae, Scalibregmatidae, Sternaspidae, Paraonidae, Magelonidae | M6 | F1, F5 | Salen del suelo con aviso |
| Pelágicos | Alciopidae, Tomopteridae, Lopadorhynchidae, Typhloscolecidae, Poeobiidae, Pontodoridae, Iospilidae, Acrocirridae | M2, M8 | F4 | Lentos, en grupos |
| Escamosos | Polynoidae, Aphroditidae, Sigalionidae, Acoetidae, Eulepethidae, Pholoidae, Chrysopetalidae, Euphrosinidae | M7, M1 | F0, F2 | Absorben el primer golpe de cada oleada (+50 % de vida) |
| Resto de familias | El resto de la lista 4.2 | M1, M4 | F1 | Ajustar tras el primer playtest |

#### 5.8.4 Los 6 poliquetos robóticos del laboratorio (propuesta, ver sección 14)

| Código | Nombre | Tamaño | Movimiento | Disparo | Comportamiento |
|---|---|---|---|---|---|
| R1 | Cablelarva | 24 px | M2 | F0 | Enjambre de 12 a 16 que embiste en cadena |
| R2 | Nereis Mk1 | 48 px | M3 | F2 | Segmentado, serpentea hacia el jugador |
| R3 | Torreta Sabélida | 48 px | M5 | F3 | Fijo en pared o techo, penacho que dispara en abanico |
| R4 | Taladro Arenicola | 56 px | M7 | F0 | Embiste en línea recta tras telegrafiar |
| R5 | Pinza Glicera | 48 px | M3 | F5 | Se acerca, abre mandíbula y dispara ráfaga |
| R6 | Escudo Afrodita | 64 px | M1 | F4 | Blindado, solo recibe daño por la parte trasera o al abrir su carcasa 1 s |

#### 5.8.5 Formaciones de oleada

Línea vertical, línea horizontal, V, V invertida, zigzag, círculo, doble columna, desde ambos lados (arriba y abajo a la vez), diagonal. Cada oleada del archivo de datos indica la formación, la separación entre enemigos (por defecto 32 px o 0,3 s) y la altura de entrada.

### 5.9 Peligros de escenario por mundo

Peligros que dañan 20 al contacto (salvo indicación). No cuentan como enemigos.

| Mundo | Peligro |
|---|---|
| 1 | Boyas y cascos de barco: obstáculos sólidos que cruzan la pantalla |
| 2 | Conchas y rocas pequeñas: sólidos en el suelo |
| 3 | Corriente de marea: empuja la nave ±30 px/s en vertical durante tramos de 10 s |
| 4 | Frondas de kelp: ralentizan la nave un 30 % mientras la tocan, sin dañar |
| 5 | Corales afilados: sólidos en suelo y techo |
| 6 | Corriente de hojas: empuje horizontal suave de 20 px/s hacia atrás |
| 7 | Raíces de manglar: sólidos que cuelgan del techo |
| 8 | Barriles explosivos (dañan en área a enemigos y jugador si se disparan) y manchas de petróleo (ralentizan un 25 %) |
| 9 | Medusas pasivas que se desplazan despacio |
| 10 | Icebergs sólidos y granizo (lluvia de bolas pequeñas, 10 de daño) |
| 11 | Costillas óseas: sólidos que sobresalen del suelo |
| 12 | Géiseres de las chimeneas (aviso de 1 s en el suelo) y lava en el fondo |
| 13 | Sin peligros extra; la dificultad viene de la visibilidad. Todo lo que daña tiene borde brillante |
| 14 | Láseres con ciclo de 3 s, compuertas que se cierran, cintas transportadoras que empujan, torretas de pared |

---

## 6. Jefes y minijefes

### 6.1 Reglas generales

- **Jefes finales:** 3 fases por defecto (cambian al 66 % y al 33 % de vida). Cada fase añade o cambia patrones. Entre fases: 3 s de invulnerabilidad con animación y las balas en pantalla se convierten en monedas pequeñas.
- **Partes:** cada jefe se compone de segmentos con hitbox propia. Hay **puntos débiles** (marcados con parpadeo tenue) que reciben ×2 de daño; el resto del cuerpo recibe ×0,5.
- **Telegrafiado:** todo ataque fuerte se anuncia con una animación de 0,5 s antes de ejecutarse.
- **Entrada:** animación de 3 s, aparece el nombre del jefe y suena la canción con voz. Música: sección 11.
- **Derrota:** explosión por segmentos durante 3 s, las balas se limpian, aparece la recompensa de monedas y suena el jingle de victoria.
- **Vida:** tabla 6.3. La mejora CTD muestra la barra de vida y los puntos débiles (sección 7.4).
- **Minijefes:** 2 fases (al 50 % de vida). Versión gigante de un poliqueto **único** del mundo (tabla 4.1), de 96 a 128 px. Usan los patrones del enemigo original, ampliados, más una embestida telegrafiada. Vida en la tabla 6.3.

### 6.2 Patrones de cada jefe (propuesta de diseño, ajustar con el artista)

| Mundo | Jefe | Tamaño aprox. | Fase 1 | Fase 2 | Fase 3 |
|---|---|---|---|---|---|
| 1 | Nereidae | 180×120 | Ondula cruzando la pantalla en vertical y dispara 3 balas apuntadas cada 2 s | Evierte la faringe con mandíbulas que embisten en horizontal tras aviso de 0,5 s; los parapodios disparan abanico de 5 | Se divide en dos segmentos que persiguen al jugador y lanzan anillos de 12 balas |
| 2 | Capitelidae | 200×140 | Columnas de arena que emergen del suelo con aviso en el suelo | Expulsa la cabeza con ganchos en abanico | Tormenta de arena (los bordes de pantalla se oscurecen) y embestida diagonal |
| 3 | Polinoidae | 200×140 | Lanza escamas laterales que rebotan una vez | Los élitros cubren los puntos débiles; hay que abrirlos con bombas o esperar 4 s | Modo blindado: carga horizontal y lluvia de piedras desde el acantilado |
| 4 | Terebellidae | 240×180 | 8 tentáculos barren desde arriba y abajo; puntos débiles en las puntas | Los tentáculos agarran la nave y la arrastran despacio hacia la boca (se suelta disparando a la punta) | Nubes de mucosidad que ralentizan un 30 % más ráfagas desde la boca |
| 5 | Hermodice carunculata | 220×140 | Cerdas disparadas en abanico de 7 | Se enrosca en el coral y embiste en línea recta | Modo ardiente: lluvia de cerdas y anillo expansivo cada 5 s |
| 6 | Phyllodocidae | 220×140 | Se esconde entre las hojas del fondo; solo aparecen partes del cuerpo (falsos blancos) | Lanza hojas cortantes que giran | Enjambre de hojas guiadas más ondulación del cuerpo por toda la pantalla |
| 7 | Orbiniidae | 240×160 | Brotes de fango que salen del suelo | Expulsa burbujas de gas tóxico que estallan en nube | Sale del fango y embiste; caen raíces de manglar desde el techo |
| 8 | Capitella capitata, Streblospio benedicti, Cirriformia tentaculata (3 jefes) | 120×80, 140×90, 160×100 | Cada uno ataca por separado en carriles distintos (Capitella lanza crías; Streblospio, palpos en espiral que regresan como bumerán; Cirriformia, cirros que barren) | Se combinan en parejas: patrones cruzados | Cuando muere uno, los restantes ganan furia (+25 % de cadencia). El último en pie usa los tres patrones |
| 9 | Tomopteridae | 260×140 | Puntos de luz cian que siguen al jugador | Se vuelve semitransparente; parpadea entre visible e invisible cada 2 s | Destellos de luz que ciegan la pantalla 0,3 s (con aviso) y rayos cian en abanico |
| 10 | Eulagisca gigantea | 260×160 | Caen estalactitas de hielo (aviso de 0,7 s) | Escamas de hielo giran como escudo alrededor del cuerpo | Tormenta de nieve (ruido visual leve) y embestida congelante que ralentiza 1 s |
| 11 | Osedax | 300×200 | Raíces que salen de los huesos como estacas | Libera enjambre de machos diminutos que persiguen | Ácido: zonas de daño que aparecen en suelo y techo y se expanden |
| 12 | Alvinella pompejana | 300×200 | Géiseres de fuego desde las chimeneas con aviso en el suelo | Manto de lava en el fondo que sube de nivel durante 10 s | Erupción: columnas de magma verticales combinadas con abanico de brasas |
| 13 | Macellicephaloides grandicirra y Riftia pachyptila (2 jefes) | 200×120 y 160×300 | Riftia fijo al borde derecho con penacho que dispara abanico; Macellicephaloides orbita y embiste | Macellicephaloides lanza escamas; Riftia dispara anillos | Muerto Riftia, Macellicephaloides entra en furia (+30 % de velocidad y cadencia) |

### 6.3 Vida de jefes y minijefes

`HP jefe = 0,65 × DPSref × tiempo objetivo (s)`; `HP minijefe = 0,65 × DPSref × 50 s`. Valores iniciales, se ajustan en playtest respetando la regla de tiempo mínimo (3.4).

| Mundo | DPSref | Tiempo objetivo jefe | HP jefe final | HP minijefe |
|---|---|---|---|---|
| 1 | 30 | 1:30 | 1.750 | 975 |
| 2 | 36 | 1:30 | 2.100 | 1.170 |
| 3 | 42 | 1:30 | 2.450 | 1.365 |
| 4 | 48 | 1:45 | 3.300 | 1.560 |
| 5 | 54 | 1:45 | 3.700 | 1.755 |
| 6 | 60 | 1:45 | 4.100 | 1.950 |
| 7 | 66 | 2:00 | 5.150 | 2.145 |
| 8 | 72 | 2:15 | 6.300 (2.100 cada jefe) | 2.340 |
| 9 | 78 | 2:00 | 6.100 | 2.535 |
| 10 | 84 | 2:00 | 6.550 | 2.730 |
| 11 | 90 | 2:00 | 7.000 | 2.925 |
| 12 | 96 | 2:00 | 7.500 | 3.120 |
| 13 | 102 | 2:30 | 9.950 (Riftia 4.000 y Macellicephaloides 5.950) | 3.315 |
| 14 | 108 | Ver 6.4 | Ver 6.4 | 3.510 |

### 6.4 Los cuatro jefes del laboratorio (mundo 14)

Cada jefe se enfrenta en una sala distinta. Después de cada uno hay punto de control y pantalla de descanso. Fases y patrones son propuesta de diseño.

| Jefe | Tiempo objetivo | HP | Tamaño | Fases y patrones |
|---|---|---|---|---|
| 4.1 Robóticos | 1:30 | 6.300 (3 robots: 2.100 cada uno) | 140 px cada uno | F1: los tres entran uno por uno, cada uno con su patrón (pinza, torreta, taladro). F2: atacan de a dos, patrones cruzados. F3: los que sobreviven se fusionan en un solo robot grande con los tres patrones |
| 4.2 Epitoca | 2:00 | 8.400 | 220×140 | F1: forma de gusano lenta con ondas. F2: se transforma en epitoca (nadadora, rápida, con ojos grandes). F3: libera nubes de gametos (balas pequeñas) mientras gira alrededor de la pantalla |
| 4.3 Científico | 2:00 | 8.400 | 200×200 (figura en exoarmadura) | F1: drones y láseres de sala. F2: inyecta una sustancia a las criaturas de los tanques, que se liberan como escoltas. F3: activa su mecha con brazos que embisten. Al morir, cae al tanque central y se libera a Eunice |
| 4.4 Eunice aphroditois | 3:00 | 12.650 | 320×300 (media pantalla) | F1: antenas visibles y emboscadas desde el borde derecho (mandíbulas que salen del suelo con aviso). F2: segmentos del cuerpo atraviesan la pantalla horizontalmente. F3: mandíbulas dobles más lluvia de escombros. F4 (al 15 % de vida): furia, se queda quieta y dispara anillos y mandíbulas simultáneos |

El minijefe del laboratorio es un poliqueto robótico grande (128 px) con patrón de R2 y R5 ampliados.

---

## 7. Economía y tienda

### 7.1 Principios

- Pocas mejoras, pero fuertes y con rangos. Cada compra debe notarse.
- **El jugador no puede comprarlo todo.** La tienda cuesta más de lo que se gana, así que hay que elegir una build.
- Los precios suben por rango, no por mundo.
- La dificultad crece con los enemigos y con los jefes, no solo con lo que compra el jugador.

### 7.2 Ingresos

Cada mundo da una **base** de monedas. El 60 % de la base se obtiene recogiendo monedas durante la etapa y el 40 % es la recompensa de fin de mundo. Si se termina el mundo sin morir, se suma un **bono de +20 %** sobre la base.

El valor total de monedas que sueltan los enemigos de la etapa es el 75 % de la base del mundo (el jugador recoge normalmente el 80 %, que da el 60 %).

| Mundo | Base | Acumulado | Mundo | Base | Acumulado |
|---|---|---|---|---|---|
| 1 | 300 | 300 | 10 | 1.200 | 7.500 |
| 2 | 400 | 700 | 11 | 1.300 | 8.800 |
| 3 | 500 | 1.200 | 12 | 1.400 | 10.200 |
| 4 | 600 | 1.800 | 13 | 1.500 | 11.700 |
| 5 | 700 | 2.500 | 14 (4.1) | 1.200 | 12.900 |
| 6 | 800 | 3.300 | 14 (4.2) | 1.400 | 14.300 |
| 7 | 900 | 4.200 | 14 (4.3) | 1.600 | 15.900 |
| 8 | 1.000 | 5.200 | 14 (4.4) | 2.000 | 17.900 |
| 9 | 1.100 | 6.300 | | | |

Ingreso total: **17.900** sin bono y **21.480** con el bono en todo (el bono suma 3.580). Hay **17 visitas** a la tienda: tras cada mundo del 1 al 13 y tras cada uno de los 4 jefes del laboratorio.

### 7.3 Mejoras permanentes

| Mejora | Rangos | Efecto por rango | Costos por rango | Total |
|---|---|---|---|---|
| Escudo máximo | 5 | +20 de escudo | 250, 450, 700, 1.000, 1.400 | 3.800 |
| Daño | 5 | +12 % de daño de todas las armas | 300, 500, 800, 1.200, 1.700 | 4.500 |
| Cadencia | 4 | +10 % de disparos por segundo | 300, 550, 900, 1.300 | 3.050 |
| Misiles | 4 | +1 al nivel mínimo de misiles (no baja de ese nivel al morir) | 350, 600, 950, 1.400 | 3.300 |
| Bombas | 3 | +1 bomba máxima | 300, 550, 900 | 1.750 |
| Regeneración de escudo | 3 | Tras 5 s sin daño, +1, +2 o +3 de escudo por segundo | 250, 500, 800 | 1.550 |
| Imán de monedas | 3 | Radio de atracción de 24 px base, +40 px por rango | 150, 300, 500 | 950 |
| Velocidad | 3 | +8 % de velocidad | 150, 300, 500 | 950 |
| **Total mejoras** | | | | **19.850** |

### 7.4 Equipo oceanográfico (desbloqueo por acto)

Cada pieza se compra una sola vez y se activa sola. Se desbloquea en la primera visita a la tienda del acto indicado (acto 1: tras el mundo 1; acto 2: tras el mundo 5; acto 3: tras el mundo 9; acto 4: tras el jefe 4.1). Los efectos son propuesta inicial.

| Acto | Equipo | Costo | Efecto de juego |
|---|---|---|---|
| 1 | Draga | 600 | Recoge automáticamente las monedas en un radio de 96 px (no se suma al Imán: vale el mayor) |
| 1 | Red de arrastre | 800 | Atrapa hasta 5 balas pequeñas por etapa frente a la nave (se recarga en cada punto de control) |
| 2 | Botella Niskin | 900 | Cada 20 s lanza un pulso de 140 px de radio que ralentiza a los enemigos un 50 % durante 2 s (25 % a jefes) |
| 2 | Box corer | 1.000 | El disparo principal perfora un enemigo más |
| 2 | CTD | 1.100 | Muestra la barra de vida de los jefes y marca sus puntos débiles |
| 3 | Multicorer | 1.300 | Cada 6 s dispara 4 proyectiles en abanico de 3× el daño del disparo principal cada uno |
| 3 | ROV | 1.500 | Dron aliado que orbita la nave y dispara un 30 % del DPS del disparo principal; no recibe daño |
| 3 | Lander | 1.400 | Una resurrección por mundo con el 50 % del escudo; no cuenta como muerte para el bono |
| 4 | Deflector | 2.000 | Escudo frontal de 32 px que convierte las balas pequeñas en proyectiles aliados de 5 de daño |
| | **Total equipo** | **10.600** | |

**Total de la tienda: 30.450.** Frente a 17.900 a 21.480 de ingreso, el jugador compra entre el **59 % y el 71 %** de todo. Es intencional: hay que elegir.

### 7.5 Reglas de tienda

- Solo se abre en la pantalla de descanso (sección 8).
- Antes de comprar se muestra costo, rango actual y efecto antes y después.
- **Reembolso del 100 %** de lo comprado, solo dentro de la misma visita (para probar builds). Al salir de la tienda las compras quedan fijas.
- Todo lo comprado se conserva al morir.
- Un solo archivo `data/shop.json` define mejoras, rangos, costos, efectos y acto de desbloqueo.
- La tienda impide gastar monedas que no se tienen.

### 7.6 Hoja de balance (entregable obligatorio antes del código de tienda)

Codex genera `docs/balance_sheet.csv` con una fila por mundo (y por jefe del laboratorio) y estas columnas: `mundo, acto, enemigos, duracion_hasta_jefe_seg, jefe_objetivo_seg, base_monedas, bono_sin_morir, acumulado, equipo_desbloqueado, vida_enemigo_pequeno, vida_jefe, vida_minijefe, dps_ref`. Y `docs/shop_sheet.csv` con una fila por mejora y rango. Debe calcular ingreso acumulado frente al gasto máximo posible, para revisar el balance en una tabla antes de jugar.

---

## 8. Pantalla de descanso, skins, astillero y guardado

La pantalla de descanso aparece tras terminar un mundo (después de la pantalla de resultados) y tras cada jefe del laboratorio. Música de descanso (sección 11).

### 8.1 Pantalla de resultados

Antes del descanso: enemigos derrotados (con porcentaje), monedas recogidas, recompensa de fin de mundo, bono sin morir (si aplica), muertes en el mundo, tiempo del mundo, objeto único conseguido (si aplica). Todo cuenta en un recuento animado de 4 s que se puede saltar con el botón de disparo.

### 8.2 Menú de descanso

Botones, en este orden:
1. **Tienda** (sección 7).
2. **Astillero:** personalización visual de la nave (3 zonas de color: casco, luces y estela) y vista del equipo instalado. Solo cosmético.
3. **Skins:** conjuntos completos de aspecto de nave (tabla 8.3).
4. **Guardar:** guardado manual en 3 ranuras.
5. **Rejugar mundo:** lista los mundos ya superados. Con la build actual, rinde el 50 % de la base de monedas, sin bono y sin objetos únicos. No altera el progreso.
6. **Siguiente mundo.**

Al entrar al menú se hace **guardado automático** en la ranura activa. Se muestra el acto, el mundo siguiente, las monedas, el tiempo total jugado y las muertes totales.

### 8.3 Skins (cosméticas, no se compran con monedas)

Para no competir con las mejoras, las skins se desbloquean por logros y por objetos únicos de jefe.

| Skin | Cómo se desbloquea |
|---|---|
| Casco original | Desde el inicio |
| Batiscafo amarillo | Terminar el mundo 4 |
| Coral | Objeto único del jefe del mundo 3 |
| Abisal | Objeto único del jefe del mundo 6 |
| Bioluminiscente | Objeto único del jefe del mundo 9 |
| Magma | Objeto único del jefe del mundo 12 |
| Laboratorio | Derrotar a Eunice aphroditois |
| Fantasma | Terminar un mundo sin morir en dificultad Difícil |
| Dorado | Terminar el juego sin morir |

### 8.4 Archivo de guardado

JSON en la carpeta de datos del usuario, 3 ranuras. Contiene: versión del archivo, dificultad, mundo actual, monedas, rangos comprados, equipo comprado, niveles de arma al entrar al siguiente mundo, bombas, skins desbloqueadas y equipada, colores del astillero, muertes por mundo, tiempo jugado, mundos superados, semilla del laboratorio. Debe tener un campo `version` y migración básica. El juego debe sobrevivir a un guardado corrupto (avisar y ofrecer una copia de respaldo `.bak`).

---

## 9. Muerte, pantalla de muerte y dificultad

### 9.1 Reglas de muerte

- Sin límite de vidas.
- Se reaparece en el último punto de control del mundo (inicio de etapa, tras el minijefe o, en el laboratorio, tras cada jefe) con las compras conservadas y el **arma al nivel con el que entró al mundo** (las mejoras de nivel mínimo de misiles se respetan).
- Las monedas recogidas se conservan.
- Cada muerte suma al contador del mundo; con 0 muertes en el mundo se gana el bono de +20 %.
- Con la mejora Lander, la resurrección no cuenta como muerte.

### 9.2 Pantalla de muerte

Secuencia: explosión de 1,2 s, fundido a negro de 0,5 s y pantalla.

| Elemento | Contenido |
|---|---|
| Título | "HAS SIDO DEVORADO" (si lo mató un jefe: "EL JEFE TE HA DEVORADO") |
| Causa | "Derrotado por: [familia]" o el nombre del jefe |
| Datos | Mundo y su nombre, muertes en este mundo, punto de control al que volverás, niveles de arma con los que reaparecerás (iconos con pips) |
| Consejo | Una frase al azar de una lista de 20 consejos (por ejemplo, "Las bombas limpian balas") |
| Botones | **Reintentar** (seleccionado por defecto), Opciones, Salir al título (con confirmación) |
| Sugerencia | Tras 5 muertes seguidas en el mismo tramo, un aviso opcional: "¿Probar en dificultad Fácil?" |

Música: se corta la música de etapa y suena un tema corto de 6 s en bucle bajo. Al reintentar, fundido de 0,5 s. El tiempo desde pulsar Reintentar hasta tener control de la nave debe ser menor de 2 s.

### 9.3 Dificultades

Se elige al empezar una partida y se puede cambiar desde Opciones en la pantalla de descanso.

| | Fácil | Normal | Difícil |
|---|---|---|---|
| Daño recibido | ×0,7 | ×1 | ×1,3 |
| Vida de jefes | ×0,85 | ×1 | ×1,15 |
| Velocidad de balas enemigas | ×0,9 | ×1 | ×1,1 |
| Burbujas de escudo | ×1,3 | ×1 | ×0,8 |
| Punto de control extra | Sí, en la alerta del jefe | No | No |

La economía no cambia con la dificultad.

---

## 10. HUD, menús y flujo de pantallas

### 10.1 Flujo

```
Portada → Menú principal → [Nueva partida → Dificultad] / Continuar
  → Mundo N: Introducción (2 s) → Etapa → Resultados → Descanso → Mundo N+1
  → ... → Mundo 14 (etapa + 4 jefes con descanso entre ellos)
  → Nivel de escape → Final y créditos → Estadísticas → Portada
```

### 10.2 Portada y menú principal

- Portada de 640×360 en pixel art con el logo "Poliquetos Asesinos" y la leyenda "Pulsa Start" parpadeando.
- Menú: Nueva partida, Continuar, Opciones, Créditos, Salir.
- Selector de ranura al elegir Nueva partida o Continuar.

### 10.3 Opciones

Volumen general, música y efectos (0 a 10); pantalla (ventana ×1, ×2, ×3 o pantalla completa); disparo automático; remapeo de teclas y mando; temblor de pantalla (sí/no); reducir destellos (sí/no); mostrar hitbox (solo en modo depuración).

### 10.4 Controles por defecto

| Acción | Teclado | Mando |
|---|---|---|
| Mover | Flechas o WASD | Stick izquierdo o cruceta |
| Disparo (mantener) | Z o Espacio | A |
| Bomba | X | B |
| Pausa | Esc o P | Start |

Los misiles son automáticos.

### 10.5 Pausa

Continuar, Opciones, Reiniciar desde el último punto de control, Salir al título (con confirmación). Al continuar, cuenta atrás de 3 s.

### 10.6 HUD durante la etapa

Barra inferior de 640×24 px:

| Posición | Elemento |
|---|---|
| Izquierda (x 8 a 128) | Barra de escudo segmentada de 120×8 px, con número |
| x 140 a 260 | Tres iconos de arma (disparo, misil, bomba) con pips del nivel 1 a 8 |
| x 270 a 340 | Iconos de bombas (hasta 5) |
| x 350 a 440 | Contador de monedas con icono |
| Derecha (x 450 a 630) | Barra de progreso de etapa con marcas del minijefe y del jefe |

Durante jefes: barra de vida en la parte superior, de 480×6 px centrada, con marcas en el 66 % y el 33 %. Con varios jefes, una barra por jefe, apiladas. El nombre del jefe se muestra sobre la barra. Con la mejora CTD se muestra además el número de vida.

Mensajes sobre la pantalla: "ALERTA" (6 s antes del jefe), "NIVEL MÁXIMO" al llegar a nivel 8, "PUNTO DE CONTROL" 2 s al activarse.

---

## 11. Música y audio

### 11.1 Estructura musical

- **Cada mundo tiene una canción de jefe con voz.** La música de la etapa es la **versión instrumental** de esa misma canción y suena en bucle durante todo el mundo.
- Al comenzar la alerta del jefe, la música instrumental baja de volumen y entra la versión con voz con un fundido cruzado de 1 s, sincronizado al siguiente compás si el audio incluye el dato de BPM.
- El minijefe no cambia la música. Si el audio incluye una capa de percusión (stem), se activa en el minijefe; si no, no cambia nada.
- En los mundos 8 (tres jefes) y 13 (dos jefes), suena una sola canción para todos los jefes juntos.
- En el laboratorio hay una canción por jefe: cuatro canciones con voz (4.1, 4.2, 4.3, 4.4) y una instrumental común para la etapa (versión instrumental de la canción de 4.1).

### 11.2 Lista de pistas

| Mundo | Canción del jefe (con voz) | Pista de etapa (instrumental) |
|---|---|---|
| 1 | Nereida Vuelve a Desgarrar | `w01_level_instr` |
| 2 | Capitélido del Arenal | `w02_level_instr` |
| 3 | Polinoideo de Hierro | `w03_level_instr` |
| 4 | Reina de los Tentáculos | `w04_level_instr` |
| 5 | Gusano de Fuego | `w05_level_instr` |
| 6 | En proceso (sugerencia: Hoja entre las Hojas) | `w06_level_instr` |
| 7 | Orbiniidae, sal de ahí | `w07_level_instr` |
| 8 | Zona muerta | `w08_level_instr` |
| 9 | En proceso | `w09_level_instr` |
| 10 | En proceso | `w10_level_instr` |
| 11 | Osedax | `w11_level_instr` |
| 12 | En proceso | `w12_level_instr` |
| 13 | En proceso | `w13_level_instr` |
| 14 | En proceso (cuatro canciones: 4.1, 4.2, 4.3 y 4.4) | `w14_level_instr` |

Las pistas con voz se llaman `wNN_boss_vocal` (para el laboratorio: `w14_boss1_vocal` a `w14_boss4_vocal`). Mientras una canción esté "En proceso", Codex usa una pista silenciosa de 10 s como marcador y deja el nombre `en_proceso` en el archivo de datos.

### 11.3 Otras pistas

Portada, descanso (suave, común a todos los mundos), pantalla de muerte (6 s), jingle de victoria de minijefe (2 s) y de jefe (4 s), nivel de escape, créditos.

### 11.4 Formato técnico

- Música en OGG Vorbis, 44,1 kHz, estéreo. Efectos en OGG o WAV mono.
- Archivo `data/audio.json` con, por pista: ruta, volumen, `loop_start` y `loop_end` en segundos, y `bpm` (opcional).
- Efectos mínimos: disparo (3 variantes por nivel), misil, bomba, impacto en enemigo, explosión pequeña y grande, burbuja, moneda, compra, rechazo de compra, daño al jugador, nivel de arma, alerta de jefe, cambio de fase, apertura de menú, selección.
- No más de 16 sonidos simultáneos; cuando se sature, se descartan los de menor prioridad (los de disparo primero).

---

## 12. Nivel de escape y final

Tras derrotar a Eunice aphroditois, el laboratorio colapsa. El nivel de escape es una etapa especial de **5:00** (propuesta de diseño, ver sección 14).

- **Scroll acelerado** a 120 px/s (el doble de lo normal). Luz roja pulsante y temblor de pantalla leve.
- **Sin jefe.** Hay 90 enemigos (poliquetos robóticos y aleatorios) y los peligros del laboratorio.
- Tres tramos:

| Tramo | Tiempo | Contenido |
|---|---|---|
| 1. Corredores | 0:00 a 1:30 | Compuertas que se cierran con ciclo de 4 s, láseres, 30 enemigos |
| 2. Tanque inundado | 1:30 a 3:30 | Escombros que caen (aviso de 0,5 s), corrientes de agua que empujan, 40 enemigos |
| 3. Salida al mar abierto | 3:30 a 5:00 | Oleadas de 20 enemigos, fondo que pasa del laboratorio al mar celeste del mundo 1; el escenario "amanece" |

- Puntos de control cada 1:30. No hay tienda ni compras.
- Recompensa: 1.000 monedas que no se pueden gastar (solo cuentan para la puntuación final) y desbloqueo de la skin "Dorado" si no se murió en toda la partida.
- Final: escena con la nave emergiendo al mar, créditos con la música de créditos, estadísticas (tiempo total, muertes, monedas totales, porcentaje de enemigos derrotados) y regreso a la portada. El guardado queda marcado como "completado" y permite rejugar mundos.

---

## 13. Fases de trabajo para Codex

Hacer un commit por fase y dejar una nota breve de lo hecho y lo pendiente.

**Fase 0. Inventario y base.** Revisar el proyecto actual. Crear `data/legacy_inventory.json` con todos los poliquetos y jefes existentes (nombre, mundo, estadísticas, sprites actuales). Crear la estructura de carpetas (sección 15.3) y los esquemas JSON (15.1). Aceptación: el inventario coincide con la tabla 4.2 y con los jefes de 4.1.

**Fase 1. Motor de assets y resolución.** Resolución 640×360 con escalado entero y vecino más cercano. Carga de PNG y atlas JSON por mundo. Generador de placeholders y del `assets_manifest.json`. Fuente bitmap. Aceptación: se puede sustituir un PNG sin tocar código; F3 muestra hitboxes.

**Fase 2. Núcleo de juego.** Nave, movimiento, disparo principal con 8 niveles, escudo, colisiones, scroll con parallax de 3 a 4 capas, un enemigo de prueba, HUD base. Aceptación: 60 FPS estables con 200 balas en pantalla; la nave muere y reaparece.

**Fase 3. Armas e ítems.** Misiles, bombas, burbujas de ítem, oleadas portadoras, reglas de nivel y de muerte. Aceptación: un modo depuración permite fijar cualquier nivel de cada arma y verificar el DPS de las tablas 5.3 y 5.4.

**Fase 4. Motor de oleadas y etapa.** Lector de `data/waves/world_NN.json`, patrones M1 a M8 y F0 a F5, formaciones, línea de tiempo de 3.2, peligros de escenario, punto de control. Aceptación: el mundo 1 completo (3:00 hasta el jefe) con sus 90 enemigos, el minijefe y la alerta, todo definido en datos.

**Fase 5. Jefes y minijefes.** Segmentos, fases, puntos débiles, telegrafiado, invulnerabilidad entre fases, entrada y derrota, jefes múltiples (mundos 8, 13 y 4.1). Aceptación: un jefe de 3 fases funcional con sus patrones y la regla de tiempo mínimo medible con una herramienta de depuración que simula el DPS máximo.

**Fase 6. Economía y tienda.** `shop.json`, pantalla de resultados, pantalla de descanso, compra y reembolso, aplicación de efectos, equipo por acto, hoja de balance generada. Aceptación: `balance_sheet.csv` y `shop_sheet.csv` coinciden con la sección 7 (totales 17.900, 21.480 y 30.450).

**Fase 7. Flujo, guardado y menús.** Portada, menú, opciones, pausa, pantalla de muerte (9.2), dificultades (9.3), guardado automático y manual (8.4), rejugar mundo, skins y astillero. Aceptación: cerrar y reabrir el juego restaura la partida exacta.

**Fase 8. Contenido de los mundos 1 al 13.** Archivos de oleadas, escoltas, minijefe y jefe de cada mundo con los datos de las secciones 3, 4, 5 y 6. Aceptación: cada mundo respeta enemigos y tiempos de la tabla 3.3.

**Fase 9. Laboratorio y escape.** Mundo 14 con sus 4 sectores, minijefe, los 4 jefes en cadena con descansos, y el nivel de escape (12). Aceptación: el mundo 14 dura 5:30 hasta el primer jefe y se completa de punta a punta.

**Fase 10. Audio, pulido y balance.** Música por mundo con el cambio a canción con voz, efectos, ajuste de HP con la regla de tiempo mínimo, prueba de duración total. Aceptación: el recorrido objetivo dura 1 h 30 min y un jugador hábil con build máxima lo termina en unos 1 h 10 min (nunca menos de 1 h 05 min).

---

## 14. Puntos abiertos (preguntar antes de inventar)

| Tema | Valor por defecto si no hay respuesta |
|---|---|
| Nombres de canciones "En proceso" (mundos 6, 9, 10, 12, 13 y las cuatro del laboratorio) | Usar `en_proceso` y, para el mundo 6, la sugerencia "Hoja entre las Hojas" |
| Los 6 poliquetos robóticos del laboratorio (5.8.4) | Usar la propuesta de la tabla, marcada como `revisar` |
| Función original del astillero y del menú de skins en el juego anterior | Usar las definiciones de la sección 8 |
| Efectos del equipo oceanográfico (7.4) | Usar la propuesta de la tabla |
| Patrones exactos de cada jefe y sus puntos débiles (6.2 y 6.4) | Usar la propuesta; el artista ajusta |
| Nivel de escape (sección 12): duración, tramos, recompensa | Usar la propuesta |
| Si los niveles de arma deben conservarse entre mundos | Conservarlos (sección 5.6) |
| Los jefes del laboratorio: guion o texto de escenas entre jefes | Sin escenas; solo una línea de texto de 2 s al entrar a cada sala |
| Personalización de la nave: cuántas zonas de color | 3 zonas (casco, luces, estela) |
| Idioma de la interfaz | Solo español |

---

## 15. Anexos técnicos

### 15.1 Formatos de datos (JSON)

**`data/worlds.json`** (un registro por mundo):

```json
{
  "id": 1,
  "nombre": "Superficie marina",
  "acto": 1,
  "duracion_hasta_jefe_seg": 180,
  "enemigos_total": 90,
  "minijefe_inicio_seg": 60,
  "minijefe_ventana_seg": 60,
  "alerta_jefe_seg": 170,
  "paleta": ["#7fd8f0", "#2bb5c9", "#f5f1d0"],
  "scroll_px_s": 60,
  "cancion_jefe": "Nereida Vuelve a Desgarrar",
  "musica_etapa": "w01_level_instr",
  "musica_jefe": "w01_boss_vocal",
  "peligros": ["boyas", "cascos"],
  "minijefe": "mini_w01_pisionidae",
  "jefes": ["boss_w01_nereididae"]
}
```

**`data/enemies.json`:**

```json
{
  "id": "serpulidae",
  "familia": "Serpulidae (Hydroides)",
  "tipo": "tubicola",
  "categoria": "pequeno",
  "mundos": {
    "1": { "rol": "unico", "sprite_set": "w01_enemy_serpulidae" },
    "3": { "rol": "recurrente", "sprite_set": "w03_enemy_serpulidae" }
  },
  "movimiento": "M5",
  "disparo": "F3",
  "puntos": 100,
  "drop": { "moneda_chica": 0.35, "moneda_grande": 0.05 },
  "estado": "revisar"
}
```

**`data/waves/world_01.json`:**

```json
{
  "mundo": 1,
  "eventos": [
    { "t": 10.0, "tipo": "oleada", "enemigo": "serpulidae", "cantidad": 6, "formacion": "linea_vertical", "y": 168, "portadora": false },
    { "t": 20.0, "tipo": "oleada", "enemigo": "euphrosinidae", "cantidad": 5, "formacion": "v", "y": 120, "portadora": true, "item": "rojo" },
    { "t": 60.0, "tipo": "minijefe", "id": "mini_w01_pisionidae" },
    { "t": 120.0, "tipo": "oleada", "enemigo": "syllidae", "cantidad": 16, "formacion": "zigzag", "y": 168 },
    { "t": 170.0, "tipo": "alerta_jefe", "id": "boss_w01_nereididae" }
  ]
}
```

**`data/bosses.json`:**

```json
{
  "id": "boss_w01_nereididae",
  "nombre": "Nereidae",
  "vida": 2350,
  "tamano": [180, 120],
  "segmentos": [
    { "id": "cabeza", "hitbox": [0, 0, 48, 48], "debil": true, "mult_dano": 2.0 },
    { "id": "cuerpo", "hitbox": [48, 0, 132, 48], "debil": false, "mult_dano": 0.5 }
  ],
  "fases": [
    { "desde_pct": 100, "hasta_pct": 66, "patrones": ["ondular_vertical", "balas_apuntadas_3"] },
    { "desde_pct": 66, "hasta_pct": 33, "patrones": ["faringe_embestida", "abanico_5"] },
    { "desde_pct": 33, "hasta_pct": 0, "patrones": ["dividir_en_dos", "anillo_12"] }
  ],
  "recompensa_extra": 0,
  "objeto_unico": null
}
```

**`data/shop.json`:**

```json
{
  "mejoras": [
    { "id": "escudo_max", "rangos": 5, "efecto_por_rango": { "escudo": 20 }, "costos": [250, 450, 700, 1000, 1400] },
    { "id": "dano", "rangos": 5, "efecto_por_rango": { "dano_pct": 12 }, "costos": [300, 500, 800, 1200, 1700] }
  ],
  "equipo": [
    { "id": "draga", "acto": 1, "costo": 600, "efecto": "autorecoger_96px" },
    { "id": "deflector", "acto": 4, "costo": 2000, "efecto": "convertir_balas_pequenas" }
  ],
  "reembolso_misma_visita": 1.0
}
```

Los demás archivos (`cosmetics.json`, `audio.json`) siguen el mismo criterio: un registro por elemento, identificadores en `snake_case`.

### 15.2 Atlas de assets (por mundo)

```json
{
  "imagen": "w01.png",
  "tamano": [1024, 1024],
  "frames": {
    "w01_enemy_serpulidae_move_01": { "x": 0, "y": 0, "w": 32, "h": 32 },
    "w01_enemy_serpulidae_move_02": { "x": 32, "y": 0, "w": 32, "h": 32 }
  },
  "animaciones": {
    "w01_enemy_serpulidae_move": { "frames": ["w01_enemy_serpulidae_move_01", "w01_enemy_serpulidae_move_02"], "fps": 8, "bucle": true }
  }
}
```

### 15.3 Estructura de carpetas

```
/data
  legacy_inventory.json  worlds.json  enemies.json  bosses.json
  shop.json  cosmetics.json  audio.json
  waves/world_01.json ... world_14.json  escape.json
/docs
  balance_sheet.csv  shop_sheet.csv  decisiones.md
/assets
  assets_manifest.json
  atlas/w01.json  w01.png ... w15.json  w15.png
  sprites/<mundo>/  backgrounds/<mundo>/  ui/  fx/
  audio/music/  audio/sfx/
/src
  core/  player/  weapons/  enemies/  bosses/  stages/  shop/  save/  ui/  audio/
```

### 15.4 Criterios de aceptación globales

- Cada etapa respeta enemigos y tiempos de la tabla 3.3 con una tolerancia de ±5 s en el momento del aviso del jefe.
- La duración total del recorrido objetivo es de 1 h 30 min (±5 min) y la de un jugador hábil con build máxima y sin morir no baja de 1 h 05 min (regla de tiempo mínimo de 3.4).
- 60 FPS estables con 200 balas enemigas y 50 enemigos en pantalla.
- Todos los parámetros de balance viven en archivos de datos; cambiar un precio o la vida de un jefe no requiere recompilar.
- Reemplazar un PNG por arte final no requiere cambios de código.
- El guardado sobrevive a cerrar el juego en cualquier momento de la pantalla de descanso.
- La tienda impide gastar monedas que no se tienen y los reembolsos no generan monedas de más.
- El juego es completable de principio a fin sin herramientas de depuración.
- Las mecánicas se inspiran en las referencias; **ningún sprite, nombre, jefe o música de otro juego** forma parte del proyecto.

### 15.5 Cómo trabajar con este documento

- Un commit por fase con una nota breve de lo hecho y lo pendiente.
- Si una instrucción es ambigua o choca con lo existente, elegir la opción más simple, anotarla en `docs/decisiones.md` y continuar (salvo los temas de la sección 14, que se preguntan).
- Los valores numéricos son iniciales y se ajustan jugando, siempre mediante los archivos de datos.
