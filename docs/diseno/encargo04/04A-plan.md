# Plan Encargo04A — ejecución y límites

Base aceptada para continuar según instrucción actual: `pulido/w01-combate-vfx-b1`, `7dcad1c5a864305803d96aeddfeaeea8182c6a01`, árbol limpio y referencia remota comprobados. Rama `fix/w01-04a-pantalla-sonar-auras`. Único bloque autorizado:04A.

- [x] Política aislada Rellenar/aspecto/fraccional y Píxel perfecto/integer en fullscreen real; conservar ventanas×1/2/3 y640×360 lógico. Tests matemáticos, cinco escritorios virtuales, cliente/tamaño/modo4, capturas completas y restauración modo0. Navegación real con teclado en PE. Mando físico, Alt+Tab y DPI de Windows físico pendientes.
- [x] Sonar único integrado con entrada, remapeo, HUD/tutorial. Usuario aprobó Q configurable/mando configurable,12s recarga/4s revelado sin daño ni CTD. PredeterminadoY, rango320px y barrido1,2s son elecciones técnicas documentadas. Datos encombat.json y esquema. No crear anclajes físicos ficticios; señales sobre actores/peligros existentes y límites documentados.
- [x] Auras: inventario de fuente/condición/duración/significado. Insignias de botín pequeñas con PNG existentes; estados carga/bloqueo/debilidad distintos, CTD condicionado, sin IDs/hitboxes normales. Fixtures rotulados con agua clara/oscura.
- [x] Ecología: auditoría M5/tubícolas/IDs/sprites/formaciones; mapa propuesto y diseño04B/C/D, sin implementar geometría, balance, compras ni continuidad de partidas.
- [x] Suite final32PASS con render, ambos instaladores y CRC/PE/PCK/payload comprobados; ambosPE bajo Wine con40s efectivos y vídeos completos, Q/E12/4,08s/LISTO, pausa y menús. Cinco resoluciones también conPE; fixtures de ambos modos, barra de jefe y HUD en Godot; Normal/Pruebas640×360 y1920×1080.
- [x] Revisión independiente final de código/evidencia sin bloqueantes; decisiones e informe con hashes. Conservados1.781 archivos de assets idénticos y174 contratos B1 (extensión sonar acotada en dos JSON). Entrega mediante commit propio e instaladores individuales.

Windows físico, instalación/desinstalación NSIS, mando conectado y aceptación visual/jugable personal siguen pendientes. Wine no dispone del runtime32 del instalador; los payloads64 se extraen y ejecutan. No se acredita60FPS: medición aislada llvmpipe04A51,59 frente al controlB155,32; detalle en informe. La aprobación del usuario abre04B posteriormente; este plan no la concede.

Resultado verificable y comandos: [informe04A](../../verificacion/04a/README.md). Ningún código04B/C/D ni mundo2. Música, gráficos B1, especies, jefes, datos de oleadas/daño/precios, guardados y HTML legado se conservan.
