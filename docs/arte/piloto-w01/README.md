# Piloto visual W01 — conceptos pendientes de aprobación

**Plataforma activa:** Godot 4.6.3 / Windows nativo. **Base:** `docs/instrucciones-redisenio-v2` / `f60abfb`, descendiente de `juego-nativo-v2` / `ac29e23`. **Rama:** `arte/piloto-godot-w01`. Conciliación documental: commit `b7212c2`. El segundo commit de esta rama contiene los conceptos y esta revisión.

El producto final futuro sigue siendo `entregas/Poliquetos-Normal-Instalar.exe` y `entregas/Poliquetos-Pruebas-Instalar.exe`, con instalación, configuración y guardados independientes. **Estos PNG no son instaladores, screenshots nuevos ni recursos de producción aprobados.** No se reconstruyeron los ejecutables existentes.

## Comparación y cuatro propuestas

[Comparativa PNG con placeholders actuales](comparativa.png). Ambos lados son composiciones estáticas hechas con PNG, identificadas como MOCKUP; no se afirma que el lado derecho esté ejecutándose en Godot.

| Propuesta | Hoja para revisar | Entregables |
|---|---|---|
| A — Nave | [Tres variantes](A_variantes.png) | Científica marfil/turquesa (recomendada), industrial ocre y expedición azul/oliva; cada una a48×24 y ampliación×8. |
| B — Hydroides | [Poses, escala y daño](B_hydroides_hoja.png) | Tres cuadros48×48: retraído, extensión y corona abierta; dos cuadros blancos de daño, [silueta](B_hydroides_silueta.png) y [paleta común](B_hydroides_paleta.png). |
| C — Superficie marina | [MOCKUP640×360](C_mockup_640x360.png) / [×3](C_mockup_1920x1080.png) | Cuatro capas1280×336, [composición](C_composicion_1280x336.png) y [hoja de empalmes](C_empalmes.png). |
| D — Portada | [MOCKUP640×360](D_portada_mockup_640x360.png) / [×3](D_portada_mockup_1920x1080.png) | [Ilustración sin texto](D_ilustracion_640x360.png), [texto independiente](D_textos_separados_640x360.png) y original de mayor resolución. |

### A — Nave

PNG nativos: [científica](A_nave_cientifica_48x24.png), [industrial](A_nave_industrial_48x24.png), [expedición](A_nave_expedicion_48x24.png). Ampliaciones: [científica×8](A_nave_cientifica_x8.png), [industrial×8](A_nave_industrial_x8.png), [expedición×8](A_nave_expedicion_x8.png).

Recomiendo la científica: casco marfil y franja turquesa conservan identidad oceanográfica y contraste sobre el agua azul. Misma silueta básica en las tres: cabina acristalada con piloto oscuro, dos propulsores traseros, faros y cañón a derecha. Encuadre48×24, centro visual24,12; la hitbox10×6 y los controles se conservan en el juego, sin alteración. La silueta del tripulante queda simplificada a pocos píxeles en la prueba nativa: su detalle se aprecia mejor en el [original conceptual](originales/A_naves.png). Se requiere aprobación de esa lectura a escala real antes de producción.

### B — Hydroides: dato real y propuesta

Se verificaron los datos: `data/enemies.json` lo clasifica **mediano48×48**; `src/stages/stages.gd` crea el actor con ese tamaño y `src/core/assets.gd` estira su textura al rectángulo del actor. El manifiesto/PNG provisional actual mide32×32. Este piloto presenta48×48 para el actor real y registra la discrepancia, **sin editar datos, manifiesto, código ni colisiones**.

El tubo calcáreo sigue visible durante retracción y despliegue; la corona radiolar coral, el opérculo y las estrías lo distinguen de una lombriz errante. Los tres bocetos comparten16 colores y base en y46. Propuesta de secuencia01→02→03→02 a8fps, sin integración. Dos cuadros de impacto blancos mantienen el spec. El cuarto dibujo de la fuente generada se descartó por tocar el borde derecho: solo se entregan tres poses completas.

La preparación inicial producía un tubo salmón en la tercera pose. La revisión lo corrigió con una rampa común marfil/coral. Quedan por retocar a mano las microformas del contorno y comprobar el ciclo animado real, la apertura y el anclaje dentro de Godot después de aprobar el estilo. No se cambian M5/F3, cadencias ni estados de combate.

### C — Cuatro capas independientes

1. [Agua y luz lejanas](C_capa_01_1280x336.png), velocidad relativa propuesta0,1.
2. [Cascos y puerto lejanos](C_capa_02_1280x336.png), 0,3.
3. [Corrientes, peces lejanos y estructuras](C_capa_03_1280x336.png), 0,6.
4. [Boyas, cadena y espuma](C_capa_04_1280x336.png), 1,0.

Cada PNG tiene1280×336: primera mitad derivada del concepto y segunda reflejada horizontalmente para asegurar continuidad de los bordes sin inventar nuevas ilustraciones por código. Se comprobó igualdad píxel a píxel del borde de repetición y de la unión central, y se inspeccionó la hoja de empalmes. La simetría se aprecia en la pareja de boyas: es una solución de boceto, no un acabado artístico definitivo. El refinado de repetición menos simétrica queda para producción aprobada.

La maqueta reserva los24px inferiores, mantiene la nave a48×24 y los actores a48×48. Proyectiles amarillos: PNG ya existente del repositorio, solo para comprobar contraste. Boyas y estructuras del concepto son ilustración estática, no nuevos obstáculos implementados. Se conserva luminosidad celeste/turquesa y espacio central; la legibilidad deberá reevaluarse en movimiento con combates reales durante la futura integración.

### D — Portada ilustrada

La ilustración ocupa todo el fondo: tripulante en nave frente a una horda monstruosa de poliquetos, ráfagas, burbujas y luz superficial. El logo y las cinco opciones del spec se componen por separado con la fuente bitmap existente; el panel izquierdo contiene el texto y deja la acción a derecha y abajo. Son píxeles estáticos: los botones no funcionan. La imagen fuente es **ilustración conceptual generada**, más detallada que los bocetos de sprites; su reducción no se declara pixel art final. Requiere una posterior pasada artística que armonice densidad, contorno y color con el juego.

## Procedencia, estado y reproducción

Imagegen produjo7 imágenes originales para este encargo. Se conservaron en `originales/` sin sustituirlas por versiones editadas. No se importaron gráficos de juegos comerciales. [procedencia.json](procedencia.json) registra herramienta, fecha, usos, tamaño, alfa, paleta y hashes de cada PNG. Preparación posterior: recortes seleccionados, alfa binario, paletas, contorno exterior, nearest-neighbor, reflejo de capas, composición y tipografía mediante Pillow. No se dibujaron animales o vehículos con primitivas ni SVG.

**39 PNG de concepto/no aprobado** (7 fuentes y32 derivados/hojas). **0 recursos finales aprobados o integrados**. Producción permanece en557 entradas `placeholder`, sin cambios. Las hojas contienen tipografía de presentación; los bocetos de sprites tienen hasta16 colores opacos, alfa binario y ampliaciones×8 verificadas. Reducir/cuantiﬁcar automáticamente no garantiza pixel art profesional: se revisaron encuadres, paletas, anatomía, siluetas y composición, pero falta el trabajo de acabado y animación en ejecución.

Desde la raíz, con las dependencias de desarrollo instaladas y DejaVu Sans disponible para las etiquetas de las hojas:

```sh
python3 docs/arte/piloto-w01/preparar.py
python3 docs/arte/piloto-w01/verificar.py
python3 scripts/test-native.py
```

[Validación de PNG](verificacion-png.json):39 archivos decodificados; dimensiones, alfa, paletas, ampliaciones, base alineada, dos cuadros de daño y empalmes comprobados. [Pruebas nativas del piloto](../../verificacion/piloto-w01/conceptos/native-run.log):19 comprobaciones aprobadas (incluyen15 pruebas Python, contratos, suites Godot y arranque headless de Normal/Pruebas). Se ejecutaron también tras la conciliación documental, con [registros separados](../../verificacion/piloto-w01/documentacion/results.json).

Se revisaron las hojas A/B, la comparativa, los empalmes y las maquetas C/D a640×360 y1920×1080. Son PNG revisados, **no validación visual del juego ejecutado**. Sin `DISPLAY`; `xdpyinfo -display :0` no pudo abrir pantalla, por lo que no se ejecutó `--render`. Windows, instalación/desinstalación, firma, mando físico, FPS y partida humana completa **no comprobados en este encargo**. No se copiaron registros antiguos de rendimiento/render como evidencia nueva.

## Aprobaciones pendientes

- Elegir nave científica (recomendada), industrial o expedición y confirmar su lectura a48×24.
- Aprobar o corregir anatomía, corona y paleta de Hydroides a48×48.
- Aprobar luminosidad/composición del mundo1; decidir si se mantiene la boya y ajustar la simetría antes de arte final.
- Aprobar composición y tono de la portada; confirmar su posterior adaptación al estilo de píxel del juego.

**No integrar ni avanzar al mundo2 hasta aprobación explícita.** La próxima tarea autorizable sería el acabado e integración de recursos W01 en Godot con capturas reales, F3, parallax y pruebas de legibilidad a640×360,1280×720 y1920×1080. Jefe Nereidae y otros poliquetos del mundo1 vendrán después, según el encargo. Este piloto no acepta retrospectivamente fases1–10.
