# Integración artística del mundo 1 — Godot / Windows

Base: `arte/piloto-godot-w01` / `d6beb99`. Rama de trabajo: `arte/integracion-godot-w01`. El usuario aceptó la dirección visual del piloto, confirmó el catálogo completo W01 y autorizó continuar. Es un lote artístico jugable **en revisión**, no una aprobación final de la fase10 ni del mundo1 completo.

## Qué se puede probar

Los dos instaladores actualizados están en `entregas/Poliquetos-Normal-Instalar.exe` y `entregas/Poliquetos-Pruebas-Instalar.exe`. Mantienen sus rutas de instalación y `user://` independientes. Normal conserva progresión y compras; Pruebas conserva selector/accesos y dinero ilimitado para comprar, sin estadísticas ni invulnerabilidad automáticas. No se cambiaron datos de combate, patrones, oleadas, economía, guardados ni archivos de sonido. Los HTML siguen intactos como legado.

Se integra la nave científica (y la variante industrial para Batiscafo amarillo), cuatro capas superficiales luminosas de1280×336 y una portada ilustrada con menú funcional. El resto de skins conserva sus recursos anteriores. El dibujo respeta el tamaño real de los actores:

| Tipo | ID nativo | Tamaño del PNG y actor |
|---|---|---|
| Serpulidae (Hydroides), único | `hydroides` | 48×48 |
| Euphrosinidae (Euphrosine), único | `euphrosine` | 48×48 |
| Fabriciidae, único | `fabric` | 48×48 |
| Pisionidae (Piso), único | `pision` | 32×32 |
| Lacydoniidae, único | `lacy` | 32×32 |
| Syllidae, recurrente | `syll` | 24×24 |
| Phyllodocidae, recurrente | `phyll` | 32×32 |
| Pisionidae gigante, minijefe | `mini_w01_pision` | 128×96 |
| Nereidae, jefe final | `boss_w01_nereis` | 180×120 |

Hydroides reutiliza las tres poses del piloto (cuatro posiciones en el ciclo). Los nuevos tipos tienen dos poses originales alternadas en cuatro posiciones, a8fps. Nereidae tiene PNG separados de cabeza, cuerpo y mandíbulas que reconstruyen el mismo actor, y frente/cola para las dos partes físicas de su fase3; no se cambian sus ataques, daño ni puntos débiles. Se conservan dos cuadros blancos de daño. La nave reutiliza una pose del piloto en las cuatro posiciones del ciclo; la estela existente sigue siendo provisional.

[Catálogo de PNG](catalogo.png) — hoja de arte, no captura. Fuentes originales de imagegen en `originales/`; se conservan cuatro propuestas rectas descartadas como `*_straight_reference.png`. Las poses finales curvadas evitan franjas excesivas de colisión vacía, manteniendo los mismos rectángulos de combate.

## Capturas reales del render nativo

Proceden de Godot4.6.3 en Linux/X11 con llvmpipe. Son escenas de prueba deterministas del motor real, **no mockups ni una partida humana completa**. Se capturó la ventana real a640×360,1280×720 y1920×1080, posicionándola dentro del monitor para evitar recortes.

- [Menú Normal640](../../verificacion/integracion-w01/normal-menu-640x360.png) / [1920](../../verificacion/integracion-w01/normal-menu-1920x1080.png).
- [Menú Pruebas1280](../../verificacion/integracion-w01/pruebas-menu-1280x720.png).
- [Siete familias640](../../verificacion/integracion-w01/familias-640x360.png) / [1920](../../verificacion/integracion-w01/familias-1920x1080.png).
- [F3 y geometría640](../../verificacion/integracion-w01/f3-640x360.png).
- [Minijefe Pisionidae](../../verificacion/integracion-w01/pision-mini-640x360.png).
- [Nereidae fase1](../../verificacion/integracion-w01/nereidae-fase1-640x360.png), [fase2](../../verificacion/integracion-w01/nereidae-fase2-640x360.png), [fase3](../../verificacion/integracion-w01/nereidae-fase3-640x360.png).
- [Etapa tras20s del programador de oleadas](../../verificacion/integracion-w01/etapa-natural-20s.png): la protección contra daño se aplica únicamente en la fixture de prueba, nunca a las ediciones entregadas.

Los fixtures y registros están en `native-tests/art_w01_visual.gd` y `docs/verificacion/integracion-w01/`. Los IDs no se dibujan dentro de los nuevos sprites. Quedan elementos antiguos visibles en HUD/efectos y skins, por lo que **no se declara superado el hito de mundo1 sin placeholders**.

## Cómo repetir la preparación y validación

```sh
python3 scripts/integrate-art-w01.py
python3 scripts/test-native.py
# Con pantalla/X display disponible:
python3 scripts/test-native.py --render
```

La preparación utiliza fuentes y paletas seleccionadas, recorte, alfa binario, nearest y composición PNG mediante Pillow. No crea criaturas por primitivas ni utiliza sprites comerciales. Solo reconstruye el atlasW01. No usar `--force-placeholders` para esta integración ni regenerar otros mundos por rutina. [Procedencia por archivo](procedencia.json):100 PNG integrados en revisión, con autor/herramienta, fuente, fecha y hashes; estado de producción `placeholder`, metadata `art_stage=integrated-review`. La reducción no se presenta como pixel art final profesional; quedan refinamientos de animación y acabado para aceptación.

Pruebas ejecutadas: **25 comprobaciones nativas** con importación actualizada,19 pruebas Python, contratos, suites Godot, arranque de ambas ediciones, render y rendimiento. Pruebas adicionales de todos los botones del menú con ratón/teclado y cierre confirmado de ambas ediciones sin errores de recursos. La igualdad visible de PNG/importación tolera únicamente RGB bajo alfa0, que el importador cambia sin afectar la imagen. El dibujo por regiones evita zonas transparentes de los fondos; se comprobó una captura640×360 idéntica píxel a píxel antes/después.

[Revisión independiente y correcciones](revision-independiente.md). [Invariantes comprobadas](../../verificacion/integracion-w01/invariantes.json):95 archivos protegidos de spec, datos, legado, audio y lógica de guardado/tienda/etapas/jefes, sin diferencias. El atlas mantiene límite2048×2048 y cobertura exacta de PNG sin solapes; las pruebas comprueban también reemplazo individual y fallback al atlas.

### Rendimiento y límites de esta entrega

La medición con50 enemigos,200 balas enemigas y64 proyectiles aliados no acredita60FPS estables en este renderizador por software. Medición aislada:56,54FPS,17,69ms de media y24,53ms p95. La última suite antes de empaquetar se conserva en `performance.json`; la variación por carga del entorno no debe confundirse con hardware Windows. No se afirma superado este criterio ni la fase10.

No se ejecutó Windows real ni instalación/desinstalación en Windows, mando físico o recorrido humano90/70min. Los instaladores no llevan firma digital. La verificación de distribución comprueba estructura PE/PCK, CRC, payload, hashes y arranque del pack de cada edición con Godot Linux; **eso no equivale a probar Windows**. Canciones y audio existentes permanecen intactos.

Para probar: instala cada edición en su ruta propia. En Normal, Nueva partida → dificultad → ranura → mundo1. En Pruebas, elegir mundo/armas → mundo1 → iniciar; las mejoras siguen pendientes de compra. Revisa desplazamiento, contraste, siete familias, Pisionidae y las tres fases de Nereidae, F3, guardado/carga separado y fluidez en tu PC. El acabado de los cortes de frente/cola de Nereidae (incluidos píxeles aislados del recorte), la animación final, HUD/efectos/otras skins y el hito artístico completo siguen sujetos a revisión. No se avanza al mundo2 ni se aprueban retrospectivamente fases.
