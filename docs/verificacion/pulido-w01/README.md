# Encargo03 · B1 visual W01 · entrega para revisión

**Base:** `fix/w01-export-stage-runtime`, `d31d3406f07868942bbd3f594bee78d0f12d63b7`, árbol inicialmente limpio. **Rama:** `pulido/w01-combate-vfx-b1`. El commit final es el que incorpora este informe, evidencia y los dos instaladores. La especificación aplicada es el [Encargo03 literal](../../encargos/03-pulido-jugabilidad-vfx-escenario-w01.md), complementado por la v2 completa. B2/B3/B4 y mundo2 no se implementan. Esta entrega no significa que B1 haya sido aceptado visualmente ni que el mundo1 esté terminado.

## Cambios implementados

- Proyectiles PNG animados: lanza cian aliada, orbe/espina ámbar enemiga, torpedo metálico, haz violeta y formas distintas para dirigidos/rebotes. La bomba real conserva daño/radio existentes y muestra una onda acuática, no un nuevo tipo de arma.
- FX de explosión, impacto, escudo, propulsión, fogonazo y recogida. La animación recorre todos sus cuadros dentro del TTL real. Reduce destellos atenúa también fogonazos y recogidas. Los recogibles, peligros y portadoras tienen recursos sin texto técnico.
- La nave científica se conserva. Inclinación visual al moverse, propulsor animado y reacción de escudo. Ocho skins técnicas se sustituyen por variantes cromáticas de esa nave, no por diseños genéricos con nombres.
- Las siete familias y los PNG de Pisionidae gigante y Nereidae se preservan. Las criaturas errantes usan cuatro regiones del PNG con ondulación de ±1px y fase propia; las poses de palpos/quetas existentes siguen animadas. No se alteran patrones, fases o vidas de jefes.
- Cuatro profundidades de parallax y tres sectores: pilares costeros, arcos/ruinas y estructuras de naufragio. Transiciones de3s a15/30s, sin cambiar la etapa. Algas y cadenas con fases propias; peces, burbujas, plancton y caústicas discretos. Las grandes boyas repetidas dejan de llenar el corredor. Los objetos decorativos se mantienen atenuados; el peligro activo conserva acentos cálidos.
- HUD640×24 con iconos PNG, texto bitmap y progreso/cronómetro; tarjetas semitransparentes de SONAR/CTD/DEFLECTOR indican LISTO o NO INST. según instalación real. Son equipos pasivos: no se inventan recargas o teclas que no existen. Escudo, niveles, bombas y monedas siguen leyendo el mismo estado. Barra/nombre/fase de jefe dentro de la zona segura.

## Auditoría, arte y límites de presentación

[Auditoría captura → clave → ruta → causa → sustitución](../../arte/pulido-w01/auditoria.md). Se inspeccionaron las cuatro capturas del usuario. Rojo: FX de portadoras; naranja: explosiones; gris: ítems y riesgos; diminutos códigos del HUD: imágenes provisionales de iconos. La banda central sobredimensionada de captura03 no pudo asociarse de forma concluyente con un evento del checkout: sus dimensiones no coinciden con los riesgos actuales. Esa incertidumbre se conserva, sin inventar una atribución.

[Inventario completo](../../arte/pulido-w01/inventario.md): **50 animaciones /197 PNG**, con dimensiones, cuadros y FPS. [Procedencia FX/UI](../../arte/pulido-w01/fx-fragment.json), [procedencia ambiente](../../arte/pulido-w01/environment-fragment.json), fuentes originales y scripts de preparación se conservan. No se dibujan criaturas ni escenarios con geometría de código. El atlas W01 permanece en2048×2048; MaxRects evita el desbordamiento del empaquetador por filas, con contratos de no solape e igualdad exacta de píxeles. Los otros14 atlas no se regeneran.

Los recursos están `integrated-review`, con el estado contractual `placeholder` que utiliza el manifiesto para lotes pendientes de aprobación. Eso **no significa que los recuadros planos sigan siendo el arte de B1** ni que se certifique arte final: la aceptación visual de estos nuevos PNG corresponde al usuario. No se copia arte de juegos comerciales.

La revisión del EXE detectó un defecto que los contratos iniciales no vieron: el borde de burbuja8×8 se volvía un mosaico oscuro con el tinte rojo al ampliarlo. [Captura intermedia rechazada](portadora-antes.png). Se sustituyó por un borde perla neutro32×32, centro/exterior transparentes y solo12–15% de píxeles opacos; se reconstruyeron atlas y ejecutables. [Regresión específica de alfa](portadora-alfa.log). Se conserva la procedencia de la reparación; la captura intermedia no pertenece a los instaladores finales.

## Vídeos, comparativas y capturas de esta entrega

**Vídeos continuos del EXE Windows, ventana nativa640×360, Wine10/Linux; no Windows físico.** Se graba40s efectivos de juego, además del menú/introducción/salida. La captura ffmpeg es20fps; esa frecuencia del vídeo no es una medición de FPS del motor.

| Edición | Tiempo efectivo | Scroll | Enemigos creados | Bajas | Duración vídeo | Evidencia |
|---|---:|---:|---:|---:|---:|---|
| Normal | 40.001s | 2400.08px | 22 | 14 | 49.85s | [vídeo](windows-normal/gameplay.mp4) · [00:12](windows-normal/t12.png) · [00:40](windows-normal/t40.png) · [log](windows-normal/wine.log) |
| Pruebas | 40.005s | 2400.27px | 22 | 14 | 50.00s | [vídeo](windows-pruebas/gameplay.mp4) · [00:12](windows-pruebas/t12.png) · [00:40](windows-pruebas/t40.png) · [log](windows-pruebas/wine.log) |

[Comparativa antes/después](comparativa.png): captura original del usuario y captura real de esta entrega; son escenas diferentes del mismo mundo, no una prueba de igualdad de píxeles ni de tiempos. [Hoja de estilo dentro del escenario](hoja-estilo-render.png): montaje de dos fixtures reales etiquetados, no partida humana.

Fixtures por resolución: [640×360](fixtures/sector2-640x360.png), [1280×720](fixtures/sector2-1280x720.png), [1920×1080](fixtures/sector2-1920x1080.png); [bomba](fixtures/bomba-1280x720.png), [Pisionidae gigante](fixtures/minijefe-1280x720.png), [Nereidae/barra/fase](fixtures/jefe-1280x720.png), [destellos reducidos](fixtures/destellos-reducidos-1280x720.png). Hay muestras de los tres sectores y de todos los fixtures a las tres escalas. [Payloads exactos de los EXE grabados](windows-verificacion.json).

Se revisaron las capturas finales de ambas ediciones: el borde de portadora tiene centro transparente, no quedan etiquetas W01/cajas técnicas en lo observado; el fondo cambia, las siluetas aliadas/enemigas se distinguen y el HUD conserva sus24px. La revisión cubre los recorridos/fixtures descritos; no se extiende como certificación a escenas de otros mundos o a una campaña completa.

## Pruebas, evidencia y alcance

- **28 controles nativos** en `DISPLAY=:91 python3 scripts/test-native.py --render`: incluyen25 pruebas Python, contratos JSON, activos, combate, oleadas, tienda/guardado, UI, arranque Normal/Pruebas y PCK. [Salida](suite.log), [resultados](results.json).
- Seis contratos nuevos comprueban siluetas transparentes/animación real, módulos y atlas, y174 archivos preservados:40 datos,41 audio,9 scripts funcionales y84 PNG de criaturas. La prueba de presentación comprueba inmutabilidad del proyectil, orientación/halo y último cuadro visible. [Revisión independiente](revision-independiente.md).
- **Fixtures del renderer real**, etiquetados como «FIXTURE B1 / NO PARTIDA HUMANA», a640×360/1280×720/1920×1080: tres sectores, armas, bomba, minijefe, jefe y reducción de destellos. [Registro](fixtures.log). Son composición y acceso directo de QA, no una campaña humana, ni validación completa de B2/B3.
- Los vídeos principales ejecutan el **PE Windows real** desde carpeta aislada bajo Wine10, con teclado X11 y captura ffmpeg, sin F3, invulnerabilidad, daño artificial o enemigos inyectados. Se inicia nueva partida, se mueve/dispara, se pulsa una bomba y se sale por el menú. Las trazas son lecturas reales del estado a0/5/12/15/20/30/40s; el HUD no se simula.
- El empaquetado verifica CRC NSIS, PE x64, PCK incorporado, licencias y hashes. Cada EXE grabado se compara byte a byte con el payload del instalador final. Los probes de PCK se ejecutan desde carpetas vacías con Godot Linux, separados de la prueba PE/Wine. [Distribución](distribucion.json).

Los primeros ensayos fallaron por metadatos incompletos de los módulos (corregidos sin cambiar píxeles), último cuadro FX omitido (regresión roja y corrección), y el halo visual antes descrito. Los registros se conservan. Las pruebas no se presentan como aprobación de calidad artística.

### Rendimiento y plataformas pendientes

El fixture de estrés sintético, separado de las grabaciones reales, de50 enemigos,200 balas enemigas y64 aliadas se mide con OpenGL por software **llvmpipe en Linux**,220 cuadros, disparo activo. Medición aislada final: **46.63FPS**, media **21.44ms**, p95 **29.76ms** ([datos](rendimiento.json), [log](rendimiento-aislado.log)). La medición de la suite bajo NSIS se conserva en `performance.log`; no se sustituye por esta sin explicar las condiciones. El objetivo60FPS **no se da por alcanzado** en este equipo; las condiciones/cifras exactas se conservan y no se atribuyen a Windows físico. Se evita cambiar la transformación de canvas en los disparos rectos para conservar agrupación de dibujo. Las mediciones bajo compresión NSIS varían y no se presentan como benchmark de una GPU Windows.

**Pendiente:** instalación/desinstalación y partida en Windows10/11 físico, mando físico, rendimiento del PC del usuario y aprobación visual/jugable. El Wine64 disponible no puede ejecutar NSIS32; las grabaciones son del EXE exportado, no de una instalación completada. Los instaladores no llevan firma digital. No se han creado/modificado canciones; la grabación usa audio Dummy, por lo que no acredita salida sonora en Windows.

Quedan para B2/B3/B4 los recorridos completos de oleadas, encuentros, recompensas/tienda/guardados y su aceptación específica. El acabado futuro de otras skins como diseños propios y de mundos2–14 no se presenta como parte de B1. No se ejecuta el siguiente bloque hasta recibir autorización.

## Archivos de código cambiados

| Ruta | Motivo |
|---|---|
| `src/core/main.gd` | Integra la presentación, ordena nave/balas/FX/HUD, mantiene contraste/barras, extiende la traza opcional hasta40s. |
| `src/core/assets.gd` | Consulta duración/cuadros de animación y compone regiones PNG para articulación; mantiene carga desde recursos compilados. |
| `src/visuals/combat_presentation.gd` | Estado estrictamente visual: banco, fogonazo, impactos y recogida, sin escribir en la simulación. |
| `src/visuals/w01_environment.gd` | Parallax modular y animación ambiental; solo lee scroll/tiempo. |
| `scripts/merge-b1-art.py` | Integra fragmentos y empaqueta exclusivamente atlasW01, sin generar dibujos ni placeholders. |
| `scripts/qa-exported-windows.py` | Extiende captura40s y muestras, usa WASD/X/Z y configura solo preferencias del prefijo QA. |
| `native-tests/b1_presentation_test.gd`, `test_b1_visual_contracts.py`, `carrier_alpha_probe.py`, `b1_visual.gd` | Regresiones de presentación/recursos, preservación y fixtures visuales etiquetados. |
| `native-tests/test_assets.py` | Mantiene contrato de los4tiles y distingue los nuevos módulos transparentes, comprobados aparte. |

No hay cambios en `src/core/game.gd`, armas, etapas, tienda, guardados, audio, patrones ni JSON de diseño. Los PNG/manifiesto/atlas e instaladores cambiados corresponden al lote y al empaquetado descritos; las imágenes de documentación no son recursos de producción.

## Instalar y reproducir

Descargar individualmente `entregas/Poliquetos-Normal-Instalar.exe` y `entregas/Poliquetos-Pruebas-Instalar.exe`; hashes en [SHA256.json](../../../entregas/SHA256.json). Cada edición instala en su directorio y conserva sus guardados separados. Abrir → Nueva partida → dificultad → ranura libre. WASD/flechas, Z/Espacio para disparar, X para bomba, Esc/P para pausa. Verificar primera oleada a00:10, cronómetro/progreso, siluetas de balas, efectos, tres sectores durante30s y ausencia de rótulos técnicos. Pruebas conserva selector y dinero de pruebas con compras pendientes.

Para QA en este entorno:

```sh
python3 scripts/test-native.py
DISPLAY=:91 python3 scripts/test-native.py --render
python3 native-tests/carrier_alpha_probe.py
python3 scripts/merge-b1-art.py
python3 scripts/build-native.py --templates-dir /ruta/templates --makensis /ruta/makensis --linux-check
python3 scripts/verify-distribution.py --sevenzip /ruta/7z
python3 scripts/qa-exported-windows.py --exe /ruta/Poliquetos-Normal.exe --wine /ruta/wine64 --prefix /ruta/prefijo-qa --output /ruta/evidencia --seconds 40 --scale 1
```

Repetir la última línea con Pruebas. El prefijo QA es aislado e inicializado antes, sin partidas del usuario. La herramienta solo configura escala, desactiva autodisparo/F3 y manda teclas; no altera combate ni estado de campaña. Las fuentes/procesamiento son reproducibles mediante los scripts de `docs/arte/pulido-w01/`; regenerar el atlas con el merge de fragmentos, nunca con `--force-placeholders`.

**Puerta de aceptación:** revisar vídeos, capturas y ambas ediciones en el PC del usuario. Solo después de aprobar B1 se podrá autorizar B2; la entrega no autoriza avanzar automáticamente.
