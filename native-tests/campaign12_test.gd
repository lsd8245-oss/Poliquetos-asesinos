extends SceneTree
const Game = preload("res://src/core/game.gd")
const Shop = preload("res://src/shop/shop.gd")
const Data = preload("res://src/core/data.gd")
const Saves = preload("res://src/save/saves.gd")
var failures: Array[String] = []
var checks = 0
var campaign

func check(value: bool, message: String):
	checks += 1
	if not value:
		failures.append(message)

func make_game(world_id: int = 1, room: int = 0):
	var p = Shop.create_profile()
	p.world = world_id
	p.lab_boss = room
	var g = Game.new()
	g.start(p)
	return g

func has_property(object, name: String) -> bool:
	return object.get_property_list().any(func(p): return p.name == name)

func _initialize():
	var d = Data.all()
	check(d.has("campaign"), "Data.all exposes the shared campaign contract")
	check(d.waves.size() == 12, "Data.all loads exactly twelve active wave files")
	check(FileAccess.file_exists("res://src/core/campaign.gd"), "Campaign API exists")
	if not FileAccess.file_exists("res://src/core/campaign.gd"):
		finish()
		return
	campaign = load("res://src/core/campaign.gd")
	if OS.get_cmdline_user_args().has("--replay-returns-only"):
		test_replay_return_states()
		finish()
		return
	print("CAMPAIGN12 running test_contract")
	test_contract()
	print("CAMPAIGN12 running test_no_minis_and_victory_guards")
	test_no_minis_and_victory_guards()
	print("CAMPAIGN12 running test_pending_and_identity")
	test_pending_and_identity()
	print("CAMPAIGN12 running test_legacy_stats")
	test_legacy_stats()
	print("CAMPAIGN12 running test_lab_pool")
	test_lab_pool()
	test_legacy_boss_conditions()
	print("CAMPAIGN12 running test_combat_victory")
	test_combat_victory()
	print("CAMPAIGN12 running test_lab_progression_and_rewards")
	test_lab_progression_and_rewards()
	print("CAMPAIGN12 running test_skins_and_escape")
	test_skins_and_escape()
	test_replay()
	test_replay_return_states()
	finish()

func test_contract():
	check(campaign.world_count() == 12 and campaign.escape_id() == 13, "twelve main worlds and separate escape13")
	check(campaign.laboratory_id() == 12 and campaign.lab_encounter_count() == 3, "laboratory12 has three encounters")
	check(campaign.legacy_world(3) == 4 and campaign.legacy_world(12) == 14 and campaign.legacy_world(13) == 15, "asset/stat source world map")
	check(campaign.asset_key(3, "bg", "layer1", "idle") == "w04_bg_layer1_idle", "background resolves directly to original PNG key")
	check(campaign.asset_key(3, "boss", "boss_w03_tere") == "w04_boss_boss_w04_tere_move", "renumbered final resolves to original boss key")
	check(campaign.asset_key(1, "enemy", "eulalia") == "", "pending art never falls back to another species")

func test_no_minis_and_victory_guards():
	for world_id in range(1, 13):
		var g = make_game(world_id)
		check(has_property(g, "mini_status") and has_property(g, "mini_spawn_count") and has_property(g, "boss_spawn_count"), "runtime exposes real actor counters and disabled status")
		if not has_property(g, "mini_status"):
			continue
		check(g.mini_status == "disabled" and not g.mini_defeated and not g.mini_spawned, "world%d starts with mini disabled, never defeated" % world_id)
		for tick in range(240):
			g.stage_system.step(g, 0.5)
			if tick in [119, 239]:
				check(g.mini_spawn_count == 0 and not g.mini_defeated and not g.mini_spawned, "world%d no mini at60/120s" % world_id)
		var before_world = int(g.profile.world)
		g.continue_campaign()
		g.finish_encounter()
		check(g.state == "playing" and int(g.profile.world) == before_world and not g.profile.has("resume"), "playing cannot advance/finish without victory")
		# Old external wave files cannot resurrect archived minibosses or escorts.
		g.stage_system.events.insert(g.cursor, {"t":120.25,"tipo":"minijefe","id":"mini_w01_pision"})
		g.stage_system.step(g, 0.5)
		g.boss_system.spawn(g, "mini_w01_pision", true)
		check(g.mini_spawn_count == 0 and not g.mini_spawned and not g.mini_defeated, "legacy mini event and direct spawn remain inactive")
		while g.world_time < float(g.world.alerta_jefe_seg):
			g.stage_system.step(g, 0.5)
		check(g.state == "alert", "world%d reaches final alert without fabricated mini victory" % world_id)
		check(g.regular_spawned == int(g.world.enemigos_total), "world%d actual regular actor budget" % world_id)
		g.continue_campaign()
		g.finish_encounter()
		check(g.state == "alert" and int(g.profile.world) == before_world, "alert cannot advance before final")
		g.phase_clock = float(g.data.combat.timings.alert)
		g.boss_system.step(g, 0.0)
		var expected = g.world.sectores_jefes[0].jefes.size() if world_id == 12 else g.world.jefes.size()
		check(g.state == "boss" and g.boss_spawn_count == expected and g.boss_spawned, "world%d spawns every real final actor" % world_id)
		g.continue_campaign()
		g.finish_encounter()
		g.phase_clock += 5000.0
		g.boss_system.step(g, 0.01)
		check(g.state == "boss" and int(g.profile.world) == before_world and not g.profile.cleared.has(world_id), "time alone and direct calls cannot grant results")
		check(g.mini_spawn_count == 0 and not g.mini_defeated, "minis remain inactive during final combat")
		g.start(g.profile)
		check(g.boss_spawn_count == 0 and g.mini_spawn_count == 0, "start resets actual actor counters")
		g.start(g.profile, {"mini_defeated":true})
		check(not g.mini_defeated and not g.mini_spawned and g.mini_status == "disabled", "historical checkpoint cannot fabricate a disabled mini victory")

func test_pending_and_identity():
	var g = make_game()
	var size_before = g.enemies.size()
	check(g.stage_system.spawn_enemy(g, "eulalia", Vector2(600, 80)).is_empty(), "global pending species cannot spawn")
	var ready = g.stage_system.enemy_index.hydroides
	ready = ready.duplicate(true)
	ready.mundos["1"].runtime_ready = false
	g.stage_system.enemy_index.hydroides = ready
	check(g.stage_system.spawn_enemy(g, "hydroides", Vector2(600, 80)).is_empty(), "per-world pending species cannot spawn")
	g.stage_system.spawn_wave(g, {"enemigo":"eulalia","cantidad":3,"formacion":"linea_horizontal","legacy_index":67}, 2)
	check(g.enemies.size() == size_before and g.regular_spawned == 0 and int(g.profile.get("spawned_total",0)) == 0, "pending waves do not fabricate actors/statistics")
	g = make_game()
	g.stage_system.spawn_wave(g, {"enemigo":"hydroides","cantidad":2,"formacion":"linea_horizontal","legacy_index":67}, 2)
	check(g.enemies[0].wave == 67 and g.enemies[0].uid == "wave_67_0" and g.wave_state.has("67"), "legacy_index stabilizes wave actor and drop identity")
	# A bad final definition must not yield a spawned flag or automatic victory.
	g = make_game()
	g.data = g.data.duplicate(true)
	g.data.bosses = []
	g.state = "alert"
	g.phase_clock = float(g.data.combat.timings.alert)
	g.boss_system.step(g, 0.0)
	g.boss_system.step(g, 100.0)
	g.finish_encounter()
	check(not g.boss_spawned and g.boss_spawn_count == 0 and g.state == "boss", "missing final definition cannot create an empty encounter victory")

func test_legacy_stats():
	for world_id in range(1, 14):
		var g = make_game(world_id)
		var source = campaign.legacy_world(world_id)
		var id = "mech_nereis" if world_id == 13 else str(g.stage_system.events.filter(func(e): return e.tipo == "oleada")[0].enemigo)
		var enemy = g.stage_system.spawn_enemy(g, id, Vector2(600, 100))
		var ref = float(g.data.combat.enemy.dps_ref_base) + float(g.data.combat.enemy.dps_ref_world_step) * (mini(source,14)-1)
		var expected_hp = ceilf(ref / float(g.data.combat.enemy.small_hp_divisor))
		if enemy.config.categoria == "enjambre":
			expected_hp = ceilf(ref / float(g.data.combat.enemy.swarm_hp_divisor))
		elif enemy.config.categoria == "mediano":
			expected_hp *= float(g.data.combat.enemy.medium_hp_multiplier)
		if enemy.config.get("blindado",false):
			expected_hp *= float(g.data.combat.enemy.armored_hp_multiplier)
		check(is_equal_approx(enemy.hp, expected_hp), "world%d HP preserves old world%d budget" % [world_id,source])
		var speed = float(g.data.combat.enemy.bullet_speed_base) * (1 + float(g.data.combat.enemy.bullet_speed_world_scale) * (source-1))
		check(is_equal_approx(g.stage_system.bullet_speed(g), speed), "enemy bullet speed retains source world scaling")
		g.enemy_bullet(Vector2.ZERO, Vector2.ZERO)
		var expected_damage = floorf(float(g.data.combat.enemy.bullet_damage_base) + float(g.data.combat.enemy.bullet_damage_world_step) * (source-1))
		check(g.enemy_bullets.back().damage == expected_damage, "enemy bullet damage retains source world scaling")
		enemy.pos = g.player.pos
		# Isolate contact scaling from M2/M5/M6 repositioning and hiding.
		g.stage_system = null
		var shield = float(g.player.shield)
		g.step_enemies(0.0)
		var contact = float(g.data.combat.enemy.contact_damage_base) + float(g.data.combat.enemy.contact_damage_world_step) * (source-1)
		check(is_equal_approx(shield-g.player.shield, contact), "enemy contact damage retains source world scaling")

func test_lab_pool():
	var g = make_game(12)
	var sequence = g.stage_system.events.duplicate(true)
	check(sequence.filter(func(e): return e.tipo == "oleada").all(func(e): return g.stage_system.enemy_index[e.enemigo].get("runtime_ready", true) and g.stage_system.enemy_index[e.enemigo].mundos.get("12",{}).get("runtime_ready",true)), "seeded laboratory contains ready species only")
	g.world = g.world.duplicate(true)
	g.world.recurrentes.erase("capitella_capitata")
	g.stage_system.begin(g)
	check(sequence == g.stage_system.events, "pending species filtered before seeded selection, preserving ready pool determinism")
	g.stage_system.begin(g)
	check(sequence == g.stage_system.events, "repeated laboratory seed generates identical wave mapping")
	# Per-world readiness must also be filtered before consuming seed choices.
	g.data = g.data.duplicate(true)
	for row in g.data.enemies:
		if row.id == "hydroides":
			row.mundos["12"].runtime_ready = false
	g.stage_system.begin(g)
	sequence = g.stage_system.events.duplicate(true)
	g.world.recurrentes.erase("hydroides")
	g.stage_system.begin(g)
	check(sequence == g.stage_system.events, "per-world pending species are excluded before seeded lab selection")

func test_legacy_boss_conditions():
	# Remove an ally from these isolated conditions; no victory is claimed.
	var g = make_game(6)
	start_final(g)
	for e in g.enemies:
		e.entry = 0.0
	g.enemies.remove_at(0)
	g.boss_system.step(g, 0.01)
	check(g.enemies.all(func(e): return is_equal_approx(e.fury_multiplier,1.25)), "old-world8 pollution fury follows current world6")
	check(not g.boss_system.encounter_defeated(g), "missing ally actor cannot substitute for defeat")
	g = make_game(11)
	start_final(g)
	var ruler = g.enemies.filter(func(e): return e.config.arquetipo == "hadalsovereign")[0]
	ruler.entry = 0.0
	g.enemies = [ruler]
	g.boss_system.step(g,0.01)
	check(is_equal_approx(ruler.fury_multiplier,1.3), "old-world13 hadal ally condition follows current world11")

# This fixture shoots production level1 bullets through real collision geometry,
# advances real phase locks and entry/defeat timers, and never edits boss HP.
# It isolates aim/survival, so it is not a claimed human campaign playthrough.
func defeat_with_primary(g, max_seconds: float = 1200.0) -> Dictionary:
	var phases = {}
	var attacks = false
	var initial_hp = {}
	var initial_patterns = {}
	for e in g.enemies:
		if e.get("boss",false):
			initial_hp[e.id] = e.max_hp
			initial_patterns[e.id] = e.config.fases.duplicate(true)
	var elapsed = 0.0
	while g.state == "boss" and elapsed < max_seconds:
		var dt = 1.0/30.0
		g.invulnerability = 1.0
		g.phase_clock += dt
		g.boss_system.step(g, dt)
		attacks = attacks or not g.enemy_bullets.is_empty() or not g.hazards.is_empty()
		for e in g.enemies:
			if not e.get("boss",false) or e.hp <= 0:
				continue
			phases[int(e.phase)] = true
			if e.get("inactive",false) or e.entry > 0 or e.lock > 0:
				continue
			var rects: Array = g.enemy_hit_rects(e)
			if rects.is_empty():
				continue
			var target: Vector2 = rects[0].get_center()
			g.player.pos = target - Vector2(40,0)
			g.shot_clock -= dt
			if g.shot_clock <= 0:
				g.shoot_primary()
			break
		g.step_projectiles(dt)
		g.step_enemies(dt)
		g.step_hazards(dt)
		elapsed += dt
		# Attack emission is checked above; survival/aim are isolated fixtures.
		# Recycle enemy shots rather than retaining irrelevant survival work.
		g.clear_enemy_bullets(false)
	for e in g.enemies:
		if initial_hp.has(e.id):
			check(e.max_hp == initial_hp[e.id] or (e.flags.get("fusion",false) and is_equal_approx(e.max_hp,float(initial_hp.values().reduce(func(a,b): return a+b,0.0)))), "combat fixture preserves production boss HP/fusion group total")
			# Fusion changes archetype/body as designed, never the configured phase table.
			check(e.config.fases == initial_patterns[e.id], "combat fixture preserves configured phases/attacks")
	print("COMBAT world%d room%d %.2fs state=%s" % [g.profile.world,g.profile.lab_boss,elapsed,g.state])
	return {"phases":phases,"attacks":attacks,"seconds":elapsed}

func start_final(g):
	g.state = "alert"
	g.phase_clock = float(g.data.combat.timings.alert)
	g.boss_system.step(g, 0.0)

func test_combat_victory():
	var g = make_game()
	for i in range(340):
		g.stage_system.step(g,0.5)
	check(g.world_time == 170.0 and g.regular_spawned == 90 and g.state == "alert", "W01 ninety regular actors and final alert170")
	start_final(g)
	check(g.enemies.any(func(e): return e.id == "boss_w01_nereis" and e.hp == 2319), "W01 preserves mandatory Nereis production HP")
	# Keep only final actors to isolate the collision fixture from stage clutter.
	g.enemies = g.enemies.filter(func(e): return e.get("boss",false))
	var combat = defeat_with_primary(g)
	check(g.state == "results" and g.profile.cleared.has(1), "production primary collisions defeat real final and grant results")
	check(combat.phases.has(1) and combat.phases.has(2) and combat.phases.has(3) and combat.attacks, "Nereis executes all phases and real attacks before defeat")
	check(g.mini_spawn_count == 0 and g.boss_spawn_count == 1 and not g.mini_defeated, "real combat never spawns/defeats a mini")
	var credits = float(g.profile.credits)
	g.finish_encounter()
	check(g.profile.credits == credits, "results cannot reward same encounter twice")
	g.continue_campaign()
	check(g.profile.world == 2 and g.state == "playing", "completed final permits world progression")

func test_lab_progression_and_rewards():
	var g = make_game(12, 1)
	check(g.state == "alert" and not g.mini_defeated and not g.mini_spawned, "resuming laboratory room2 enters alert without fake mini checkpoint")
	var world_cleared = g.profile.cleared.duplicate()
	for room in range(3):
		g = make_game(12, room)
		g.profile.weapons.shot = 8
		g.profile.cleared = world_cleared
		start_final(g)
		var expected = 3 if room == 0 else 1
		check(g.boss_spawn_count == expected, "lab room%d spawns actual current group" % room)
		var combat = defeat_with_primary(g, 2200.0)
		check(g.state == "results" and g.profile.lab_boss == room+1, "lab room%d requires actual collision defeat before next rest" % room)
		check(combat.attacks, "lab group executes preserved production attacks")
		if room == 0:
			check(combat.phases.has(3), "three robotic bodies reach fusion phase")
		var expected_reward = float(g.world.sectores_jefes[room].base_monedas) * (1.2 if room > 0 else 0.6)
		check(is_equal_approx(float(g.profile.credits), expected_reward), "one final/lab reward, no automatic mini coins")
		world_cleared = g.profile.cleared.duplicate()
		var saved = g.profile.duplicate(true)
		var credits = float(saved.credits)
		# Retry a previously rewarded room after reload: including the0.6 extra.
		saved.lab_boss = room
		var restored = Game.new()
		restored.start(saved)
		start_final(restored)
		defeat_with_primary(restored,2200.0)
		check(is_equal_approx(float(restored.profile.credits),credits), "reloaded lab room cannot duplicate base, bonus or0.6 extra")
		g.continue_campaign()
		check(g.profile.world == (13 if room == 2 else 12), "dynamic three-room progression leads to escape13")
		if room < 2:
			check(g.profile.lab_boss == room+1 and g.state == "alert", "laboratory returns through rest to following real final")
		else:
			check(g.profile.lab_boss == 0 and g.state == "playing" and g.profile.cleared.has(12), "laboratory completed marker3 enters escape")

func test_skins_and_escape():
	for world_id in [3, 4, 6, 7, 10]:
		var g = make_game(world_id)
		g.profile.weapons.shot = 8
		start_final(g)
		defeat_with_primary(g, 2200.0)
		check(not g.profile.skins.has("coral") and not g.profile.skins.has("abisal"), "retired-world skins receive no invented new unlock")
		if world_id == 3: check(g.profile.skins.has("batiscafo_amarillo"), "kelp reward follows old4 to new3")
		if world_id == 7: check(g.profile.skins.has("bioluminiscente"), "biolum reward follows campaign map")
		if world_id == 10: check(g.profile.skins.has("magma"), "magma reward follows campaign map")
	var g = make_game(13)
	g.finish_escape()
	check(g.state == "playing" and not g.profile.completed, "escape cannot complete before its real duration")
	for i in range(600):
		g.stage_system.step(g,0.5)
	check(g.state == "victory" and g.profile.completed and g.regular_spawned == 90, "escape13 runs300seconds/90regulars and reaches ending")
	check(g.profile.escape_score == 1000 and g.boss_spawn_count == 0 and g.mini_spawn_count == 0, "escape awards completion score without encounters")
	# Completed profiles still cannot turn a live replay into victory/advance.
	g = make_game(1)
	g.profile.completed = true
	g.continue_campaign()
	check(g.state == "playing" and g.profile.world == 1, "completed flag cannot bypass active encounter guard")

func test_replay():
	var g = make_game(10)
	g.profile.cleared = [1,3,7,10,12]
	g.profile.skins.append_array(["coral","abisal"])
	g.profile.credits = 100.0
	g.profile.resume = "rest"
	g.state = "rest"
	var progress = g.profile.duplicate(true)
	g.begin_replay(13)
	check(g.profile == progress and not g.replay, "escape is not an ordinary replay target")
	g.begin_replay(1)
	g.profile.weapons.shot = 8
	g.add_coins(70.0)
	var reloaded = Game.new()
	reloaded.start(g.profile.duplicate(true))
	check(reloaded.replay and reloaded.replay_earned == 70.0, "replay reload preserves earned cap and return progress")
	g = reloaded
	start_final(g)
	defeat_with_primary(g)
	check(g.state == "results" and is_equal_approx(g.profile.credits,250.0) and is_equal_approx(g.replay_earned,150.0), "replay stage plus final is capped at50percent once per visit")
	g.finish_encounter()
	check(is_equal_approx(g.profile.credits,250.0), "repeated replay results cannot duplicate its reward")
	g.continue_campaign()
	check(not g.replay and g.profile.world == 10 and g.profile.cleared == progress.cleared and g.state == "rest" and g.profile.resume == "rest", "replay returns to original campaign rest/progression")
	check(g.profile.skins.has("coral") and g.profile.skins.has("abisal"), "historically acquired removed-world skins survive replay")
	check(is_equal_approx(g.profile.credits,250.0) and g.profile.weapons == progress.weapons, "replay keeps earned credits and original campaign weapons")
	# Later lab rooms use their own base and preserve the cap after reload.
	g = make_game(12,1)
	g.profile.replay_mode = true
	g.start(g.profile)
	g.add_coins(100.0)
	reloaded = Game.new()
	reloaded.start(g.profile.duplicate(true))
	reloaded.add_coins(10000.0)
	reloaded.add_coins(10000.0)
	check(reloaded.replay_earned == 800.0 and reloaded.profile.credits == 800.0, "laboratory room replay cap is idempotent across reload")

func reload_replay_profile(p: Dictionary, label: String) -> Dictionary:
	var saved = Saves.save_slot(3,p)
	check(saved.ok, label+" saves real v3 profile: "+str(saved.error))
	if not saved.ok:
		return p.duplicate(true)
	var loaded = Saves.load_slot(3)
	check(loaded.ok, label+" loads real v3 profile: "+str(loaded.error))
	return loaded.profile if loaded.ok else p.duplicate(true)

func test_replay_return_states():
	# Preserve both generations of the isolated test slot; no user slot leakage.
	var originals = {}
	for base_path in [Saves.file_path(3),Saves.legacy_file_path(3)]:
		for suffix in ["",".bak",".tmp"]:
			var path = base_path+suffix
			originals[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for old_world in [3,6]:
		var destination = 2 if old_world == 3 else 4
		var old_origin = Shop.create_profile()
		old_origin.version = 2
		old_origin.world = old_world
		old_origin.resume = "rest"
		old_origin.cleared = range(1,old_world+1)
		old_origin.entry_world = old_world
		old_origin.world_elapsed = 199.0
		old_origin.checkpoint = {"time":90.0,"cursor":8}
		var old_active = Shop.create_profile()
		old_active.version = 2
		old_active.world = 1
		old_active.weapons.shot = 8
		old_active.resume = "playing"
		old_active.replay_mode = true
		old_active.replay_return = old_origin
		# Exercise the real recursive v2->v3 migration, including removed rests.
		var imported = Saves.preview_import(3,JSON.stringify(old_active))
		check(imported.ok and imported.migrated, "legacy replay with nested old%d rest imports: %s" % [old_world,str(imported.error)])
		if not imported.ok:
			continue
		var nested: Dictionary = imported.profile.replay_return
		check(nested.world == destination and nested.resume == "playing" and not nested.has("checkpoint") and nested.world_elapsed == 0.0, "old%d nested rest migrates to safe current%d playing entry" % [old_world,destination])
		var g = Game.new()
		g.start(reload_replay_profile(imported.profile,"migrated replay old%d" % old_world))
		start_final(g)
		var combat = defeat_with_primary(g)
		check(g.state == "results" and combat.phases.has(3) and combat.attacks, "migrated replay completes real Nereis weapons/collisions/phases")
		g.continue_campaign()
		check(not g.replay and g.state == "playing" and g.profile.resume == "playing" and g.profile.world == destination, "old%d replay returns to safe current%d playing entry without advancing" % [old_world,destination])
		check(g.world_time == 0.0 and g.cursor == 0 and not g.boss_spawned and g.enemies.is_empty(), "safe return starts a fresh entry rather than retaining replay actors/time")
		g.continue_campaign()
		check(g.profile.world == destination and g.state == "playing", "Next cannot skip migrated current%d entry before victory" % destination)
		if g.state == "playing" and g.profile.world == destination:
			g.step(0.5,{})
			check(g.world_time == 0.5, "safe migrated entry actually resumes stage simulation")
		var restored = reload_replay_profile(g.profile,"returned entry old%d" % old_world)
		check(restored.world == destination and restored.resume == "playing" and not restored.get("replay_mode",false), "safe return remains playing across another save/load")
	for resume in ["rest","completed"]:
		var origin = Shop.create_profile()
		origin.world = 13 if resume == "completed" else 10
		origin.resume = resume
		origin.completed = resume == "completed"
		origin.cleared = range(1,13) if origin.completed else [1,10]
		origin.escape_score = 1000 if origin.completed else 0
		origin.weapons.shot = 8
		var g = Game.new()
		g.start(reload_replay_profile(origin,"original "+resume))
		g.state = "victory" if resume == "completed" else "rest"
		g.begin_replay(1)
		check(g.replay_return.resume == resume and origin.resume == resume, "begin_replay snapshots original "+resume+" before active resume changes")
		check(g.profile.resume == "playing" and g.state == "playing", "active replay from "+resume+" is explicitly saved as playing")
		g.start(reload_replay_profile(g.profile,"active replay from "+resume))
		check(g.replay and g.replay_return.resume == resume and g.profile.resume == "playing", "saved active replay preserves "+resume+" return marker")
		start_final(g)
		defeat_with_primary(g)
		g.continue_campaign()
		var expected_state = "victory" if resume == "completed" else "rest"
		check(not g.replay and g.state == expected_state and g.profile.resume == resume and g.profile.world == origin.world, "finished replay honors original "+resume+" state/progression")
		check(g.profile.completed == origin.completed and g.profile.cleared == origin.cleared and g.profile.escape_score == origin.escape_score, "replay preserves original completion, cleared worlds and escape score")
		var restored = reload_replay_profile(g.profile,"returned "+resume)
		check(restored.resume == resume and restored.completed == origin.completed and restored.world == origin.world, "returned "+resume+" survives real save/load")
		g.continue_campaign()
		check(g.state == ("victory" if resume == "completed" else "playing") and g.profile.world == (13 if resume == "completed" else 11), "Next retains completed ending or advances normal earned rest once")
	for path in originals:
		if originals[path] == null:
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		else:
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(str(path).get_base_dir()))
			var file = FileAccess.open(path,FileAccess.WRITE)
			file.store_buffer(originals[path])
			file.close()

func finish():
	if failures.is_empty():
		if OS.get_cmdline_user_args().has("--replay-returns-only"):
			print("CAMPAIGN12 REPLAY RETURNS PASS: %d checks;v2 nested removed rests return to safe entries, active/rest/completed save/load, real collision victories" % checks)
		else:
			print("CAMPAIGN12 PASS: %d checks;12worlds/zero minis, mandatory collision victories, legacy stats/UIDs, lab3/escape13, idempotent rewards" % checks)
		quit(0)
	else:
		for failure in failures:
			printerr("FAIL: ", failure)
		printerr("CAMPAIGN12 FAIL: %d failures / %d checks" % [failures.size(), checks])
		quit(1)
