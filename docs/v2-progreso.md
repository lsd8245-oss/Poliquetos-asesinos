# Progreso v2

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
