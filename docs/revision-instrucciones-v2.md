# Revisión documental y próximo encargo propuesto

## Alcance de esta entrega

Solo documentación. Se sustituyó AGENTS.md por el adjunto y se añadió procedimientos-v2.md literalmente. El spec completo se conserva byte a byte. No se modifican scripts, datos, gráficos, sonidos, HTML, instaladores ni guardados; tampoco se inicia ni se aprueba una fase.

Base revisada: rama `juego-nativo-v2`, commit `ac29e2365202cba90dcf504c1913651aa6b5426d`. La copia de trabajo estaba limpia. Rama de esta entrega: `docs/instrucciones-redisenio-v2`.

## Compatibilidad

Los documentos no son literalmente equivalentes. La conciliación de [decisiones](decisiones.md#incorporación-documental-del-1-de-noviembre-reglas-para-los-siguientes-encargos) identifica las diferencias sin editar los adjuntos ni debilitar el spec. Para diseño prevalece el spec completo por instrucción directa del usuario. Para este encargo prevalece la prohibición de cambiar el juego o iniciar una fase, también frente a instrucciones generales de compilación o integración.

Permanecen las reglas de dos HTML autocontenidos, Normal/Pruebas independientes, compras pendientes salvo sonar y música aplazada. El generador HTML y sus dos salidas siguen presentes. La aplicación Godot también se conserva; la documentación nueva no convierte su motor en JavaScript ni acredita sus fases para la línea HTML.

## Estado real y fase pendiente

- **Referencia fase0:** inventario de 119 tipos, 14 mundos, contratos y especificación. No equivale al motor visual v2.
- **HTML del repositorio:** mantiene la campaña anterior; sus dos ediciones no son el rediseño lateral v2. La primera fase v2 pendiente de implementación/aceptación en esta línea es **fase1: assets y resolución**.
- **Godot actual:** contiene implementación de sistemas de fases1–9 y parte técnica de fase10. Su existencia no sustituye una aceptación explícita ni las pruebas visuales de los adjuntos. Su fase10 sigue pendiente de playtest humano de 90/70min, comprobación en Windows/mando y rendimiento del equipo destino. El arte continúa marcado placeholder.
- No hay base para declarar ahora todas las fases aprobadas ni para asumir que debe empezarse una fase11. Antes de programar, el próximo encargo debe fijar la plataforma, la rama/commit aceptados y una única fase. No se descarta la decisión anterior de Windows de manera implícita.

## Próximo alcance para la línea Windows existente

En la rama nativa, propondría primero verificar y corregir únicamente los incumplimientos reproducibles de fase10: sesión completa cronometrada, balance, estabilidad, instalación Windows y mando. No añadiría mundos ni sistemas de otra fase. Se contrastarían los resultados con la tabla de duraciones, los patrones y la economía del spec; los ensayos automáticos previos no sustituyen una partida humana ni mediciones en el equipo destino.

No hacen falta nuevos gráficos para auditar esa versión. Sus placeholders siguen sin ser arte final. Si la prioridad pasa a arte de producción, sería un encargo artístico separado: tres PNG originales de muestra para aprobar estilo, después los recursos del mundo1, con manifiesto, animaciones y procedencia. No se mezclaría esa producción con el cierre técnico de fase10. La aceptación nativa requeriría capturas nuevas a ambas resoluciones, revisión de HUD/menús y legibilidad en combate, pruebas de instalación y guardados separados en Windows, mando y mediciones de FPS y duración. Nada de ello se declara realizado en esta integración documental.

## Propuesta concreta para la próxima fase1, si se confirma la línea HTML

Implementaría únicamente carga de PNG individuales y atlas por mundo, manifiesto rastreable, fuente bitmap española, resolución640×360 (campo640×336/HUD24), escalado entero sin suavizado y F3. Mantendría Normal/Pruebas autocontenidas y sus guardados separados. Reutilizaría recursos verificados compatibles de la rama nativa cuando corresponda, sin importar a ciegas el resto del motor o sus fases.

No incluiría todavía nuevas armas, nuevos ataques, oleadas, economía, cambios de guardado incompatibles, música ni mundos adicionales. El hito de mundo1 con arte final es posterior y reúne fases1–5; no debe confundirse con la aceptación técnica de fase1.

### Recursos necesarios

Para la prueba técnica: PNG de nave48×24; enemigo de prueba con categoría y tamaño aprobados (Hydroides32×32 si se elige pequeño); cuatro capas de fondo repetibles de640×336 como mínimo; fuente bitmap con ASCII y acentos/ñ/¿¡; componentes PNG del HUD/menú y marcador de impacto. Manifiesto/atlas deben contener dimensiones, cuadros, fps, anclajes, estado y procedencia/licencia. Se pueden usar placeholders identificados según la regla del spec, sin cubrir controles; no declararlos finales.

Para el primer hito artístico posterior: lote pequeño de tres assets originales para aprobar estilo y método antes de producir cientos. Para completar mundo1 se necesitarán sus cinco únicos y dos recurrentes, minijefe Pisionidae, jefe Nereidae por piezas articuladas, fondo de cuatro capas, proyectiles y efectos; cada uno con sus ciclos y paleta. No se produce ni integra ese lote en este encargo.

### Cómo comprobaría fase1

1. Pruebas de rutas, referencias, dimensiones, límites/solapes de atlas, caracteres bitmap y estado/procedencia del manifiesto.
2. Sustituir un PNG de prueba sin editar código y comprobar el cambio real en pantalla.
3. Generar ambos HTML desde la fuente; abrir cada uno offline, con datos existentes y perfiles separados.
4. Ejecutar `node --test`, validador y generador; añadir las pruebas de comportamiento del cargador que falten.
5. Revisar en navegador a640×360 y1920×1080, registrar capturas reales de menús/HUD y probar clics/teclado. Verificar escalado entero, nitidez, anclajes, ausencia de superposiciones y F3. No usar capturas antiguas como evidencia nueva.
6. Informar resultados, límites y diferencias frente al spec. La fase solo se presentaría para aceptación cuando pasen las pruebas y la revisión visual; esperar aprobación antes de fase2.

## Verificación de esta integración documental

Los resultados ejecutados se registran en [instrucciones-v2.json](verificacion/instrucciones-v2.json), con el [registro completo de Node](verificacion/instrucciones-v2/node-test.log): 35 pruebas aprobadas, 13 contratos verificados y generación de ambas ediciones sin cambios de contenido. Los adjuntos coinciden byte a byte y el hash del spec permanece intacto.

Se ejecutaron y revisaron capturas nuevas de los menús HTML anteriores: [Normal 640×360](verificacion/instrucciones-v2/normal-640x360.png), [Normal 1920×1080](verificacion/instrucciones-v2/normal-1920x1080.png), [Pruebas 640×360](verificacion/instrucciones-v2/pruebas-640x360.png) y [Pruebas 1920×1080](verificacion/instrucciones-v2/pruebas-1920x1080.png). A 1920×1080 los menús caben; a 640×360, Pruebas recorta parte del panel inferior y abrevia el destino del selector. Normal muestra sus cinco botones principales en esa captura pequeña. La incidencia del menú pequeño se registra sin corregirla, conforme al alcance documental.

Estas capturas no validan el nuevo motor v2, el combate ni todas las interacciones. No se repitieron pruebas visuales nativas, instalación Windows, mando o playtest humano. Ninguna fase queda aprobada ni terminada con esta entrega.
