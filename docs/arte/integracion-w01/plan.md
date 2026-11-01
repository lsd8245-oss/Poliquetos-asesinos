# Integración artística W01 — plan y alcance autorizado

Base `arte/piloto-godot-w01` / `d6beb99`. El usuario acepta la dirección del piloto, confirma el catálogo del mundo1 y pide «OK entonces prosigue». Rama `arte/integracion-godot-w01`. Un único lote artístico; no una nueva fase de mecánicas ni una aceptación retrospectiva de fases1–10.

## Diseño aplicado

Godot4.6.3, Windows nativo. Nave científica marfil/turquesa elegida como recomendación del piloto; resolución640×360 con HUD24, nearest/integer. Fondo superficial luminoso y portada ilustrada. Siete familias: Hydroides, Euphrosine, Fabriciidae, Pisionidae, Lacydoniidae, Syllidae y Phyllodocidae. Minijefe Pisionidae gigante y jefe Nereidae. No cambiar datos, hitboxes, patrones, tiempos, progresión, economía, guardados ni audio. Mantener Normal/Pruebas separadas.

Se integra el estilo aceptado en una rama revisable, sin marcar automáticamente los nuevos recursos como finales aprobados. Manifiesto: estado placeholder mientras se revisa el lote; procedencia y etapa de revisión en registro de arte separado, por el contrato cerrado del manifiesto. Los PNG no llevan rótulos dentro del combate. El usuario debe aceptar el lote jugable al final.

## Tareas verificables

- [x] Ejecutar baseline nativa; guardar hashes de diseño/datos/guardado/audio y abrir rama limpia.
- [x] Integrar primero nave, Hydroides48×48, capas y portada del piloto. Cargar ancho de capa real, conservar UI funcional y F3; pruebas del render para esos casos antes de ampliar el lote.
- [x] Generar con imagegen y revisar dos poses originales de las otras seis familias, Pisionidae gigante y Nereidae. Recortar/paletizar mediante Pillow autorizado; mantener tamaños reales y geometría. Para Nereidae, piezas PNG independientes sobre los segmentos existentes; no alterar daño ni IA.
- [x] Actualizar solo PNG, manifiesto y atlasW01; no regenerar placeholders de otros mundos. Adaptar pruebas antiguas que exigían rectángulos etiquetados a la coexistencia de arte y placeholders, con regresiones de transparencia/daño/geometría y fallback atlas.
- [x] Ejecutar suites nativas y validación. Capturas reales a640×360,1280×720,1920×1080 de menú, siete especies, minijefe, fases de Nereidae y F3; medir rendimiento real. Declarar límites Windows/mando/humano.
- [x] Reconstruir ambas ediciones Windows/NSIS con plantillas existentes, verificar hashes/payload/arranque disponible sin afirmar prueba Windows real. Publicación posterior al commit: rama e instaladores con enlaces directos; la verificación de estos enlaces se comunica al entregar.

## Criterios de revisión

Comparar nombres/roles con spec4.1/4.2 y datos reales. Paletas<=16 por sprite y alfa binario; animación sin saltos; dos frames blancos; fondos repetibles sin deformarlos a640 si miden1280; daño visible separado de fondo; títulos y botones legibles y accionables en ambas ediciones; ilustración no sustituye lógica de menú. Render y colisiones usan la misma geometría, incluida división de fase3. Ningún PNG fuera del mundo1 se presenta como final.

Fuera: mundo2+, canciones, rediseño de patrones, balance y nuevas habilidades. No llamar terminado al mundo1 entero si permanecen recursos provisionales, controles sin revisar o validaciones pendientes.
