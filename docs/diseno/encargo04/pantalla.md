# Pantalla 04A

La política aislada `src/visuals/display_policy.gd` conserva un viewport de **640×360** (combate 640×336 y HUD 640×24). Solo cambia su presentación. No cambia cámara, geometría, posiciones, hitboxes ni datos de combate. El encargo 04 §2.1 autoriza el ajuste fraccional como opción preferida aunque el spec original solo contemplase escala entera.

`Ventana x1/x2/x3` mantiene escalas enteras. `Rellenar pantalla` solicita `Window.MODE_EXCLUSIVE_FULLSCREEN`, escala fraccional y aspecto `KEEP`. `Píxel perfecto` solicita el mismo fullscreen real con escala entera. La preferencia antigua `fullscreen` se interpreta como `fullscreen_fill` en memoria; no se migran partidas. Las dos variantes usan `CONTENT_SCALE_MODE_VIEWPORT`, factor interno 1 y resolución lógica fija. Godot recalcula la presentación al redimensionar o cambiar DPI/resolución; no hace falta cambiar dimensiones del combate.

Rellenar conserva toda la imagen sin deformación deliberada ni recorte de amenazas/HUD. La rasterización puede dejar un píxel residual por redondeo: 1366×768 presenta contenido 1365×768 y un píxel de margen. En 16:10 y ultrawide se conservan barras para mantener proporción. Nearest conserva los colores; una escala fraccional produce bloques físicos de anchura alternante, por ejemplo 2/3 píxeles a ×2,5. **Píxel perfecto sacrifica superficie de pantalla para conservar bloques uniformes enteros**, por ejemplo contenido 1280×720 en 1600×900.

| Superficie física | Rellenar: contenido / escala | Píxel perfecto: contenido / escala | Barras píxel perfecto izquierda/arriba/derecha/abajo |
|---|---|---|---|
| 1920×1080 | 1920×1080 / ×3 | 1920×1080 / ×3 | 0/0/0/0 |
| 1366×768 | 1365×768 / ≈×2,133 | 1280×720 / ×2 | 43/24/43/24 |
| 2560×1440 | 2560×1440 / ×4 | 2560×1440 / ×4 | 0/0/0/0 |
| 1600×900 | 1600×900 / ×2,5 | 1280×720 / ×2 | 160/90/160/90 |
| 1920×1200 | 1920×1080 / ×3 | 1920×1080 / ×3 | 0/60/0/60 |
| Ventana maximizada 1918×1078 | 1916×1078 / ≈×2,994 | 1280×720 / ×2 | 319/179/319/179 |

La captura del usuario mide aproximadamente1918×990 de cliente maximizado: con escala entera solo cabe×2. No informa su DPI ni certifica la resolución física del monitor. La última fila reproduce el mismo mecanismo con un cliente distinto,1918×1078, mediante cálculo y redimensionamiento real: una ventana decorada apenas inferior a1920×1080 cae de×3 a×2. Maximizar no equivale a pantalla completa. La implementación solicita fullscreen exclusivo sin título/barra de tareas y, al restaurar una ventana, vuelve a `MODE_WINDOWED`, repone bordes y tamaño seleccionado, y la centra en el área utilizable del monitor. No se impide Alt+Tab ni se atrapa el foco.

La escala de ventana solicitada se reduce al mayor entero que cabe contando las decoraciones que el sistema puede medir, mínimo ×1: `Ventana x3` pasa a ×2 en un monitor 1366×768 o un escritorio 1920×1080 con área utilizable 1920×1040. En 2560×1440 mantiene ×3; nunca agranda una opción ×1. La opción elegida permanece disponible; las métricas `requested_window_scale`, `effective_window_scale` y `window_adjusted` explican el ajuste. El helper puro `fit_window_size(requested_size: Vector2i, usable_size: Vector2i, decoration_size: Vector2i = Vector2i.ZERO) -> Vector2i` cubre estos casos. Las medidas de decoración pueden ser cero si el sistema no las informa; no se inventa un grosor de marco Windows.

API: `modes()`, `normalize(mode)`, `label(mode)`, `apply(window, mode)`, `content_metrics(window_size, mode)` y `metrics(window, mode)`. Los dos últimos devuelven diccionarios serializables a JSON. `metrics` registra backend, modo real de DisplayServer, dimensiones físicas cliente/con decoraciones, pantalla/área utilizable, DPI/escala de pantalla, dimensiones del viewport, configuración de escalado y transformación observada. `bars` expresa izquierda/arriba/derecha/abajo; `scale_xy` recoge el pequeño redondeo físico por eje. `observed_scale` y `observed_origin` proceden del transform real de Godot. Las métricas de pantalla requieren ejecutarse después de que el sistema procese el cambio de modo. En headless solo se informan propiedades disponibles; no se inventan DPI o pantalla física.

Comprobación del módulo: RED inicial sin política y RED específico de métricas observadas; después **83 comprobaciones headless aprobadas**, incluidos ajuste al área utilizable, decoraciones y métricas del ajuste. `native-tests/display_policy_probe.gd` ejecutó en Godot 4.6.3/X11 la secuencia ventana ×1/×2/×3 → fullscreen exclusivo rellenar → fullscreen exclusivo píxel → ventana ×2, con modo real 4 en ambos fullscreens y 0 al restaurar. Luego redimensionó el cliente a 1918×1078, 1366×768, 1600×900 y 1920×1200, comprobando que origen y escala reales coinciden con el cálculo y que el viewport sigue siendo 640×360. Resoluciones 2560×1440 cubiertas matemáticamente; el probe no las presenta como monitor físico.

Comandos reproducibles, usando directorios XDG con permisos de escritura:

```sh
XDG_DATA_HOME=/tmp/04a-display-data XDG_CONFIG_HOME=/tmp/04a-display-config XDG_CACHE_HOME=/tmp/04a-display-cache godot --headless --path . --script native-tests/display_policy_test.gd
DISPLAY=:91 XDG_DATA_HOME=/tmp/04a-display-data XDG_CONFIG_HOME=/tmp/04a-display-config XDG_CACHE_HOME=/tmp/04a-display-cache godot --path . --audio-driver Dummy --rendering-method gl_compatibility --script native-tests/display_policy_probe.gd
```

Registros iniciales del módulo: [headless](../../evidencias/encargo04/display-policy/headless.log) y [probe inicial](../../evidencias/encargo04/display-policy/probe-x11.log). La integración añadió una aserción sobre tamaño físico, además del modo4: en X11 sin gestor de ventanas se reproducía un falso fullscreen de640×360. La solución del entorno fue ejecutar Openbox local sobre el Xorg dummy, **sin añadir un workaround de X11 al juego Windows**. El [probe final](../../verificacion/04a/display-probe-x11.log) comprueba modo4 y cliente del tamaño del monitor, y la [matriz final](../../verificacion/04a/matriz-x11/) contiene capturas del escritorio completo y métricas a las cinco resoluciones, incluida2560×1440 y16:10. Las imágenes `viewport-640/` son lecturas adicionales del viewport lógico, sin recortar ni reemplazar las capturas del monitor.

Los fixtures de auras y jefe están rotulados como fixtures; no son partidas. El informe [04A](../../verificacion/04a/README.md) distingue estas pruebas de los vídeos de ambos PE Windows con entrada real del teclado bajo Wine. Pantallas y DPI son los informados por el escritorio virtual; Openbox no proporciona una barra de tareas Windows. VSync no soportado por el driver es un aviso del entorno. **Windows físico, sus escalados DPI/Alt+Tab/barra de tareas, mando físico e instalación/desinstalación siguen pendientes**; ninguna captura Linux/Wine los certifica.
