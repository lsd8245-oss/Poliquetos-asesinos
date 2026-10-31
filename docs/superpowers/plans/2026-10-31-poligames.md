# PoliGames Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Aplicar el PDF PoliGames, excepto canciones/música.
**Architecture:** Adaptación del motor PA4Engine, datos de campaña y UI existentes. Los colaboradores preparan parches delimitados; la integración del HTML la realiza el agente principal para evitar ediciones concurrentes.
**Tech Stack:** HTML/CSS/JavaScript Canvas y Web Audio existentes; Node test, Playwright, Chromium.
**Spec:** docs/superpowers/specs/2026-10-31-poligames-design.md

## Global Constraints

- HTML autocontenido, modo individual sin internet.
- No cambiar composiciones, canciones ni instrumentos.
- 14 mundos, 144 sectores; único escape de 180 s.
- Conteos y distribución taxonómica exactos del PDF.
- Conservar guardados y respetar movimiento reducido/ECO.

## Review Focus

- Migrar checkpoints de mundo16 antiguo a mundo14 sin perder compras.
- Jefes de grupo: no terminar tras matar solo uno.
- Escape: pausa no consume rescate; no requiere vaciar enemigos al final.
- Compras/skins y cambio de aspecto no eluden validación del anfitrión.
- Teclas duplicadas/reservadas y menús pequeños conservan navegación.

### Task 1: Campaña y taxonomía
**Files:** HTML; tests/campaign.test.cjs; tests/helpers/game.cjs.
**Interfaces:** campaignLevelSpec(level), campaignWorld/Stage/Act, migrateCampaignCheckpoint(c); registros TYPES/ALL/CREATURE_STYLE y pools.
- [x] Escribir pruebas de 14 mundos/144niveles, actos, conteos, pools válidos y migración7→8.
- [x] Ejecutar y confirmar fallos por campaña antigua.
- [x] Integrar datos y anatomías taxonómicas; corregir umbrales de laboratorio y progresión.
- [x] Ejecutar pruebas de campaña y pruebas audiovisuales previas.

### Task 2: Encuentros, rescate y reintento
**Files:** HTML; tests/campaign.test.cjs.
**Interfaces:** laboratoryGoal/RequiredBosses/EncounterReady, tickRoom, spawnEnemy, makeCheckpoint/restoreCheckpoint; retry client command.
- [x] Probar exclusividad de jefes, grupos múltiples, gauntlet4, Eunice anclada, rescate180s y pausa.
- [x] Confirmar fallos antes de implementar.
- [x] Adaptar scheduler y final; guardar snapshots por piloto al inicio del sector y reintentar desde ellos.
- [x] Probar muerte/reintento individual y cooperativo, sin premios duplicados.

### Task 3: Economía, astillero y atajos
**Files:** HTML; tests/progression.test.cjs.
**Interfaces:** compactShopFor, compactPlayerEconomy, parseClient shopBuy, openHarbor/app.harborFrom, input key mapping.
- [x] Probar compra gated por actos, moneda insuficiente, skin persistente, retorno al descanso y claves conflictivas.
- [x] Confirmar fallos y añadir skins cosméticas validadas por motor; balance de recompensas y precios.
- [x] Montar astillero en descanso y opciones de atajos persistentes, manteniendo dos controles de audio.
- [x] Ejecutar pruebas de flujo y regresión.

### Task 4: Escenarios, HUD e interfaz
**Files:** HTML; tests/ui.test.cjs; README.md.
**Interfaces:** oceanScene/modernBackdrop, modernLayoutFor, drawEquipment, bit32Icon; death/end, shop, main/options UI.
- [x] Capturar referencia; verificar arena mayor y paneles navegables en escritorio/móvil.
- [x] Diferenciar 14 hábitats con geometrías/luminosidad; ampliar arena y redistribuir HUD; efectos de equipos.
- [x] Mejorar portada, tienda, iconos, derrota y animaciones respetando accesibilidad.
- [x] Revisar capturas y medir coste de fondos normal/ECO.

### Task 5: Integración y entrega
**Files:** todos los anteriores.
- [x] Ejecutar node --test y smoke funcional offline de sector, descanso, compra, astillero, reintento.
- [x] Revisión independiente; corregir fallos sustantivos con prueba de regresión.
- [x] Documentar controles, campaña y entrega; git diff --check.
- [ ] Commit y publicación de rama instrucciones-poligames; verificar remoto y enlace GitHub.
