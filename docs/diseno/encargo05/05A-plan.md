# Encargo05A Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans. No avanzar05B/C/D.

**Goal:** Campaña12+escape, guardados migrados, cero minijefes y jefes finales obligatorios.
**Architecture:** Datos activos migrados con mapa explícito y archivo04A; recursos gráficos/sonoros originales traducidos por alias; runtime y guardado consumen el mapa compartido.
**Tech Stack:** Godot4.6.3/GDScript,JSON/Python,NSIS,Windowsx64.
**Spec:** docs/encargos/05-campana-12-mundos-rescate-jugabilidad-w01.md y05A-diseno.md.

## Global Constraints

- Solo05A. Sin nuevos PNG/música/terreno/balance deNereidae/sonar táctico.
-12mundos principales, escape13 especial, laboratorio12/3encuentros; Epitoka archivado.
- Arte B1/04A y legado HTML se conservan. Normal/Pruebas aisladas, compras pendientes salvo sonar.
- Guardados antiguos recuperables y aviso al retirar3/6; ninguna victoria automática de jefe.
- Un commit coherente final segúnAGENTS; agentes no confirman ni cambian rama.

## Review Focus

- Colisiones de nuevos IDs y alias con fuentes históricas→tests de matriz/recursos.
- Guardados de retirados/replay/laboratorio→fixturesv1/v2/v3 + backups.
- Alerta bloqueada por mini deshabilitado→recorrido hasta jefe de12mundos.
- Recompensas duplicadas al cargar resultados/rest/laboratorio→idempotencia y compra real.
- Selector muestra destino pero carga recursos distintos→arranque real de cada selección/export.

### Task1: Datos/archivo/mapa/contratos
Files: data/*.json,data/waves/*,data/schemas/*,assets/campaign_aliases.json,scripts/migrate-campaign-12.py,scripts/validate-v2-data.py,native-tests/test_campaign12_data.py.
Produces data/campaign.json: version3,world_count12,escape_id13,laboratory_id12,lab_encounters3,old_to_new,removed_world_destinations(3:2,6:4),legacy_lab_to_new(0:0,1:1,2:1,3:2,4:3),legacy_boss_to_current,asset_sources. Worlds gain legacy_id,miniboss_enabled=false,final_boss_enabled=true. Aliases distinguish active/historical resources without changingPNG. Event legacy_index stable.
- [x] RED structural tests against14worlds; migrate+archive; GREEN schema/catalog/map/aliases/economy report. Do not touchGDScript.

### Task2: Campaña/runtime
Files src/core/campaign.gd,src/core/data.gd,src/core/game.gd,src/stages/stages.gd,src/bosses/bosses.gd,native-tests/campaign12_test.gd.
Consumes Task1. Produces Campaign static config(),world_count(),escape_id(),laboratory_id(),lab_encounter_count(),legacy_world(id),asset_key(world,kind,id,action="move"). Uses Data.read_json, no dependency cycle. Runtime mini_status disabled/zero spawn (keep mini_defeated false); final boss real. Lab3, escape13, correct stats/rewards/replay.
- [x] RED no-mini mandatory-boss tests; integrate constants/map and stage flow; GREEN all12/world1/lab/rewards. No edits to main/save/shop/dataJSON.

### Task3: Persistencia/tienda
Files src/save/saves.gd,src/shop/shop.gd,native-tests/campaign12_save_test.gd.
Consumes map. Profileversion3, file_path uses user://normal|pruebas/campaign12/slot_N.json, legacy_file_path previous. Load migrates in memory only; result migration_notice (String), migrated(bool). Originalfile+bak preserved and copied at firstnewsave. Options paths unchanged. Map all nested history/keys/replay; oldremoved3→2,6→4 withnotice; labmap; nofutureversion accepted. Act thresholds4/7/12 and first labvictory.
- [x] RED migration/backup/rejectedcases/price+purchase tests; integrate; GREEN absent/valid/old/corrupt/mismatchededition + rest/load/purchase/refund.

### Task4: UI/render and remaining regressions (root)
Files src/core/main.gd and affected native-tests/export probes/scripts verification.
Consumes Campaign API and save result metadata. Newselector1–12+escape label,lab3; render aliases/archivePNG; no minitick; bossarrival reflects actualalert; displaymigrationnotice. Exact existing fullscreen/audio/sonar unchanged. Update targeted stale assertions using historicalfixtures forhistoricalart, not weakeninggeneralcontracts.
- [x] RED menu/alias/migrationnotice tests; integrate; GREEN focused+fullnative --render. Review task1–3 diffs beforeintegration close.

### Task5: Exports/evidence/report/review
Files scripts/qa-05a-windows.py,docs/verificacion/05a/*,docs/decisiones.md,docs/v2-progreso.md,docs/diseno/encargo05/siguientes-bloques.md,entregas/*.exe,entregas/SHA256.json.
- [x] Baseline clean30PASS; new full suite passes. Configure isolatedWineQA; exportedPE routeW01 with realkeyboard/no cheats throughactualboss+shop+save+reload. Record failures honestly and fixrootcause.
- [x] CRC/hashes/PE/PCK, twoinstallers, captures and videos; economybefore/after. Independent wholebranchreview. Publish ownbranch/directfiles only afterverification; stop05A foruserreview.
