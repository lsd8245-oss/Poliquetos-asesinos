# Revisión independiente del lote W01

Revisor: agente independiente `review_w01_integration`, sin historial de la sesión, sobre diff frente a `d6beb99`. Sin hallazgos críticos.

- Importante: Pisionidae, Lacydoniidae y Syllidae quedaban demasiado delgados dentro del rectángulo de contacto. Se regeneraron esas poses y también Phyllodocidae en C/S compactas. Regresión RED→GREEN: `test_errant_poses_fill_the_existing_square_collision_dimensions`. Dimensiones, daño, movimientos y hitboxes intactos.
- Menor: la prueba inicial de división usaba dimensiones sintéticas. Se corrigió para leer split_size_x/y del balance real; las capturas usan Patterns.sync_parts. No se deja diferida.
- Catálogo, transparencia binaria, paletas <=16, atlas sin solapes, frente/cola y reconstrucción de cabeza/cuerpo/mandíbulas verificados. Sin cambios de datos, guardados ni audio.

Después de esa revisión se comprobó: importación de PNG para evitar caché obsoleta; igualdad de píxeles visibles al cargar recursos; dibujo por regiones transparentes con captura640×360 idéntica antes/después; capturas de ventana a tamaño real (sin recorte de monitor); salida de menú y liberación del sonido de selección antes de cerrar. Estas comprobaciones posteriores son del implementador, no una segunda certificación del revisor. Registros completos en `docs/verificacion/integracion-w01/`.

Limitación material: la carga gráfica en llvmpipe no acredita60FPS estables; medición aislada56,54FPS y última suite50,37FPS. Windows real, mando físico y duración humana siguen pendientes. No se aprueba una fase ni se declara final el arte por estas pruebas.
