# Encargo04A — entrega para revisión

Implementación acotada en `fix/w01-04a-pantalla-sonar-auras`, desde **7dcad1c5a864305803d96aeddfeaeea8182c6a01** (`pulido/w01-combate-vfx-b1`). Se verificaron rama, árbol limpio y referencia remota antes de comenzar; la referencia remota seguía en ese commit al finalizar las pruebas. La instrucción actual acepta esa base para continuar, sin declarar cumplidos retrospectivamente sus criterios pendientes.

**04A queda entregado para revisión personal del usuario. 04B/C/D y mundo2 no se han programado. W01 no se declara terminado.** La revisión independiente final no encontró bloqueantes en el código ni en la evidencia examinada; la aprobación visual/jugable del usuario sigue pendiente.

## Descargas individuales

- [Instalador Windows Normal](../../../entregas/Poliquetos-Normal-Instalar.exe).
- [Instalador Windows Pruebas](../../../entregas/Poliquetos-Pruebas-Instalar.exe).
- [Vídeo Normal, escritorio completo1366×768](windows-normal/gameplay.mp4),76,75s.
- [Vídeo Pruebas, escritorio completo1920×1080](windows-pruebas/gameplay.mp4),77,70s.
- [SHA-256 de instaladores](../../../entregas/SHA256.json) y [payloads/CRC/PE/PCK](distribucion.json).

Los vídeos muestran **el PE Windows extraído de cada instalador final y ejecutado bajo Wine10/Linux**, con teclado real del sistema, sin invulnerabilidad, F3 ni inyección de etapa/tiempo/vida. No son vídeo del editor ni una simulación headless. Están grabados a20fps, H264, sin recorte ni escalado posterior y **sin pista de audio**: el driver de QA es Dummy, la música del juego no se cambió. La frecuencia de grabación no mide los FPS del juego.

| Entrega | Bytes | SHA-256 |
|---|---:|---|
| Normal | 29698179 | `2f920e3c408cd171b13cc96c49f33d406e75b8b1e0a6687b8d5f8b16598485b4` |
| Pruebas | 29699095 | `75057a26d8a6f5cf6b409cecd99c9d8bb3abb0075f4f829a9742f985f39cbbee` |

Instaladores NSIS existentes, sin firma digital. Se verifican estructura, CRC, licencias, pack y correspondencia exacta con lo ejecutado. **No se acredita instalación/desinstalación Windows física.** El intento silencioso en el Wine disponible falla por ausencia del runtime32 necesario para NSIS; [resultado](installer-wine.json) y logs `installer-wine-*.log`. Se ejecutó directamente el payload extraído, sin presentar eso como instalación completada.

## Cambios y conservación

1. **Pantalla:** `display_policy.gd` conserva640×360 lógico, arena640×336 y HUD24. Opciones accesibles: Ventana×1/×2/×3, Rellenar pantalla (aspecto fijo, escala fraccional), Píxel perfecto (escala entera). Ambos fullscreen solicitan modo exclusivo4; al volver se restauran modo0, bordes y tamaño. Una ventana solicitada demasiado grande se reduce al entero que cabe, mostrando el ajuste. Preferencia anterior `fullscreen` compatible en memoria, sin migración de partidas. Menús rellenan el pie lógico con el PNG de HUD B1 existente.
2. **Sonar:** una implementación informativa; propiedad inicial preservada en ambas ediciones. Usuario aprobó Q/configurable,12s recarga,4s revelado. MandoY predeterminado y configurable. Datos y esquema añaden solo `sonar`; rango320px, expansión1,2s. Pulso animado PNG, HUD con tecla actual/LISTO/08s/NO INST., Controles, tutorial y primera explicación. Pausa/reanudación congelan sus timers; reintentar reinicia solo estado transitorio. No causa daño ni sustituye CTD. [Contrato y límites](../../diseno/encargo04/sonar.md).
3. **Señales:** se quita el aro permanente de portadora. Insignias pequeñas TIRO/MISIL/BOMBA indican pertenencia a grupo con recompensa. Carga, bloqueo y debilidad CTD tienen semánticas distintas. Reducir destellos conserva señales con menor intensidad. [Inventario](../../diseno/encargo04/auras.md).
4. **Ecología y futuro:** auditoría deHydroides/Fabriciidae, M5, formaciones y soportes ausentes. Mapa propuesto de23 anclajes (22 regulares+1 escolta), sin recolocar actores ni crear sólidos en04A. [Auditoría/mapa](../../diseno/encargo04/ecologia-y-anclajes.md) y [diseño04B/C/D](../../diseno/encargo04/siguientes-bloques.md).

Archivos de producción modificados: `src/core/main.gd`, nuevos `src/equipment/sonar.gd`, `src/visuals/display_policy.gd`, `src/visuals/state_indicators.gd`; extensión aditiva de `data/combat.json` y su esquema. Se añaden tests, harness de QA y documentación. El documento adjunto se conserva literalmente en `docs/encargos/04-diagnostico-espacial-ecologia-dificultad-w01.md`; cuatro JPG originales en `docs/evidencias/encargo04/`.

**1.781 archivos de assets idénticos byte a byte a B1**, incluidos PNG, atlas, manifiesto y audio: [inventario SHA-256](assets-preservados.json). No se crea ningún asset nuevo ni se promueven los existentes a `final`: mantienen su estado `integrated-review`/`placeholder` original. No se presentan como arte final aprobado.

El contrato B1 mantiene sus174 archivos protegidos:172 siguen congelados exactamente; los dos JSON que admiten la nueva sección sonar se comparan con copias de la base cuyo hash original también se exige. Se sustrae únicamente la extensión sonar autorizada y se exige igualdad del resto. No se cambia el conjunto de40 archivos de datos ni se flexibilizan otras reglas. `game.gd`, oleadas, especies, jefes, armas, patrones, tienda, serializador, economía, música y HTML legado permanecen intactos. Los guardados/preferencias separados de Normal/Pruebas conservan su servicio existente.

## Pruebas ejecutadas

`DISPLAY=:91 python3 scripts/test-native.py --render`: **32 controles aprobados**, incluidas25 pruebas Python, esquemas, sistemas existentes, arranque Normal/Pruebas, probes exportados, salidas, visual y benchmark. [Resultados](tests/results.json), [resumen](suite.log) y logs individuales en [tests](tests/).

Nuevas regresiones:83 comprobaciones de política/ajustes de pantalla; Q/E/Y y disposición de Controles; persistencia de remapeo; recarga12/4, no repetición durante cooldown, pausa y reinicio; comparación de20s de combate real contra control con igual RNG sin mutación de daño/spawn; estados de botín/carga/CTD, exposición, bloqueo, reducción de destellos y reloj congelado. El evento Y sintético **no certifica mando físico**.

Construcción: `python3 scripts/build-native.py --templates-dir /workspace/godot-templates --makensis /workspace/tools/nsis/usr/bin/makensis --linux-check`. [Log](build.log). Verificación: `python3 scripts/verify-distribution.py --sevenzip /workspace/tools/7zip/usr/lib/7zip/7z`. CRC NSIS, payload exacto, PE x64/PCK y licencias aprobados para ambos; arranque y simulación20s del pack desde carpeta vacía. Además ambos PE ejecutaron `--headless -- --verify-export` **con Wine**, logs `verify-pe-*.log`; no confundir ese inicio con instalación ni revisión visual.

### Juego real de los PE finales

Harness reproducible: `python3 scripts/qa-04a-windows.py --exe RUTA_AL_PAYLOAD --output CARPETA --prefix PREFIJO_QA`. Usa preferencias aisladas, nueva campaña real, movimiento WASD, disparoZ, menús con flechas/Enter/Escape y Q/E; sin atajos de prueba que alteren combate. El prefijo requiere Wine64 funcional y `DISPLAY`; el cache se mantiene fuera de docs. `--display-only` comprueba únicamente menús/pantalla y no reclama validar una partida.

| Edición | Tiempo real de etapa | Scroll | Generados / bajas | Sonar Q →08s →LISTO →E |
|---|---:|---:|---:|---|
| Normal | 40,001s | 2400,08px | 22 /13 | 16,718 →20,719 →28,726 →31,245s |
| Pruebas | 40,005s | 2400,30px | 22 /13 | 16,676 →20,684 →28,677 →30,785s |

Cada activación registra12s/4s, `informational_only=true`, CTD no instalado. El HUD cambia a E al remapear y el archivo de preferencias confirma69. Se rechaza Q durante la recarga. Se observan disparos enemigos, proyectiles aliados y muerte de enemigos sin aumentar estadísticas; la nave recibe daño. Las duraciones wall-clock incluyen menús y pausa; los40s corresponden al reloj de etapa efectivo.

[Reporte Normal](windows-normal/report.json), [Pruebas](windows-pruebas/report.json), logs completos, capturas y metadatos MP4 en sus carpetas. La decodificación de todos los fotogramas se comprueba en `video-decode.json`. Se revisaron capturas reales de opciones, pulso Q/E,08s, grupos y HUD, además de fotogramas decodificados del vídeo. Las trazas observan estado; no cambian el juego.

### Pantalla y revisión visual

Los cinco escritorios virtuales se probaron también **con el PE Windows**: Normal1366×768, Pruebas1920×1080 y matriz adicionalNormal a1600×900,2560×1440 y1920×1200. Modo real4 en rellenar/píxel, cliente igual a pantalla y origen0,0, viewport640×360, sin recorte; volver a ventana×2 da modo0 y cliente1280×720. Se registran decoración, área utilizable, DPI y transform real. [Matriz adicional Windows](windows-matriz/).

| Escritorio virtual | Contenido Rellenar | Contenido Píxel perfecto | Márgenes píxel L/T/R/B |
|---|---|---|---|
| 1366×768 | 1365×768 | 1280×720 | 43/24/43/24 |
| 1600×900 | 1600×900 | 1280×720 | 160/90/160/90 |
| 1920×1080 | 1920×1080 | 1920×1080 | 0/0/0/0 |
| 2560×1440 | 2560×1440 | 2560×1440 | 0/0/0/0 |
| 1920×1200 | 1920×1080 | 1920×1080 | 0/60/0/60 |

A1366 hay1px residual a la izquierda en rellenar por redondeo. A16:10 se conservan60px arriba/abajo para evitar deformar/recortar; no se promete eliminar barras en todos los aspectos. Píxel perfecto sacrifica superficie para uniformidad de bloques; rellenar puede alternar bloques físicos2/3px en escala fraccional, siempre nearest.

[Matriz Godot/X11](matriz-x11/) añade en cada una de esas resoluciones8 capturas **del escritorio completo**, estados comparativos sobre agua clara/oscura, sonar sin CTD, recarga, ventana restaurada y barra deNereidae/HUD enteros. Imágenes `viewport-640/`: lecturas adicionales640×360 del viewport, no recortes sustitutos del escritorio. [Edición Pruebas](matriz-x11/edicion-pruebas/1920x1080/) se ejecuta por separado con `--pruebas` y aporta también ambos tamaños. Los fixtures están rotulados: las flags de exposición/carga se preparan solo para comparar presentación; **no añaden puntos débiles a Euphrosine ni son evidencia de balance jugado**.

El probe reforzado detectó un falso fullscreen cuando X11 carecía de gestor de ventanas: modo declarado y tamaño real diferían. Se preparó Openbox únicamente en el entorno de QA y se exigieron ambas condiciones; no se añadió un parche de X11 al juego. [Probe final](display-probe-x11.log). Cada matriz registra dimensiones reales virtuales, no modelos matemáticos presentados como monitores físicos. VSync no soportado es aviso del renderer del entorno.

### Rendimiento y límites

La suite se ejecutó mientras NSIS comprimía y midió22,92FPS en llvmpipe: [medición original](rendimiento-con-empaquetado.json). No se descarta ni se usa para atribuir una regresión al juego. Se repitió **solo el benchmark**, sin otras aplicaciones/compresión/grabación, usando el mismo test y opciones×2; control con `main.gd` original7dcad1c y resto de sistemas/arte iguales: [B1](rendimiento-b1-control.json)55,32FPS/18,08ms/p95 25,07ms; [04A](rendimiento-04a-aislado.json)51,59FPS/19,38ms/p95 27,52ms. Carga50 enemigos/200 balas enemigas/64 aliadas,220frames. Son observaciones cortas del renderer por software, no una distribución estadística ni certificación de60FPS. El coste observado sigue pendiente de rendimiento04D y equipo objetivo; no se atribuye esa diferencia a una causa no medida.

**Pendientes explícitos:** Windows físico, instalación/desinstalación real, escalado DPI de Windows, varios monitores, Alt+Tab/cambio de resolución en una sesión Windows física, barra de tareas Windows y mando conectado. Wine informa96DPI/escala1; en fullscreen no hay decoraciones del juego, pero el escritorio de QA no tiene una barra de tareas Windows. Las pruebas de tamaño/resize no sustituyen esas comprobaciones. Fullscreen se solicita al SO mediante Godot, sin interceptar Alt+Tab.

## Revisión del usuario y siguiente bloque

Instalar cada `.exe` en Windows; Normal y Pruebas usan directorios/configuración/partidas independientes. Abrir Opciones con flechas/Enter o mando y alternar pantalla; comprobar título/barra de tareas y Alt+Tab en el equipo destino. IniciarW01, mover conWASD/flechas, dispararZ, activarQ: pulso,12s→08s→LISTO. Cambiar aE en Controles y repetir; activar Reducir destellos. Confirmar que CTD sigue pendiente de compra y quePruebas tiene créditos ilimitados sin invulnerabilidad. Desinstalar conserva las partidas según el script NSIS existente; su ejecución real está pendiente.

Antes de04B: aprobación personal04A y autorización expresa. El [diseño siguiente](../../diseno/encargo04/siguientes-bloques.md) prioriza soportes del suelo/techo unidos al mundo, colliders que sigan el borde PNG, ruta navegable, pausa/reintento y continuidad de checkpoint. Faltan piezas originales de roca/casco/suelo/techo/esquinas, caras de montaje, compuerta animada y metadata pie/boca/orientación; se conservará todo el arte B1. Resolver primero la escolta efectiva, la arena frente aFabriciidae162s y qué mide la duración180 frente al reloj congelado170. Ninguna propuesta se implementó en04A.
