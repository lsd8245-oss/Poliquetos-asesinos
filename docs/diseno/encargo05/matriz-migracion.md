# Matriz y contrato de datos 05A

Fuente inmutable: `data/archive/04a/`, copia byte por byte de los JSON originales de `9871b5a997408cd4ffec45b8a2b2b0593435537c`, incluido el esquema de guardados v2 y el manifiesto de assets. `archive_manifest.json` registra SHA-256 por archivo. El inventario heredado activo no se modifica. El script reconstruye desde esta fuente; no usa los IDs activos como entrada ni hace reemplazos globales.

| Mundo antiguo | Activo 05A | Acto |
|---:|---:|---:|
| 1 | 1 | 1 |
| 2 | 2 | 1 |
| 3 | Archivado; destino seguro de guardado 2 | — |
| 4 | 3 | 1 |
| 5 | 4 | 2 |
| 6 | Archivado; destino seguro de guardado 4 | — |
| 7 | 5 | 2 |
| 8 | 6 | 2 |
| 9 | 7 | 3 |
| 10 | 8 | 3 |
| 11 | 9 | 3 |
| 12 | 10 | 3 |
| 13 | 11 | 3 |
| 14 | 12 | 4 |
| 15 | 13, escape especial | Epílogo |

`data/campaign.json` contiene versión 3, 12 mundos, escape 13, laboratorio 12 y tres encuentros. `old_to_new`, `removed_world_destinations`, `asset_sources` y `legacy_boss_to_current` son los mapas compartidos por motor, guardados y presentación. `legacy_lab_to_new={0:0,1:1,2:1,3:2,4:3}` conserva el progreso seguro al retirar la segunda sala: robots → científico → Eunice. Los tres robots siguen siendo un grupo concurrente; se conservan también los grupos de contaminación y de la zona hadal.

Cada mundo tiene `legacy_id`, `miniboss_enabled=false` y `final_boss_enabled=true`. Los finales activos cambian solo su ID y `mundo`; `asset_id` y `asset_world` identifican su fuente histórica. Los minijefes, los finales de antiguos W03/W06 y Epitoka existen únicamente en el catálogo archivado; los perfiles/patrones históricos y PNG continúan preservados.

Cada mundo conserva las listas originales y añade exactamente los dos comunes y el recurrente del JSON adjunto. Se conservan 83 especies existentes y se añaden 15 definiciones pendientes. Las nuevas especies no tienen movimiento o disparo inventados: `estado=pendiente`, `runtime_ready=false` y lista de trabajo pendiente. El catálogo no autoriza spawns de una entrada pendiente. Cada asignación `mundos[n]` declara su rol, `sprite_set` y `runtime_ready`; el selector aleatorio del laboratorio debe filtrar pendientes. Las 36 asignaciones adicionales no son 36 sprites nuevos ni implican oleadas añadidas.

`assets/campaign_aliases.json` contiene 577 alias hacia claves del manifiesto original y 32 faltantes explícitos (move/hit de las 16 asignaciones pendientes). Se incluye el fondo del escape y las referencias históricas a gráficos de mini. Resolver un alias significa consultar su fuente directamente en el manifiesto/atlas original; **no seguir otra entrada del mapa recursivamente**. Por ejemplo, `w03_bg_layer1_idle → w04_bg_layer1_idle` usa el PNG del antiguo kelp aunque exista también una clave activa `w04_bg_layer1_idle`. Una especie trasladada solo reutiliza PNG de esa misma especie. Los fondos, PNG, atlas, manifiesto original y música no se regeneran ni renombran.

Las doce tablas de oleadas activas preservan todas las cantidades, formaciones, posiciones, portadoras, escudos y peligros anteriores. Solo se eliminan el evento de minijefe y sus escoltas. Cada evento sobreviviente tiene `legacy_index` igual a su índice en el archivo original. Debe usarse este índice para UIDs de enemigos/portadoras y migración de `claimed_drops`, nunca el nuevo cursor del array.

Para ocupar la antigua ventana vacía se distribuyen uniformemente las **mismas** oleadas, en el mismo orden, desde 10 s hasta el último tiempo regular original. No se altera el punto de alerta. `data/wave_schedule_migration.json` contiene la comparación completa por evento; en W01 son 14 oleadas, intervalo 11.6923 s, último spawn 162 s, alerta 170 s y 90 individuos. No se ha aplicado la densidad 160 de 05C.

Los campos musicales siguen apuntando a las claves originales inmutables. Para mantener las estadísticas existentes durante la renumeración, la escala de dificultad utiliza `legacy_id`; los nuevos números no son una autorización de rebalanceo. Las recompensas de victoria conservadas y precios están detallados en `economia.md`; el agregado del laboratorio excluye la sala retirada. Las reglas de desbloqueo histórico se expresan en `cosmetics.json` y `campaign.skin_world_rewards`; no se reasignan coral/abisal a otros jefes.

Reproducción y comprobación:

```sh
python3 scripts/migrate-campaign-12.py
python3 scripts/validate-v2-data.py --self-test
python3 -m unittest native-tests/test_campaign12_data.py -v
```

El validador comprueba mapas, referencias, catálogos completos, ausencia de minijefes activos, finales obligatorios, laboratorio consecutivo, identidad y composición de eventos, presupuestos, HP, precios, fuentes PNG de cada especie y pendientes. Los negativos incluyen IDs repetidos/antiguos, jefe final deshabilitado, spawns pendientes, alias ausente o de otra especie y cambios no autorizados de recompensas o conteo. Las pruebas integradas de Godot, guardados y exportaciones pertenecen al controlador de la entrega 05A.
