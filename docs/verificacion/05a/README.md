# Encargo 05A — campaña de 12 mundos, entrega para revisión

Base aceptada: `fix/w01-04a-pantalla-sonar-auras`, `9871b5a997408cd4ffec45b8a2b2b0593435537c`; checkout original limpio y referencia remota comprobada. Rama de entrega `migracion/05a-campana-12-mundos`. Godot 4.6.3, Windows x64, Normal/Pruebas. Entrega05A comprobada para revisión personal del usuario; no implica su aceptación ni mundo1 terminado.

## Qué cambia

- 12 mundos principales y escape especial13, sin exponerlo como un decimotercer mundo. Antiguos3/6 retirados como etapas, datos y recursos conservados en archivo04A verificable.
- Minijefes temporalmente desactivados, sin escoltas/premios/bloqueos ficticios. Nereidae y los demás jefes finales siguen obligatorios. Laboratorio12: robots→científico→Eunice→escape, sin Epitoka activo.
- Catálogos añaden exactamente2 comunes/1 recurrente por mundo.15 tipos nuevos y16 asignaciones sin recursos permanecen pendientes;32 entradas de sprites pendientes explícitas. No se inventa arte ni IA. Las oleadas conservan su composición; W01 mantiene90 individuos, distribuidos sin la ventana vacía del minijefe. No se implementa la densidad160 de05C.
- Guardado3 aislado en `normal|pruebas/campaign12`, opciones en su ruta anterior. Carga/preview sin escritura, aviso y confirmación; antiguas etapas3→entrada2,6→entrada4. Copias crudas inmutables de originales y `.bak` antes del primer guardado nuevo, verificadas por hash. Escritura atómica, recuperación, aislamiento de ediciones y retorno de repetición.
- Equipo=false sigue sin comprar; importación activa el perfil antes de autosave; continuación exige victoria real y los premios permanecen idempotentes. La migración también traduce el propietario semántico de las monedas de cambio de fase; las cobradas antes de migrar no reaparecen al reintentar. Precios, HP/patrones, PNG y música conservados.

[Mapa y recursos](../../diseno/encargo05/matriz-migracion.md) · [Economía](../../diseno/encargo05/economia.md) · [Diseño posterior sin implementación](../../diseno/encargo05/siguientes-bloques.md).

## Descargas de esta rama

- [Instalador Normal](../../../entregas/Poliquetos-Normal-Instalar.exe), 29.745.519 bytes, SHA-256 `16f04be5830208480deacffaeac2bea8d7b3b755684074e7e8019546a217fcda`.
- [Instalador Pruebas](../../../entregas/Poliquetos-Pruebas-Instalar.exe), 29.746.368 bytes, SHA-256 `f4b92554a70665644a81b4b658a296df263025c3ba6a1c554445ea7209afe4ca`.

[Construcción](construccion.log), [manifiesto](SHA256-build.json), [CRC/PE/PCK/payload/arranque](distribucion.json). El payload del instalador coincide por SHA con el PE exportado. También se ejecuta un probe contra el PCK extraído y el export Linux independiente como comprobaciones adicionales, identificadas por su host.

## Instalación y revisión personal

Descargar cada `.exe` por su enlace individual en la raíz del repositorio, ejecutar para el usuario actual y abrir su acceso directo. No hace falta Godot, navegador ni conexión. Instalar cada edición en su carpeta independiente; los instaladores NSIS ofrecen desinstalador y conservan partidas. Los hashes definitivos están en `entregas/SHA256.json`. Instaladores sin firma digital.

Normal: nueva partida, dificultad Normal, ranura1; esperar oleadas desde10s, comprobar ausencia del minijefe gigante Pisionidae y llegada obligatoria de Nereidae después de la alerta170. Derrotarlo, abrir tienda, comprar, guardar; cerrar el proceso, abrir y cargar, comprobar compra y continuar a la entrada siguiente. Pruebas: selector1–12 y escape especial; laboratorio3 encuentros, armas seleccionables explícitamente, estadísticas base iguales y mejoras/equipos pendientes salvo sonar. Sus créditos ilimitados financian compras y no alteran Normal.

Para comprobar migración, conservar copia externa de la partida antigua, abrir su ranura y leer el aviso antes de aceptar; cancelar no escribe. Los originales anteriores permanecen fuera del subdirectorio `campaign12`.

## Revisión y regresiones

`DISPLAY=:92 python3 scripts/test-native.py --render`: **38 controles PASS**, incluidos36 tests Python y15 contratos de datos. [Resumen](suite-completa.log) · [Registros completos](pruebas-nativas/) · [Resultados estructurados](pruebas-nativas/results.json). Campaña387 checks; persistencia651; tienda149. El recorrido completo comprueba2139 rivales de12 mundos,14descansos,3 encuentros de laboratorio y escape300s/90 rivales; todos los jefes mueren por proyectiles de producción. Sus rivales regulares, puntería y supervivencia se aíslan artificialmente: **no es evidencia de partida humana ni vídeo sin ayudas**. Error máximo de los relojes al guardar/cargar:4,55e-13s.

La revisión independiente detectó y permitió reproducir el cobro duplicado de monedas de fase al renumerar el jefe: RED140 checks/34 fallos, GREEN140/0 tras traducir solo el propietario semántico del UID. Incluye Game real, v1/v2, importación, reintento y retornos de repetición anidados del laboratorio. Persistencia completa651 checks/0 fallos. Revisión acotada independiente repitió140/0 y aprobó la corrección. Se conserva el detector estricto de errores del runner.

La revisión también exige distinguir presupuesto modelado de ingreso total: las monedas variables por convertir proyectiles de jefes finales/minijefes históricos no están cuantificadas en22680/4485/16,51%. El cero de minijefes corresponde solo a recompensa fija directa al morir.

## Fallo descubierto al comprobar el PE y corrección

La primera grabación del PE derrotó a Nereidae, obtuvo375 créditos y compró escudo por250, pero el guardado falló y la reapertura leyó la partida antigua. **Esa sesión está rechazada**, aunque ganó el combate; [resumen y hash de su vídeo](diagnostico-semilla/sesion-rechazada.json), [pantalla del error](diagnostico-semilla/fallo-guardado-PE.png). Su semilla concreta se perdió al cerrar el proceso; no se presenta una deducción como lectura directa de aquel perfil.

Se reprodujo el mismo fallo desde Main._new_profile:13de24creaciones naturales fallaban. `randi()` genera uint32, mientras el validador heredado aceptaba solo hasta2147483647. Se amplió **solo la semilla** a4294967295; no se cambiaron RNG, estadísticas, dinero ni otros límites. RED643 checks/28 fallos, GREEN651/0 y24creaciones UI correctas. Los negativos, fracciones, NaN y2^32 siguen rechazados. El EOF de archivo se investigó y quedó descartado con una lectura Windows real.

El [arnés Windows](guardado-windows/report.json), reproducible con `scripts/qa-windows-save-suite.py`, exporta las mismas651 pruebas y módulos de producción a un PE con carpeta de usuario propia; terminó con0y651/0bajo Wine. Esto verifica la API Windows de guardado; **no es una grabación de partida ni una prueba de instalación**. El piloto de vídeos comprueba además los archivos reales de la campaña tras crearla y guardar la compra; registra semilla/versión y falla ante `SAVE_DIAGNOSTIC`. No modifica el perfil para validarlo.

## Partida exportada Normal comprobada

[Vídeo completo Normal](videos/Normal.mp4) · [metadatos y SHA](videos/Normal.json) · [resumen y capturas](sesiones/normal/resumen.json) · [telemetría completa comprimida](sesiones/normal/reporte-completo.json.gz).

PE final `d0eba82cf9fffc1d62b0b9cdaff02dd5c45e8b329374e818e55e99c0a4d8c322`, idéntico al payload del instalador. Windows PE bajo Wine/X11,1366×768, teclado automatizado guiado por telemetría de lectura. No es una partida humana. No se inyecta vida, daño, tiempo, dinero ni victoria. La semilla3789403639, que antes excedía el límite, se genera naturalmente y queda guardada en versión3 desde el inicio.

90 rivales generados/82 destruidos,0 minijefes,1 Nereidae con3fases. Entrada del jefe a176,013s de simulación y resultados a545,298s, escudo90. El combate del piloto automatizado dura369,285s: no demuestra el objetivo humano60–100s, cuyo ajuste pertenece a05C. Se obtienen390 créditos, se compra escudo250→140y rango1; guardar, cerrar el proceso con0, abrir de nuevo y cargar recupera los140 créditos, la misma semilla y todas las mejoras. La entrada siguiente muestra escudo120. Esa entrada usa contenido histórico, **no desarrollo nuevo de mundo2**; su fondo provisional conserva la etiqueta técnica existente.

Vídeo601,45s,12008 cuadros,1366×768; fuente y publicación coinciden en duración, cuadros y resolución. Se comprime todo con H264, sin cortes, escalado ni recorte; decodificación completa sin errores. Grabación sin audio (`Dummy`), música y muestras del juego intactas por hash. Una advertencia XShm durante el ajuste inicial de pantalla no detuvo la captura; se conserva en el [log](sesiones/normal/grabacion.log). Los20FPS de captura no son una medición del rendimiento del juego.

## Partida exportada Pruebas comprobada

[Vídeo completo Pruebas](videos/Pruebas.mp4) · [metadatos y SHA](videos/Pruebas.json) · [resumen y capturas](sesiones/pruebas/resumen.json) · [telemetría completa comprimida](sesiones/pruebas/reporte-completo.json.gz).

PE final `8cf2b2b5cd73615283be15a16aa6a0f08d535d0c598edf3f32749478798889eb`, idéntico al payload del instalador. Se recorren en el menú los12 mundos y escape especial y se elige **explícitamente8/8/8** para armas; no son las armas iniciales de Normal. Las mejoras siguen a0y los equipos pendientes salvo sonar, con escudo100. No se usa invulnerabilidad, daño artificial ni un salto al resultado.

90 generados/90 destruidos,0 minijefes,1 Nereidae/3fases. Jefe176,030→victoria269,827s de simulación, escudo100; esa duración con armas8no valida la dificultad humana de Normal. Se compra escudo de rango0→1 con créditos ilimitados, se guarda, cierra con0y reabre; misma semilla147001, dinero999999999y mejoras recuperadas, siguiente entrada con escudo120. [Comprobación de ambos archivos después de las dos sesiones](aislamiento-tras-ambas-sesiones.json): Normal conserva140y su semilla3789403639; Pruebas mantiene su perfil independiente.

Vídeo342,60s/6847 cuadros/1366×768, mismos cuadros y duración que la fuente, decodificación completa sin errores. H264 sin cortes/escalado/recorte; silencio intencional de captura y advertencia XShm inicial declarados igual que en Normal. Revisados los PNG reales y cuadros extraídos de los vídeos publicados: combate/HUD, fases, compra/guardado, carga tras proceso nuevo y transición. Una pantalla negra entre procesos corresponde al cierre real y arranque siguiente; no se retoca ni se sustituye por un montaje.

## Evidencia y límites

Las [capturas de UI](fixtures-ui/) son fixtures sintéticos de presentación, **no partidas**: ambas ediciones, ventanas físicas640×360,1280×720 y fullscreen1920×1080, viewport lógico640×360. Se revisaron avisos de3/6, selector de laboratorio/escape y alias de kelp. El kelp conserva el recurso histórico provisional con su etiqueta técnica: no se presenta ese mundo como arte nuevo terminado. Los PNG de W01 integrados en B1/04A conservan su estado de revisión previo.

[Rendimiento aislado](rendimiento-aislado.json): Linux/llvmpipe,50 enemigos,200balas enemigas,64aliadas,220 frames medidos;50,56FPS medios,19,78ms medios,37,65ms p95. La suite final registró41,48FPS/24,11ms medios/40,94ms p95 en su propia ejecución ([log](pruebas-nativas/performance.log)); no se atribuye la variación a una causa no medida. Ninguna medición acredita60FPS ni representa hardware Windows. No se borraron enemigos para mejorar el dato.

[Intento de instalación bajo Wine](intento-instalar-wine.json): ambos NSIS salen con1 por falta del runtime Wine32 (`syswow64/ntdll.dll`, c0000135). No se presenta la extracción/verificación del payload como instalación. CRC, PE/PCK y arranque del contenido se comprueban por separado. Windows físico, instalación/desinstalación allí, mando, DPI/Alt+Tab/barra de tareas y aceptación visual/jugable personal siguen pendientes.

[Precisión JSON](precision-json.log): `full_precision` evita pérdida innecesaria al serializar. Godot puede interpretar un decimal con1ULP de diferencia (~4,55e-13s); el test de campaña admite hasta1ns solo en los dos relojes, con tipos/presencia preservados y todos los demás campos exactos. No se altera la partida para forzar una igualdad binaria.

## Siguiente puerta

Revisar esta entrega05A antes de autorizar05B (terreno sólido y anclajes). Después,05C (densidad y Nereidae) y05D (sonar táctico), cada uno separado y con pruebas jugables. No se inicia mundo2 ni se declara terminado mundo1.
