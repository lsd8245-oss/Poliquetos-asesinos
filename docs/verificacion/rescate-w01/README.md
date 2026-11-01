# Encargo 02: corrección de simulación en exportación

## Alcance y procedencia

Base: `arte/integracion-godot-w01`, commit `9ea435b692b437deb202519076823d6fae47aac4`. Rama de entrega: `fix/w01-export-stage-runtime`. El commit final es el commit que incorpora este informe y los instaladores; sus hashes exactos están en `entregas/SHA256.json` y `distribucion.json`. Árbol inicialmente limpio. Se incorpora literalmente el [encargo](../../encargos/02-rescate-jugabilidad-y-validacion-w01.md). Solo bloque A; B1–B4 y mundo 2 no se implementan.

## Causa confirmada y corrección

En el PCK extraído del instalador anterior, `FileAccess.file_exists()` devuelve falso para los cuatro scripts `.gd`, mientras `ResourceLoader.exists/load()` los resuelve mediante los recursos compilados/remapeados. Las guardas de `PoliGame._init()` dejaban `stage_system`, `weapon_system` y `boss_system` vacíos sin error. El movimiento básico seguía funcionando, pero no se ejecutaba la simulación de etapa. A 0/5/12/20 segundos de la regresión anterior, tiempo, scroll y enemigos permanecían en cero: [registro rojo](antes-pack.log).

La misma condición afectaba `refresh_stats()`, que calculaba estadísticas de respaldo e ignoraba las compras en el exportado. Se restauró la llamada al cálculo existente `Shop.stats()`; no se modificaron sus fórmulas ni valores.

Se precargan los cuatro recursos requeridos con `preload` y se crean los tres controladores incondicionalmente. Si falta un recurso requerido, Godot informa el error de carga en lugar de continuar silenciosamente sin él. No se reemplaza FileAccess para JSON, partidas o PNG. No quedan guardas `FileAccess.file_exists(...gd)` en `src/`.

## Archivos y propósito

| Archivos | Cambio |
|---|---|
| `src/core/game.gd` | Carga obligatoria de sistemas y estadísticas existentes. |
| `src/core/main.gd` | Fortalece `--verify-export` con 20 s de simulación; `--runtime-trace` opcional registra 0/5/12/20 sin modificar estado ni HUD. Solo con ese indicador se fuerza vaciado de stdout para sincronizar capturas. |
| `native-tests/export_stage_probe.gd` | Regresión roja/verde: carga, tiempo, scroll, primera oleada a 10 s, movimiento, balas, bajas y estadísticas compradas. Solo usa movimiento/disparo para vencer enemigos. |
| `scripts/test-native.py` | Añade regresión Normal/Pruebas. |
| `scripts/build-native.py`, `scripts/verify-distribution.py` | Ejecutan pruebas del PCK desde directorios vacíos para impedir carga accidental desde el checkout. Verifican los payloads del instalador. |
| `scripts/qa-exported-windows.py` | Ejecuta el PE Windows mediante Wine, pulsa teclas con XTest, graba pantalla con ffmpeg y conserva logs, capturas y hash del EXE. No inyecta enemigos ni daño. |
| `docs/encargos/02-*`, este directorio, `docs/decisiones.md`, `docs/v2-progreso.md` | Encargo literal, plan acotado, decisiones y evidencia. |
| `entregas/*-Instalar.exe`, `entregas/SHA256.json`, `docs/verificacion/distribucion.json` | Dos instaladores NSIS reconstruidos y comprobación de distribución. |

Todos los assets, datos, audio, legado HTML, spec completo y módulos de tienda/guardado/armas/etapas/jefes permanecen idénticos: **1.764 archivos protegidos**, SHA-256 por archivo en [manifiesto](archivos-protegidos.json). No se incorporan assets nuevos; se conserva su estado artístico anterior `integrated-review`/`placeholder`.

## Pruebas y límites

| Prueba | Resultado y alcance |
|---|---|
| Regresión contra PCK antiguo | Falla como se esperaba: tres controladores vacíos, 0 s/0 px/0 enemigos y estadísticas compradas incorrectas. |
| `python3 scripts/test-native.py` | 25 controles aprobados. |
| `DISPLAY=:91 python3 scripts/test-native.py --render` | **27 controles aprobados**, incluidos contratos JSON, pruebas Python, combate, tienda/guardados, UI, render y rendimiento. [Salida completa](suite-native.log), [resultados](results.json). |
| PCK de ambos instaladores nuevos, desde carpetas vacías | Controladores presentes; primera oleada a 10.0000000000001 s, 20 s/1.200 px, movimiento >300 px, ataques y bajas reales. Igualdad con estadísticas de Shop. Logs `export-*-stage.log`. Host: Godot Linux, no Windows. |
| EXE Windows con ventana bajo Wine 10 | Teclado físico simulado mediante X11, nueva partida, movimiento, disparo, muestras 0/5/12/20 y cierre desde menú. Vídeos y capturas de las dos ediciones. Host Linux con Wine, **no Windows real**. |
| Distribución | CRC NSIS, extracción, PE x64, PCK incorporado, licencias, SHA-256 y comparación exacta con el EXE probado. [Registro](distribucion.json). |
| Windows real / instalación y desinstalación completas | **Pendiente**. No hay equipo Windows en este entorno. El NSIS PE32 no arranca con la instalación Wine64 disponible (`syswow64/ntdll.dll`, c0000135), por lo que los vídeos son del EXE exportado extraído/comparado, no de una instalación completada. No se presenta esa limitación como prueba aprobada. |
| Recorrido completo W01, 90 enemigos/minijefe/jefe/tienda; 60 s de partida Windows; mando físico | Fuera de esta corrección y/o pendientes. No se certifican B1–B4, 60 FPS, rendimiento en equipo Windows ni finalización del mundo 1. |

Los efectos y música no se modificaron. En la grabación automatizada se usa `--audio-driver Dummy` para operar sin dispositivo de audio; esa grabación no valida la salida sonora de Windows. La prueba de rendimiento del render nativo usa llvmpipe; sus valores están en `performance.log` y no acreditan hardware Windows. El HUD y los efectos previos conservan su acabado pendiente; la corrección no es un nuevo lote artístico.

La [revisión independiente](revision.md) detectó y resolvió el riesgo de cargar fuentes del checkout durante una prueba del PCK. Los primeros ensayos de captura fallaron por buffering de logs y por recorte del hijo OpenGL al redimensionar solo X11; esas capturas se descartaron. La herramienta final utiliza la preferencia de pantalla del juego en el prefijo aislado y comprueba el tamaño real. El primer control de arranque fortalecido también detectó recursos de audio pendientes al salir: se desactiva `_process` únicamente en el modo automatizado `--verify-export`, evitando consumir sonidos durante el cierre de la prueba. No afecta las partidas normales. Un ensayo adicional Pruebas ×3 registró 20 s/1.200 px/8 enemigos, pero cero bajas porque el recorrido de teclado por tiempo de pared no alineó la nave bajo la carga del render por software: [fallo conservado](ensayo-teclado-x3.log). Se prolongó únicamente la pulsación Up de la herramienta de QA hasta el límite existente y se repitió esa edición/escala; no se modificó el combate.

## Evidencia visual revisada

Grabaciones del EXE Windows extraído de cada instalador, con payload SHA-256 idéntico al publicado: [Normal — 29,70 s](normal-x2/gameplay.mp4), [Pruebas — 30,10 s](pruebas-x2/gameplay.mp4). Incluyen 20 s efectivos de simulación, menú y salida. Comparación: [EXE anterior — HUD detenido, 30,65 s](antes-wine/gameplay.mp4), [captura anterior](antes-wine/t20.png).

En cada carpeta se conservan menú y muestras 0/5/12/20, log real y report.json con hash, plataforma y duración. Se revisaron las capturas completas: HUD visible, cambios de posición de las capas del fondo, aparición de enemigos, proyectiles y desaparición al morir. Las escalas se establecen mediante la preferencia existente del juego, sin recortar la ventana. Se preserva el acabado previo del HUD y los efectos; no se certifica acabado artístico final.

| Edición/escala | Tiempo s | Scroll px | Regulares creados | Bajas | Evidencia |
|---|---:|---:|---:|---:|---|
| Normal ×1 | 20.001 | 1200.04 | 8 | 4 | [00:20](normal-x1/t20.png) · [log](normal-x1/wine.log) |
| Normal ×2 | 20.006 | 1200.35 | 8 | 4 | [00:20](normal-x2/t20.png) · [log](normal-x2/wine.log) |
| Normal ×3 | 20.008 | 1200.46 | 8 | 4 | [00:20](normal-x3/t20.png) · [log](normal-x3/wine.log) |
| Pruebas ×1 | 20.002 | 1200.11 | 8 | 4 | [00:20](pruebas-x1/t20.png) · [log](pruebas-x1/wine.log) |
| Pruebas ×2 | 20.003 | 1200.19 | 8 | 4 | [00:20](pruebas-x2/t20.png) · [log](pruebas-x2/wine.log) |
| Pruebas ×3 | 20.007 | 1200.43 | 8 | 4 | [00:20](pruebas-x3/t20.png) · [log](pruebas-x3/wine.log) |

## Reproducir

```sh
python3 scripts/test-native.py
DISPLAY=:91 python3 scripts/test-native.py --render
python3 scripts/build-native.py --templates-dir /ruta/templates --makensis /ruta/makensis --linux-check
python3 scripts/verify-distribution.py --sevenzip /ruta/7z
python3 scripts/qa-exported-windows.py --exe /ruta/Poliquetos-Normal.exe --wine /ruta/wine64 --prefix /ruta/prefijo-qa --output /ruta/evidencia-normal
```

Repetir la última orden con Pruebas; `--scale 1/2/3` captura ventanas de 640×360, 1280×720 y 1920×1080. Usar un display dedicado y prefijo QA, sin partidas del usuario. Requiere X11/XTest, Pillow y ffmpeg. El prefijo QA debe haberse inicializado abriendo el juego; la herramienta configura únicamente su escala de pantalla y desactiva disparo automático para comprobar la tecla Z, sin tocar perfiles ni estadísticas. `--legacy` registra el binario anterior sin exigir progreso; se etiqueta observación, no éxito. La plantilla release no acepta la ejecución de scripts externos: el probe GDScript se ejecuta con Godot Linux leyendo el PCK; el PE real usa su entrada normal y el indicador de diagnóstico opcional.

En Windows: descargar e instalar cada EXE individual en su directorio propio; abrir Normal → Nueva partida → Normal → ranura libre. Pruebas puede comenzar igual o usar su selector existente. Mover con WASD/flechas y disparar con Z/Espacio. Comprobar HUD 00:05/00:12/00:20, desplazamiento del fondo y Hydroides desde 00:10, balas y bajas. Las mejoras permanecen pendientes de compra y los guardados siguen separados. Desinstalar mediante su entrada de Windows conserva partidas según el instalador existente. Instaladores sin firma digital.

## Puerta de aceptación y siguiente bloque

El arreglo queda entregado para probar en el PC del usuario. **No se da por aprobada la instalación Windows ni la fase.** Tras su aceptación expresa, el siguiente trabajo será B1: verificar y perfeccionar sensación lateral, escala, legibilidad y respuesta con los sistemas existentes. Se reutilizarán la nave y las cuatro capas PNG aprobadas; cualquier pulido futuro de estela/explosiones/HUD requerirá PNG originales coherentes, sin sustituir los gráficos actuales por geometría. B1 se comprobará con entradas reales y capturas a ×1/×2/×3/pantalla completa, límites, pausa, impacto y fluidez medida. B2–B4 vendrán por separado; no se inicia mundo 2.
