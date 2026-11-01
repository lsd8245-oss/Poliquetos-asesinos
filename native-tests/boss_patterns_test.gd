extends SceneTree

const PROFILES = ["nereis", "capit", "polyn", "tere", "hermo", "leafqueen", "orbin", "pollutionCapit", "pollutionSpio", "pollutionCirrat", "tomo", "eulagisca", "osedax", "alvinella", "hadalsovereign", "riftia", "robot_pinza", "robot_torreta", "robot_taladro", "epitoke", "scientist", "euniceTitan"]
var failures: Array[String] = []
var patterns: GDScript
var context = {"player": Vector2(100, 160), "time": 0.0, "width": 640.0, "height": 336.0, "bullet_speed": 110.0, "survivors": 3}

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func boss(profile: String, phase: int = 1) -> Dictionary:
	return {"pos": Vector2(500, 168), "phase": phase, "age": 0.0, "attack_clock": 0.0, "config": {"arquetipo": profile}, "size": Vector2(140, 100), "hp": 100.0, "max_hp": 100.0}

func simulate(entity: Dictionary, duration: float = 8.0) -> Array:
	var actions: Array = []
	for index in range(int(duration / 0.05)):
		context.time = float(index) * 0.05
		actions.append_array(patterns.step(entity, context, 0.05))
	return actions

func count_kind(actions: Array, kind: String) -> int:
	var total = 0
	for action in actions:
		if action.kind == kind:
			total += 1
	return total

func _initialize() -> void:
	if not FileAccess.file_exists("res://src/bosses/patterns.gd"):
		printerr("FAIL: boss patterns implementation is missing")
		quit(1)
		return
	patterns = load("res://src/bosses/patterns.gd")
	if patterns == null:
		printerr("FAIL: boss patterns script did not load")
		quit(1)
		return
	var signatures = {}
	for profile in PROFILES:
		var previous_signature = ""
		for phase in range(1, 5 if profile == "euniceTitan" else 4):
			var entity = boss(profile, phase)
			var actions = simulate(entity)
			check(not actions.is_empty(), "%s phase %d emits attacks" % [profile, phase])
			check(is_equal_approx(entity.age, 8.0), "%s updates age" % profile)
			check(entity.hp == 100.0 and entity.phase == phase, "%s leaves HP and phases to engine" % profile)
			var hazard_effects = []
			var bullet_total = 0
			for action in actions:
				check(action.kind in ["bullet", "hazard", "spawn", "notice"], "valid action kind")
				if action.kind == "bullet":
					bullet_total += 1
					check(action.pos is Vector2 and action.velocity is Vector2 and action.ttl > 0, "valid bullet geometry")
					check(action.has("homing") and action.has("bounce") and action.has("slow"), "complete bullet fields")
				elif action.kind == "hazard":
					hazard_effects.append(action.effect)
					check(action.rect is Rect2 and action.duration > 0 and action.delay >= 0, "valid hazard geometry")
					if action.get("strong", false):
						check(action.delay >= 0.5, "%s warns before strong hazard" % profile)
			var signature = str([bullet_total, count_kind(actions, "spawn"), hazard_effects, entity.pos.round(), entity.get("flags", {})])
			check(signature != previous_signature, "%s changes behavior in phase %d" % [profile, phase])
			previous_signature = signature
			if phase == 1:
				signatures[profile] = signature
	check(signatures.values().size() == PROFILES.size(), "all profiles exercised")
	for a in PROFILES:
		for b in PROFILES:
			if a < b:
				check(signatures[a] != signatures[b], "%s and %s have distinct behavior" % [a, b])
	var charging = boss("nereis", 2)
	charging.attack_clock = 100.0
	var start: Vector2 = charging.pos
	var warnings: Array = patterns.step(charging, context, 0.01)
	check(count_kind(warnings, "hazard") > 0, "charge creates warning")
	patterns.step(charging, context, 0.35)
	check(charging.pos.distance_to(start) < 30.0, "charge cannot cross screen before warning expires")
	patterns.step(charging, context, 0.2)
	patterns.step(charging, context, 0.2)
	check(charging.pos.x < start.x - 30.0, "charge moves after warning")
	var ice = simulate(boss("eulagisca"), 5.0)
	for action in ice:
		if action.kind == "hazard":
			check(action.delay >= 0.7, "stalactites have 0.7 s warning")
	var grapple = simulate(boss("tere", 2))
	check(grapple.any(func(action): return action.kind == "hazard" and action.effect == "grapple" and action.get("release_on_weak_hit", false)), "tentacles release when weak tip hit")
	var tentacles = boss("tere", 1)
	patterns.step(tentacles, context, 0.05)
	check(tentacles.flags.weak_points.size() == 8, "all eight tentacle tips are weak points")
	var armored = boss("polyn", 2)
	patterns.step(armored, context, 0.05)
	check(armored.flags.armor and not armored.flags.weak_exposed, "elytra initially cover weak points")
	patterns.step(armored, context, 4.0)
	check(armored.flags.weak_exposed, "elytra open after four seconds")
	var hidden = boss("tomo", 2)
	patterns.step(hidden, context, 0.05)
	var first_visibility: bool = hidden.flags.invisible
	patterns.step(hidden, context, 2.0)
	check(hidden.flags.invisible != first_visibility, "Tomopteridae toggles visibility each two seconds")
	var group = boss("pollutionCapit", 3)
	context.survivors = 1
	var combined = simulate(group)
	check(count_kind(combined, "spawn") > 0 and count_kind(combined, "bullet") > 0 and count_kind(combined, "hazard") > 0, "last pollution survivor uses all three patterns")
	var solo = boss("pollutionSpio", 1)
	var furious = boss("pollutionSpio", 1)
	context.survivors = 3
	var solo_actions = simulate(solo, 12.0)
	context.survivors = 2
	var fury_actions = simulate(furious, 12.0)
	check(count_kind(fury_actions, "bullet") > count_kind(solo_actions, "bullet"), "pollution death increases cadence by 25 percent")
	context.survivors = 3
	var nereis_burst = boss("nereis", 1)
	nereis_burst.attack_clock = 2.0
	var burst_start: Array = patterns.step(nereis_burst, context, 0.01)
	check(count_kind(burst_start, "bullet") == 1, "Nereis starts a three-shot aimed burst")
	var burst_followup = simulate(nereis_burst, 0.5)
	check(count_kind(burst_followup, "bullet") == 2, "Nereis burst fires remaining shots over time")
	var bristles = boss("hermo", 3)
	var before_ring = simulate(bristles, 4.9)
	check(not before_ring.any(func(action): return action.kind == "bullet" and action.velocity.y < 0), "Hermodice waits five seconds before expanding ring")
	var after_ring: Array = patterns.step(bristles, context, 0.15)
	check(count_kind(after_ring, "bullet") == 16, "Hermodice emits expanding ring at five seconds")
	var final_boss = boss("euniceTitan", 4)
	var final_start: Vector2 = final_boss.pos
	var finale = simulate(final_boss)
	check(final_boss.pos == final_start and count_kind(finale, "bullet") > 0 and count_kind(finale, "hazard") > 0, "Eunice fury stays still and combines rings and jaws")
	var mini = boss("mini", 2)
	mini.config = {"arquetipo": "mini", "mini_tipo": "glycera", "movimiento": "M3", "disparo": "F5"}
	var mini_actions = simulate(mini)
	check(count_kind(mini_actions, "bullet") > 0 and count_kind(mini_actions, "hazard") > 0, "miniboss enlarges original attacks and telegraphs charge")
	var mini_burst = boss("mini_m3", 1)
	mini_burst.config.disparo = "F5"
	mini_burst.attack_clock = 2.5
	check(count_kind(patterns.step(mini_burst, context, 0.01), "bullet") == 1, "F5 miniboss firing is a timed burst")
	check(count_kind(simulate(mini_burst, 0.5), "bullet") == 2, "F5 miniboss completes three-shot burst")
	var burrow_mini = boss("mini_m6", 1)
	burrow_mini.config.movimiento = "M6"
	burrow_mini.config.disparo = "F1"
	patterns.step(burrow_mini, context, 0.1)
	check(burrow_mini.flags.invisible, "burrowing miniboss stays concealed during emerge warning")
	patterns.step(burrow_mini, context, 0.5)
	check(not burrow_mini.flags.invisible, "burrowing miniboss emerges after warning")
	var robot_mini = boss("mini_robot", 2)
	var robot_actions = simulate(robot_mini)
	check(count_kind(robot_actions, "bullet") > 0 and count_kind(robot_actions, "hazard") > 0, "laboratory miniboss combines pursuit, jaw burst and charge")
	var stationary = boss("riftia")
	patterns.step(stationary, context, 0.05)
	var paused = stationary.duplicate(true)
	check(patterns.step(stationary, context, 0.0).is_empty() and stationary == paused, "zero delta has no effects")
	if failures.is_empty():
		print("PASS: boss patterns, 22 profiles, 67 phases, telegraphs, groups, minibosses")
		quit(0)
	else:
		for failure in failures:
			printerr("FAIL: ", failure)
		quit(1)
