extends SceneTree

const Indicators = preload("res://src/visuals/state_indicators.gd")
const Assets = preload("res://src/core/assets.gd")
const Game = preload("res://src/core/game.gd")
const Shop = preload("res://src/shop/shop.gd")
var failures: Array[String] = []

class RecordingAssets extends RefCounted:
	var sprites: Array = []
	var captions: Array = []
	func sprite(_canvas, key, rect, time, tint):
		sprites.append({"key": key, "rect": rect, "time": time, "tint": tint})
	func text(_canvas, value, pos, tint):
		captions.append({"value": value, "pos": pos, "tint": tint})

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func actor(extra: Dictionary = {}) -> Dictionary:
	var result := {"hp": 10.0, "pos": Vector2(300, 150), "size": Vector2(48, 48), "age": 2.0}
	result.merge(extra, true)
	return result

func kinds(descriptors: Array[Dictionary]) -> Array:
	return descriptors.map(func(row): return row.kind)

func _initialize() -> void:
	check(Indicators.describe(actor(), false, 2.0).is_empty(), "ordinary creature has no decorative aura")
	var actual_assets := Assets.new()
	actual_assets.load_all()
	var keys: Array = []
	for item in ["rojo", "verde", "azul"]:
		var descriptors := Indicators.describe(actor({"carrier": item}), false, 2.0)
		check(kinds(descriptors) == ["loot"], "carrier only receives loot marker")
		var loot: Dictionary = descriptors[0]
		keys.append(loot.key)
		check(actual_assets.has_sprite(loot.key), "loot reuses existing PNG")
		check(loot.rect.size == Vector2(10, 10), "loot marker is 10 px, not body halo")
		check(loot.rect.position.x > 300 and loot.rect.end.y < 150, "loot badge occupies actor corner")
		check(loot.time == 0.0 and loot.tint == Color.WHITE, "loot stays steady with original icon colours")
		check(not str(loot.text).contains("_"), "caption has no technical identifier")
	check(keys.size() == 3 and keys[0] != keys[1] and keys[1] != keys[2] and keys[0] != keys[2], "loot types differ by shape, not just colour")
	check(Indicators.describe(actor({"carrier": "unknown"}), false, 2.0).is_empty(), "unknown loot does not fabricate a marker")
	var warning := Indicators.describe(actor({"warning": true}), false, 2.0)
	check(kinds(warning) == ["warning"], "warning remains separate from loot")
	check(actual_assets.has_sprite(warning[0].key), "warning reuses existing PNG")
	var flags := {"weak_exposed": true, "weak_points": [Vector2(260, 150), Vector2(275, 160)]}
	var weak_actor := actor({"flags": flags})
	check(Indicators.describe(weak_actor, false, 2.0).is_empty(), "no weak point markers without CTD")
	var weak := Indicators.describe(weak_actor, true, 2.0)
	check(kinds(weak) == ["weak", "weak"], "CTD identifies every exposed weak point")
	var reduced_weak := Indicators.describe(weak_actor, true, 2.0, true)
	check(reduced_weak[0].tint.a <= 0.65 and reduced_weak[0].time == 0.0, "reduced weak marker is faint and steady")
	check(weak[0].rect.get_center() == flags.weak_points[0], "weak marker follows exact weak point")
	check(actual_assets.has_sprite(weak[0].key), "weak marker reuses existing PNG")
	check(weak[0].key != warning[0].key and weak[0].key not in keys and warning[0].key not in keys, "states never share an indicator PNG")
	for extra in [{"flags": {"weak_points": flags.weak_points}}, {"flags": {"weak_exposed": false, "weak_points": flags.weak_points}}, {"flags": flags, "lock": 1.0}, {"flags": flags, "entry": 1.0}, {"flags": {"weak_exposed": true, "weak_points": flags.weak_points, "invisible": true}}]:
		check(Indicators.describe(actor(extra), true, 2.0).is_empty(), "closed, missing, locked, entering or invisible weakness is not marked")
	var hidden := Indicators.describe(actor({"hidden": true, "warning": true, "carrier": "rojo", "flags": flags}), true, 2.0)
	check(kinds(hidden) == ["warning"] and hidden[0].rect.position.y == 312, "hidden M6 only warns at emergence location")
	for extra in [{"hp": 0, "warning": true}, {"inactive": true, "carrier": "rojo"}]:
		check(Indicators.describe(actor(extra), true, 2.0).is_empty(), "dead or inactive actor has no indicators")
	var waiting := actor({"_charge": {"wait": 0.5, "left": 0.85}})
	check(kinds(Indicators.describe(waiting, false, 2.0)) == ["warning"], "boss charge wait shows attack warning")
	waiting._charge.wait = 0.0
	check(Indicators.describe(waiting, false, 2.0).is_empty(), "charge warning ends when wait expires")
	check(Indicators.describe(actor({"lock": 3.0, "_charge": {"wait": 0.5}}), false, 2.0).is_empty(), "phase lock suppresses stale charge preparation")
	for time in [0.0, 0.07, 0.2, 0.37, 1.23]:
		var reduced := Indicators.describe(actor({"warning": true}), false, time, true)[0]
		check(reduced.tint.a <= 0.35 and reduced.time == 2.0 / 12.0, "reduced warning caps opacity and freezes flicker")
		check(is_equal_approx(Indicators.actor_tint(actor({"lock": 3.0}), time, true).a, 0.72), "reduced invulnerability has steady opacity")
		check(Indicators.actor_tint(actor({"lock": 3.0}), time).a >= 0.59, "normal invulnerability remains subtle")
	var combined := actor({"carrier": "azul", "warning": true, "flags": flags})
	var snapshot := combined.duplicate(true)
	var first := Indicators.describe(combined, true, 7.25)
	check(first == Indicators.describe(combined, true, 7.25), "frozen pause clock gives identical descriptors")
	Indicators.actor_tint(combined, 7.25)
	var recording := RecordingAssets.new()
	Indicators.draw(null, recording, first)
	check(recording.sprites.size() == first.size() and recording.captions.size() == 1, "draw composes only PNG sprites and bitmap caption")
	check(combined == snapshot, "describe, tint and draw never mutate simulation")
	var game := Game.new()
	game.start(Shop.create_profile())
	var live_actor: Dictionary = game.stage_system.spawn_enemy(game, "euphrosine", Vector2(480, 150))
	game.step(1.1)
	check(kinds(Indicators.describe(live_actor, false, game.total_time)) == ["warning"], "real W01 M7 simulation supplies warning state")
	game.pause()
	var paused_time: float = game.total_time
	var paused_actor := live_actor.duplicate(true)
	var paused_descriptors := Indicators.describe(live_actor, false, paused_time)
	game.step(1.0)
	check(game.total_time == paused_time and live_actor == paused_actor, "simulation pause freezes actor and supplied visual clock")
	check(Indicators.describe(live_actor, false, game.total_time) == paused_descriptors, "paused real simulation produces identical warning frame")
	game.unpause()
	game.step(0.5)
	check(game.total_time == paused_time and live_actor == paused_actor, "resume countdown also freezes supplied visual clock")
	for pos in [Vector2(0, 0), Vector2(639, 335)]:
		var loot := Indicators.describe(actor({"carrier": "azul", "pos": pos}), false, 2.0)[0]
		check(Rect2(0, 0, 640, 336).encloses(loot.rect), "loot icon stays inside combat viewport")
		check(loot.text_pos.x + 30 <= 640 and loot.text_pos.y + 9 <= 336, "loot caption stays inside combat viewport")
	if failures.is_empty():
		print("STATE INDICATORS PASS: loot, warning, CTD weakness, lock, reduced flashes and read-only pause clock")
	else:
		for failure in failures:
			printerr("FAIL: " + failure)
	quit(0 if failures.is_empty() else 1)
