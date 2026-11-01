# Progreso v2

**Estado actual: entrega nativa de Windows.** Están implementados los sistemas de las fases 1–9 y la parte técnica de la fase 10. Hay dos instaladores en `entregas/`. La validación humana de duración/dificultad y el arte definitivo siguen pendientes; las canciones permanecen fuera por indicación del usuario. Las notas iniciales describen entregas anteriores.


## Fase 0 — Inventario y base

Hecho:

- Incorporada íntegra la especificación v2 recibida.
- Inventariados automáticamente 119 tipos del motor actual, sus estadísticas base, sus mundos y roles, y las referencias a los renderizadores existentes.
- Registrados todos los participantes de jefes: contaminación (3), hadal (2) y laboratorio actual (7 individuos en 4 encuentros).
- Preparados 11 contratos JSON Schema: inventario, mundos, enemigos, jefes, tienda, cosméticos, audio, oleadas, escape, atlas y manifiesto.
- Preparada la estructura de carpetas de 15.3, incluidos `w01` a `w15` para sprites/fondos. Los archivos `.gitkeep` no son assets.
- Validación reproducible y pruebas de datos válidos e inválidos, referencias de atlas, roles y determinismo del inventario.
- Confirmadas con el usuario las propuestas de la sección 14. Registradas diferencias del legado y adaptaciones necesarias para la distribución HTML.

Aceptación: correspondencia de especies y jefes orgánicos comprobada. El inventario conserva los robots actuales; el reemplazo propuesto para el laboratorio está explícitamente registrado como pendiente. La fase 0 no implementa los nuevos minijefes.

Pendiente, por orden:

1. Fase 1: carga de PNG/atlas, manifiesto completo, fuente bitmap, resolución 640×360, escalado entero y F3.
2. Fases 2–5: núcleo lateral, armas, oleadas y jefes segmentados con patrones propios.
3. Fases 6–7: balance/tienda y guardado/menús. Generar CSV de balance antes de programar la tienda.
4. Fases 8–9: poblar los 14 mundos y escape con los datos y las propuestas aceptadas.
5. Fase 10: pulido, rendimiento y duración real; canciones pendientes hasta que el usuario reabra ese trabajo.

Las dos ediciones jugables actuales permanecen en `versiones/`. Todavía no son la campaña v2.

## Repetir la comprobación

```sh
python3 -m pip install -r requirements-dev.txt
node scripts/inventory-legacy.cjs
python3 scripts/validate-v2-data.py --self-test
node --test
```

La regeneración del inventario no debe modificar los HTML. Los contratos comprueban forma y relaciones básicas; los criterios de juego (DPS, FPS, tiempos y economía) necesitan las fases posteriores.

## Verificación y revisión de la fase 0

- Base: 32 pruebas anteriores aprobadas.
- Final: `node --test`, **35/35 aprobadas**, cero fallos.
- `python3 scripts/validate-v2-data.py --self-test`: 11 contratos verificados, ejemplos válidos aceptados y casos inválidos rechazados.
- Documento recibido comparado byte a byte; HTML canónico y ambas ediciones sin diferencias respecto a la base.
- Revisión independiente: ningún hallazgo crítico o importante. Aspectos de fases posteriores (juego lateral, balance, carga PNG, rendimiento, guardado y música) todavía no se pueden verificar y no se declaran implementados.
- Mejora menor pendiente: el validador independiente del inventario no comprueba todas las referencias en ambos sentidos ni todos los duplicados de participantes. La comparación completa contra el extractor y las pruebas de listas de especies/jefes sí detectan alteraciones del inventario guardado. Ampliar esas comprobaciones independientes cuando se amplíe el catálogo.

## Implementación nativa — 1 de noviembre

El usuario pide rehacer todas las fases como juego nativo de Windows, sin navegador. Esto sustituye la plataforma HTML del plan anterior. Godot 4.6.3 conserva el renderizado 2D con PNG y permite JSON real en el directorio de datos del usuario. Se mantienen Normal/Pruebas, todas las propuestas de sección14 aceptadas y canciones excluidas.

### Fase1

Proyecto Godot, resolución640×360 con escalado entero y nearest; generador de PNG provisionales, atlas w01–w15, manifiesto y bitmap con caracteres españoles. Renderizador carga PNG individuales reemplazables, atlas como respaldo. F3 muestra la hitbox de10×6. Arte final pendiente según documento. Verificado con cuatro pruebas Python y prueba Godot de assets.

### Fase2

Simulación nativa separada del renderizado: movimiento8direcciones160px/s, hitbox10×6, disparo principal8niveles, escudo, colisiones, pool200proyectiles, pausa y reaparición. Valores compartidos encombat.json y lectorJSON permite sustituir datos juntoalEXE. Prueba headless core aprobada; las mediciones de rendimiento visibles pertenecen a fase10.

### Fase3

Misiles automáticos8niveles, bombas8niveles con cooldown y limpieza de proyectiles, burbujas de arma/escudo, conversión de nivel máximo, equipo pasivo y reintento con armas de entrada. Prueba headless verifica las16tablas deDPS, bombas, duplicación de burbujas y restauración de armas.

### Fase4

Lector de oleadasJSON, formaciones, movimientosM1–M8 y disparosF0–F5, peligros y checkpoints. Mundo1 verificado con90enemigos, minijefe, alerta a170s y reanudación de oleadas aunque el minijefe siga vivo. Las cantidades son independientes de escoltas/invocaciones.

### Fase5

Jefes por segmentos, puntos débiles, fases que no se saltan, invulnerabilidad3s, telegráficos, entradas/derrotas y encuentros múltiples.22perfiles de jefe y14minijefes con patrones distintos;67combinaciones de fase probadas. Daño/cadencia/HP enJSON; el ajuste del mínimo40% y la medición máxima se completan en fase10.

### Fase6

HojasCSV generadas antes de programar la tienda. Totales17900base/21480bono/30450compras. Mejoras8familias y9equipos pasivos, compras por acto, reembolso100%soloenmisma visita con tokens invalidados al salir. Pruebas89comprobaciones de tienda/guardado pasan; ambos modos empiezan sin mejoras y solo con sonar.

### Fase7

Menús nativos de portada, dificultad, tres ranuras, pausa con cuenta atrás, muerte, resultados y descanso; astillero3zonas, skins por logros, remapeo teclado/mando, opciones y selector exclusivo dePruebas. Guardado JSONuser:// con .bak, importación/exportación, perfiles independientes y restauración del descanso.133comprobaciones deUI y89de tienda/guardado aprobadas.

### Fase8

Contenido completo de los mundos1–13 enJSON: familias únicas/recurrentes, conteos40/60, portadoras y escudos, minijefes y jefes. Pruebas Python verifican conteos, composición y tiempos de cada mundo. Datos orgánicos preservados de la tabla4.2.

### Fase9

Laboratorio de250enemigos con140robots y110orgánicos seleccionados mediante semilla de partida. Cuatro encuentros con descanso entreellos y escape300s/90enemigos con checkpoints90s. Recorrido automatizado verifica14mundos/2424enemigos/17descansos, guardado de cada descanso,4encuentroslab y final; usa daño artificial de prueba y no representa una partida humana ni una medición del balance.

### Fase 10 — implementación técnica y entrega

- 39 efectos WAV originales, mono/44,1 kHz, reproducción con prioridades y máximo 16 voces. No se incorporan canciones ni pistas instrumentales.
- Optimización de colisiones: rectángulos de partes calculados una vez por frame y descarte espacial de enemigos comunes. Se conservan los puntos débiles y cuerpos separados en la geometría real.
- 557 animaciones/1.564 PNG provisionales, atlas w01–w15, impactos blancos de dos frames y paneles que dejan legible la interfaz. El arte continúa siendo provisional.
- Corregidos todos los problemas críticos/importantes detectados en la revisión independiente: menús por frame, recogidas al reintentar, carga de campaña completada, apertura natural de armadura, puntas alcanzables, división/fusión físicas, validación de estado opcional y ocultación de jefes derrotados. Se añadieron regresiones para esos comportamientos.
- Añadidos barriles destruibles con área de daño, peligros cíclicos definidos en JSON, destellos/oscurecimiento/nieve, escena de salida al mar, créditos y estadísticas finales. La tienda muestra efectos antes/después en español.
- Exportaciones reales de Windows x64 con PCK incorporado, empaquetadas en dos instaladores NSIS en español. Instalan para el usuario actual y conservan sus partidas al desinstalar. Incluyen los avisos de licencia de Godot y sus dependencias.

Verificación final:

- 19 comprobaciones nativas ejecutadas por `scripts/test-native.py`: incluyen 15 pruebas Python, contratos JSON y las suites Godot de armas, fases, flujo, UI, guardado y arranque de las ediciones.
- 35 pruebas del HTML legado aprobadas; sus archivos no han cambiado.
- Recorrido automatizado: 14 mundos, 2.424 enemigos de etapa, 17 descansos, cuatro encuentros del laboratorio, escape de 300 s/90 enemigos y final. Utiliza daño de prueba, no una partida humana.
- 17 simulaciones de jefes con daño continuo máximo del presupuesto nominal cumplen el mínimo del 40 %. Se conserva `vida_base` y la vida ajustada está en `vida`; [informe de balance](boss_balance.csv).
- Render medido con 50 enemigos, 200 balas enemigas, 64 proyectiles aliados y disparo máximo: media de **85,09 FPS**, 11,75 ms por frame, p95 de 17 ms en Linux con OpenGL por software llvmpipe. No garantiza el mismo rendimiento en Windows u otro hardware. [Registro](verificacion/rendimiento.json).
- Capturas reales del render: [portada](verificacion/portada.png), [partida](verificacion/partida.png), [tienda](verificacion/tienda.png), [jefes múltiples](verificacion/jefes-multiples.png).
- Instaladores comprobados mediante CRC, extracción, comparación de payload, cabeceras PE x64/PCK y arranque del pack de cada edición con Godot. El arranque autónomo Linux también se comprueba como control del empaquetado. [Registro](verificacion/distribucion.json). Esto no equivale a ejecutar Windows real.

Pendiente de validación final del producto:

- Arte definitivo y sus variantes, a producir aparte según la sección 2.10.
- Canciones, expresamente aplazadas por el usuario.
- Partidas reales para validar/ajustar los objetivos 90/70 minutos y la dificultad.
- Prueba en Windows real y con mando físico. El mínimo de tiempo se ha medido para builds del presupuesto nominal; no está demostrado para todas las builds financiadas con repetición/monedas extra.

La fase 10 queda implementada técnicamente, pero sus criterios de duración humana y rendimiento del equipo destino siguen pendientes. No se declara terminada esa aceptación solo por pasar las simulaciones.
