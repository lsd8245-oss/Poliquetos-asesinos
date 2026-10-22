# Poliquetos asesinos

Videojuego 2D de exploración y combate submarino. El juego completo está en **`poliquetos_asesinos_8_edicion_sonora (18).html`**: gráficos, instrumentos y sonidos están incluidos y el modo individual funciona sin internet.

## Jugar

Abre el HTML en un navegador moderno. También puedes servir la carpeta con:

```sh
python3 -m http.server 8000 --bind 127.0.0.1
```

El audio comienza después de interactuar con el juego. En **Opciones** puedes ajustar música y FX de forma independiente, escuchar temas y elegir la calidad gráfica. El modo ECO reduce partículas e iluminación; se respeta la preferencia de movimiento reducido del navegador. Las partidas individuales se guardan por sector en el navegador.

## Dirección audiovisual

- Portada ilustrada con un leviatán, arrecifes y una nave de expedición.
- Escenarios con profundidad, luz submarina y detalles propios de cada hábitat.
- Submarinos con casco metálico, cristal, propulsores y estela; criaturas con bioluminiscencia.
- Música de puerto con arpa y cristal, motivos de exploración y mezcla de combate más definida.
- Reverberación estéreo y transiciones suaves, con música y cola de reverberación controladas por el mismo volumen.

El cooperativo requiere internet y los servicios de PeerJS/WebRTC.

## Comprobar los cambios

Las pruebas usan Node.js, Playwright y Chromium; estas herramientas están disponibles en el entorno cloud preparado. No se necesitan para jugar.

```sh
node --test
```

Para otro ejecutable de Chromium, define `CHROMIUM_PATH`. Las pruebas ejecutan el juego sin recursos externos y comprueban reverberación, mezcla musical, pausa, volumen, guardado y transparencia del submarino. La instrumentación de pruebas se añade únicamente a la copia servida por el propio test.
