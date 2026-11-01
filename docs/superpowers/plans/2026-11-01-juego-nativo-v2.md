# Juego nativo v2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans and superpowers:dispatching-parallel-agents for independent file ownership. No changes to other workers' files; controller integrates and commits each numbered phase.

**Goal:** Rehacer la campaña v2 como juego nativo de Windows con ediciones Normal y Pruebas.

**Architecture:** Godot 4.6.3, 2D nativo con CanvasItem componiendo PNG y fuente bitmap. JSON externo para balance y oleadas. Guardado JSON real en user:// con tres ranuras y .bak. Motor anterior HTML preservado; ningún navegador, Electron ni HTML en el nuevo juego.

**Tech Stack:** Godot/GDScript, Python/Pillow para placeholders y validación de desarrollo.

**Spec:** docs/specs/poliquetos-asesinos-v2.md. El usuario autorizó implementar todas las fases, confirmó todas las propuestas de sección 14 y sustituyó el destino HTML por Windows nativo. Música/canciones siguen excluidas.

## Global Constraints

- 640×360, campo 640×336 y HUD inferior 24 px, escalado entero/nearest con barras negras.
- Solo PNG y bitmap para gráficos; rectángulos de placeholder identificados, no arte final generado.
- 14 mundos y escape de 300 s; cifras de tablas prevalecen sobre ejemplos JSON.
- Datos de balance en JSON, 17 visitas y economía 17900/21480/30450.
- Dos ejecutables: Normal y Pruebas. Pruebas abre mundos/armas/skins y dinero ilimitado, compras de mejoras/equipo pendientes salvo sonar; sin invulnerabilidad automática.
- Un commit por fase, aceptación antes de integración siguiente. Pruebas Godot headless y ejecución visible/smoke; no declarar duración humana ni FPS universales sin medida.

## Review Focus

- Reintento conserva compras y monedas, restaura armas de entrada y checkpoint sin duplicar recompensas.
- Guardados corruptos/versiones/perfiles aislados y recuperación .bak.
- Jefes múltiples, fases no salteables, telegráficos y tiempos mínimos.
- Datos exactos: conteos de portadoras, recurrentes tardíos, laboratorio 140/110 y escape 90.
- Exportación Windows: ejecutables reales y ambas ediciones, no una página web renombrada.

## Interfaces y tareas

### Datos (propiedad independiente)
Crear data/worlds.json, enemies.json, bosses.json, combat.json, waves/world_NN.json y escape.json. Valores del documento y tests de conteos/tiempos. IDs de enemigos preservan el legado convertido a snake_case. Mundo: campos del anexo + unicos/recurrentes, jefe_objetivo_seg, vida_minijefe, mini_tipo, base_monedas. Jefe: campos anexo + mundo, arquetipo (legacy bossId), objetivo_seg; patrones por fase declarados. Oleadas: tipo oleada/minijefe/alerta_jefe/escudo/peligro; oleadas con cantidad, formacion,y,enemigo,portadora/item; separación opcional. Añadir esquema y validación para extensiones.

### Assets (fase 1, propiedad independiente)
Generador Pillow, PNG originales provisionales, assets_manifest y atlas w01–w15. `src/core/assets.gd`: class_name PoliAssets, `load_all()`, `sprite(canvas:CanvasItem,key:String,rect:Rect2,time:float=0,modulate:Color=Color.WHITE)`, `text(canvas,text,pos,color=Color.WHITE,scale=1)`, `panel(canvas,rect,selected=false)`; claves estables: wNN_enemy_ID_move, wNN_mini_ID_move, wNN_boss_ID_move (ID=full boss id), w01_ui_ship_original_move, w01_ui_panel_idle, w01_ui_pixel_idle. Background keys wNN_bg_layer1_idle ..layer4. API extra `has_sprite(key)`. Atlas o PNG individuales cargados sin generación gráfica en ejecución. Tipografía bitmap con acentos.

### Núcleo e integración (fases 2–4, controlador)
`src/core/game.gd` RefCounted con simulación determinista separada del dibujado, pool200, nave/armas/colisiones, datos por mundo, checkpoints y oleadas. `src/core/main.gd` Node2D, título, juego y HUD con assets PNG, teclado/mando. Tests headless de movimiento, DPS, daño, armas, pausa, conteos y checkpoint.

### Patrones (fase 5, propiedad independiente)
`src/bosses/patterns.gd`, class_name PoliBossPatterns. `static step(boss:Dictionary,context:Dictionary,dt:float)->Array`: boss.pos Vector2, phase int1-based, age float, attack_clock float, config Dictionary(arquetipo,patrones...), size Vector2, hp,max_hp. context player Vector2,time float,width640,height336,bullet_speed float. Actualiza boss.pos/age/attack_clock y devuelve acciones: bullet {pos,velocity,ttl,homing,bounce,slow}, hazard {rect:Rect2,delay,duration,effect,damage,direction}, spawn {enemy,pos}. Motor controla HP, entrada, fases y recompensas. Todos los jefes de 6.2/6.4 distintos y minijefes. Tests funcionales por perfil, no strings presentes.

### Tienda/guardado (fases 6–7, propiedad independiente)
JSON shop/cosmetics, CSV antes de código de tienda. `src/shop/shop.gd` class_name PoliShop con static `create_profile(sandbox=false,difficulty="normal")->Dictionary`, `stats(profile)->Dictionary`, `visit()->Dictionary`, `purchase(profile,id,visit)->Dictionary`, `refund(profile,id,visit)->Dictionary`, `close_visit(visit)`. IDs compra upgrade:<id> o gear:<id>. Perfil: version2,edition,slot,difficulty,world,lab_boss,credits,upgrades,equipment (sonar),weapons {shot,missile,bomb},bombs,skins,skin,colors {hull,lights,trail},deaths Dictionary,time,cleared Array,seed,completed. stats: max_shield,damage_mult,rate_mult,min_missile,max_bombs,regen,magnet,speed. `src/save/saves.gd` PoliSave static save_slot(slot,profile),load_slot(slot,sandbox),export_slot(slot,sandbox),import_slot(slot,json,sandbox), options. Godot user:// edition-scoped JSON and .bak, corrupt validation/migration. Tests headless.

### Contenido y entrega (fases 8–10, controlador)
Integrar datos exactos 14mundos, laboratorio 4jefes y escape. Debug explícito solo pruebas/F3, herramientas medición DPS y tiempos mínimos. Export presets Windows con recursos externos copiables sin código; ambas ediciones separadas con feature tag `pruebas`; ejecutables portátiles con PCK incorporado si export permite. Verificar importación, pruebas, recorrido simulado completo, screenshots y exportaciones. Documentar lo medido y limitaciones (arte final y música pendientes).

## Progreso

- [x] Fase 1 assets/resolución.
- [x] Fase 2 núcleo.
- [x] Fase 3 armas/ítems.
- [x] Fase 4 oleadas/mundo1.
- [x] Fase 5 jefes.
- [x] Fase 6 economía.
- [x] Fase 7 flujo/guardado.
- [x] Fase 8 mundos1–13.
- [x] Fase 9 laboratorio/escape.
- [ ] Fase 10: implementación técnica de pulido/medición/exportación lista; aceptación de duración humana/hardware destino pendiente. Música aplazada por el usuario.
