# Poliquetos asesinos · PoliGames

Videojuego 2D de exploración y combate submarino. Abre **`poliquetos_asesinos_8_edicion_sonora (18).html`** en Chrome, Edge o Firefox. El juego completo, sus gráficos y sonidos están incluidos: el modo individual funciona sin internet.

Para actualizar conservando tus guardados, reemplaza el HTML anterior en su misma carpeta y usa el mismo navegador. No borres los datos del sitio. También puedes servir esta carpeta:

```sh
python3 -m http.server 8000 --bind 127.0.0.1
```

## Campaña del PDF

| Acto | Mundos |
|---|---|
| 1 | Superficie marina, playas arenosas, costa rocosa, bosques de kelp |
| 2 | Arrecifes tropicales, pastos marinos, estuarios y fango, sedimentos contaminados |
| 3 | Zona planctónica, Antártica, restos de ballena, campos hidrotermales, zona hadal |
| 4 | El laboratorio |

Son **14 mundos y 144 sectores**. Los primeros 13 mundos tienen 9 sectores normales y un encuentro de jefe. Las cantidades y las familias/géneros siguen la distribución del PDF. El laboratorio tiene 9 oleadas, un cuarteto mecánico, epítoke, científico, Eunice anclada y un único rescate: sobrevive 180 segundos, con pausa efectiva y oleadas continuas.

La pantalla de derrota permite reintentar desde el comienzo del sector actual, conservando el equipamiento y las monedas de ese punto. Los guardados de la campaña anterior se migran por hábitat, manteniendo las recompensas ya cobradas y el acceso a los mundos.

## Descanso, tienda y aspecto

Después de cada sector puedes continuar, comprar, visitar el **Astillero** o guardar y salir. El Astillero permite cambiar aspecto sin reanudar la misión. Algunas skins son trofeos y otras se compran; la colección cosmética permanece entre expediciones en este navegador.

Los equipos se compran por acto:

- Acto 1: draga y arrastre. Sonar disponible desde el inicio.
- Acto 2: Niskin, box corer y CTD.
- Acto 3: multicorer, ROV y lander.
- Acto 4: deflector.

Las compras y los créditos se validan en el motor/anfitrión; la colección cosmética persistente se importa del perfil local y solo permite aplicar aspectos registrados como propios. No aporta estadísticas de combate.

## Controles y opciones

WASD mueve; flechas o ratón disparan; F evade; H rescata al copiloto; 1 y 2 usan consumibles; P/Esc pausa. Los atajos de cada equipo se pueden cambiar en **Opciones**, con prevención de teclas duplicadas o reservadas.

Los controles de audio se simplifican a música, efectos y sus respectivos volúmenes. **Las composiciones, canciones, instrumentos y muestras no se han sustituido**: quedan pendientes del trabajo musical del autor. El sonido comienza al interactuar con el juego.

El modo ECO reduce partículas y luz; la preferencia de movimiento reducido desactiva desplazamientos y animaciones decorativas. El cooperativo requiere internet y PeerJS/WebRTC; ambos jugadores deben usar esta misma versión.

## Pruebas

Node.js, Playwright y Chromium están disponibles en el entorno cloud preparado; no son necesarios para jugar.

```sh
node --test
```

Puedes indicar otro Chromium mediante `CHROMIUM_PATH`. Las pruebas usan copias instrumentadas exclusivamente dentro de los servidores/VM de test: el juego distribuido no expone una API de depuración. Se comprueban campaña, conteos, jefes, economía, migración, reintento, rescate, skins, astillero, atajos, audio y HUD.

## Dos ediciones, desde esta actualización

- **Normal:** `versiones/poliquetos-normal.html`, con progresión y economía normales.
- **Pruebas:** `versiones/poliquetos-pruebas.html`, con todos los mundos, niveles, armas y skins accesibles. Las habilidades/equipos y mejoras empiezan sin comprar, excepto el sonar inicial. Puedes comprarlos sin límite de dinero. No da invulnerabilidad ni sube estadísticas automáticamente.

El selector de mundo y nivel de la edición de pruebas está en el menú principal. Las dos ediciones tienen guardados separados. La normal mantiene las claves de guardado anteriores; para actualizar una partida local, sustituye el HTML antiguo en su misma ubicación.

Para futuras actualizaciones, modifica el HTML principal, ejecuta `python3 scripts/build-editions.py` y distribuye **ambas** ediciones. Cada HTML funciona por sí solo. No edites las copias generadas manualmente.
