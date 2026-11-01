extends SceneTree
const Game = preload("res://src/core/game.gd")
const Shop = preload("res://src/shop/shop.gd")
const Patterns = preload("res://src/bosses/patterns.gd")
var failures: Array[String] = []

func check(value: bool, text: String) -> void:
	if not value:
		failures.append(text)

func make_game(world: int, lab: int = 0):
	var p = Shop.create_profile()
	p.world = world
	p.lab_boss = lab
	var g = Game.new()
	g.start(p)
	return g

func spawn(g, id: String) -> Dictionary:
	g.boss_system.spawn(g, id)
	var e: Dictionary = g.enemies.back()
	e.entry = 0.0
	return e

func active_robots(g) -> Array:
	return g.enemies.filter(func(e): return e.get("boss", false) and e.hp > 0 and not e.get("inactive", false))

func _initialize() -> void:
	var g = make_game(3)
	var armored = spawn(g, "boss_w03_polyn")
	armored.phase = 2
	g.boss_system.step(g, 0.05)
	var point: Vector2 = armored.flags.weak_points[0]
	var hp: float = armored.hp
	g.hit_enemy(armored, 10.0, point)
	check(is_equal_approx(hp - armored.hp, 5.0), "closed elytra reduce weak-point damage to body multiplier")
	g.boss_system.step(g, 4.0)
	point = armored.flags.weak_points[0]
	hp = armored.hp
	g.hit_enemy(armored, 10.0, point)
	check(is_equal_approx(hp - armored.hp, 20.0), "natural four-second opening receives double weak damage")
	armored.armor_open = 1.0
	armored.flags.weak_exposed = false
	hp = armored.hp
	g.hit_enemy(armored, 10.0, point)
	check(is_equal_approx(hp - armored.hp, 20.0), "bomb opening receives double weak damage")
	g = make_game(1)
	var split = spawn(g, "boss_w01_nereis")
	split.phase = 3
	split.attack_clock = 3.0
	g.boss_system.step(g, 0.05)
	check(split.get("parts", []).size() == 2, "Nereis phase three has two physical bodies")
	if split.get("parts", []).size() == 2:
		var first: Vector2 = split.parts[0].pos
		var second: Vector2 = split.parts[1].pos
		g.player.pos = Vector2(50, 70)
		g.boss_system.step(g, 0.5)
		check(split.parts[0].pos != first and split.parts[1].pos != second, "both Nereis bodies move")
		check(not (split.parts[0].pos - first).is_equal_approx(split.parts[1].pos - second), "Nereis bodies pursue independently")
		check(g.enemy_bullets.size() == 24, "both Nereis bodies fire twelve-shot rings")
	if g.boss_system.has_method("hit_rects"):
		var rects: Array = g.boss_system.hit_rects(g, split)
		for part in split.get("parts", []):
			check(rects.any(func(r): return r.has_point(part.pos)), "split body is in collision geometry")
		check(not rects.any(func(r): return r.has_point(split.pos)), "space between split segments is not a phantom full-body hitbox")
	else:
		check(false, "adapter exposes actual boss hit rectangles")
	g = make_game(4)
	var tentacles = spawn(g, "boss_w04_tere")
	g.boss_system.step(g, 0.05)
	check(tentacles.flags.weak_points.size() == 8, "all tentacle tips exist")
	if g.boss_system.has_method("hit_rects"):
		var rects: Array = g.boss_system.hit_rects(g, tentacles)
		for tip in tentacles.flags.weak_points:
			check(rects.any(func(r): return r.has_point(tip)), "each tip can be hit outside the original boss body")
		var tip: Vector2 = tentacles.flags.weak_points[0]
		hp = tentacles.hp
		g.hit_enemy(tentacles, 10.0, tip)
		check(is_equal_approx(hp - tentacles.hp, 20.0), "tentacle tip receives double damage")
	g = make_game(14, 3)
	var eunice = spawn(g, "boss_w14_eunice_titan")
	check(not eunice.get("parts", []).is_empty(), "Eunice already has antenna geometry during entry")
	g.boss_system.step(g, 0.05)
	if not eunice.get("parts", []).is_empty():
		for part in eunice.parts:
			check(part.size.x < eunice.size.x * 0.25 and part.size.y < eunice.size.y * 0.5, "phase-one Eunice renders antenna-sized parts")
		check(eunice.flags.weak_points.size() == eunice.parts.size(), "each visible antenna has a reachable weak point")
	g = make_game(14)
	g.state = "alert"
	g.phase_clock = 6
	g.boss_system.step(g, 0.0)
	var robots = g.enemies.filter(func(e): return e.get("boss", false))
	check(robots.size() == 3, "robot factory preserves all three boss records")
	var group_max = 0.0
	for robot in robots:
		group_max += robot.max_hp
	check(robots[0].entry < robots[1].entry and robots[1].entry < robots[2].entry, "robot initial entries are sequential")
	g.boss_system.step(g, 0.05)
	check(active_robots(g).size() == 1, "robot phase one activates one body")
	var initial_active = active_robots(g)[0]
	for robot in robots:
		robot.entry = 0.0
	for index in range(160):
		g.boss_system.step(g, 0.05)
	check(active_robots(g).size() == 1 and active_robots(g)[0].uid != initial_active.uid, "phase-one active robot rotates")
	var active = active_robots(g)[0]
	var inactive_candidates = robots.filter(func(e): return e.get("inactive", false))
	var inactive: Dictionary = inactive_candidates[0] if not inactive_candidates.is_empty() else robots[1]
	hp = inactive.hp
	g.hit_enemy(inactive, 100.0, inactive.pos)
	check(inactive.hp == hp, "inactive robot cannot be damaged")
	g.hit_enemy(active, group_max * 10.0, active.pos)
	check(robots.all(func(e): return e.phase == 2 and e.lock > 0), "group damage stops at second phase with shared invulnerability")
	var phase_two_hp = 0.0
	for robot in robots:
		phase_two_hp += robot.hp
	check(is_equal_approx(phase_two_hp, group_max * 0.66), "robot group damage preserves the 66-percent HP gate")
	g.boss_system.step(g, 0.05)
	check(active_robots(g).size() == 2, "robot phase two activates two bodies")
	var first_pair = active_robots(g).map(func(e): return e.uid)
	for index in range(100):
		g.boss_system.step(g, 0.05)
	check(active_robots(g).map(func(e): return e.uid) != first_pair, "phase-two pair rotates")
	active = active_robots(g)[0]
	g.hit_enemy(active, group_max * 10.0, active.pos)
	var live = robots.filter(func(e): return e.hp > 0)
	check(live.size() == 1, "third phase physically fuses into one body")
	if live.size() == 1:
		var fused: Dictionary = live[0]
		check(fused.phase == 3 and fused.config.arquetipo == "robot_pinza" and fused.lock > 0, "fusion uses all-pattern archetype and phase lock")
		check(is_equal_approx(fused.hp, group_max * 0.33), "fusion conserves remaining group HP")
		check(robots.filter(func(e): return e.get("fused", false) and e.hp == 0).size() == 2, "fusion donors retire without being killed")
		for donor in robots.filter(func(e): return e.get("fused", false)):
			check(g.boss_system.hit_rects(g, donor).is_empty(), "retired fusion donors have no collision bodies")
		check(not robots.any(func(e): return e.get("counted_dead", false)), "fusion cannot award kill rewards for donors")
		var fusion_hp: float = fused.hp
		g.hit_enemy(fused, group_max * 10.0, fused.pos)
		check(fused.hp == fusion_hp, "fusion cannot skip three-second invulnerability")
		g.boss_system.step(g, 3.1)
		g.boss_system.step(g, 0.05)
		fused.attack_clock = 4.0
		g.boss_system.step(g, 0.05)
		check(g.enemy_bullets.size() > 0 and g.hazards.any(func(h): return h.get("charge", false)) and g.hazards.any(func(h): return h.effect == "laser"), "fused robot executes pinza, taladro and torreta attacks")
	if failures.is_empty():
		print("BOSS INTEGRATION PASS: exposed armor, physical split/tips/antennae, robot sequence/pairs/fusion/HP gates")
		quit(0)
	else:
		for failure in failures:
			printerr("FAIL: ", failure)
		quit(1)
