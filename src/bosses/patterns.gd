class_name PoliBossPatterns
extends RefCounted
## Deterministic boss choreography. The simulation owns health, phase transitions,
## entrance/death and collision resolution; this module only emits actions.

const Data = preload("res://src/core/data.gd")
static var _data: Dictionary = {}

static func _settings(profile: String, config: Dictionary) -> Dictionary:
	if _data.is_empty():
		var parsed = Data.read_json("data/boss_patterns.json", {})
		if not parsed is Dictionary:
			push_error("Invalid data/boss_patterns.json")
			return {}
		if not parsed.has("defaults") or not parsed.has("profiles"):
			push_error("Missing boss pattern defaults/profiles")
			return {}
		_data = parsed
	var result: Dictionary = _data.defaults.duplicate(true)
	result.merge(_data.profiles.get(profile, _data.profiles.mini), true)
	result.merge(config.get("pattern_overrides", {}), true)
	return result

static func _v(settings: Dictionary, key: String) -> float:
	return float(settings[key])

static func _phase_value(settings: Dictionary, key: String, phase: int) -> float:
	var values: Array = settings[key]
	return float(values[clampi(phase - 1, 0, values.size() - 1)])

static func _mini_movement(config: Dictionary) -> String:
	var archetype = str(config.get("arquetipo", "mini_m2"))
	var fallback = "M3" if archetype == "mini_robot" else archetype.trim_prefix("mini_").to_upper()
	return str(config.get("movimiento", config.get("movement", fallback)))

static func _bullet(out: Array, pos: Vector2, velocity: Vector2, settings: Dictionary, extra: Dictionary = {}) -> void:
	var action = {"kind": "bullet", "pos": pos, "velocity": velocity, "ttl": _v(settings, "ttl"), "homing": 0.0, "bounce": 0, "slow": 1.0}
	action.merge(extra, true)
	out.append(action)

static func _fan(out: Array, pos: Vector2, player: Vector2, count: int, speed: float, settings: Dictionary, extra: Dictionary = {}, angle: float = INF) -> void:
	var center = pos.angle_to_point(player) if is_inf(angle) else angle
	var spread = deg_to_rad(_v(settings, "fan_degrees"))
	for index in range(count):
		var offset = 0.0 if count == 1 else (float(index) / float(count - 1) - 0.5) * spread
		_bullet(out, pos, Vector2.from_angle(center + offset) * speed, settings, extra)

static func _ring(out: Array, pos: Vector2, count: int, speed: float, settings: Dictionary, rotation: float = 0.0, extra: Dictionary = {}) -> void:
	for index in range(count):
		_bullet(out, pos, Vector2.from_angle(TAU * float(index) / float(count) + rotation) * speed, settings, extra)

static func _burst(out: Array, boss: Dictionary, context: Dictionary, settings: Dictionary, speed: float) -> void:
	_fan(out, boss.pos, context.player, 1, speed, settings)
	if not boss.has("_bursts"):
		boss._bursts = []
	boss._bursts.append({"wait": _v(settings, "burst_gap"), "left": int(settings.burst_count) - 1, "speed": speed})

static func _advance_bursts(out: Array, boss: Dictionary, context: Dictionary, settings: Dictionary, dt: float) -> void:
	var bursts: Array = boss.get("_bursts", [])
	for index in range(bursts.size() - 1, -1, -1):
		var burst: Dictionary = bursts[index]
		burst.wait -= dt
		while burst.wait <= 0.0 and burst.left > 0:
			_fan(out, boss.pos, context.player, 1, burst.speed, settings)
			burst.wait += _v(settings, "burst_gap")
			burst.left -= 1
		if burst.left <= 0:
			bursts.remove_at(index)

static func _hazard(out: Array, rect: Rect2, settings: Dictionary, effect: String = "damage", extra: Dictionary = {}) -> void:
	var action = {"kind": "hazard", "rect": rect, "delay": _v(settings, "telegraph"), "duration": _v(settings, "duration"), "effect": effect, "damage": _v(settings, "damage"), "direction": Vector2.ZERO, "strong": true}
	action.merge(extra, true)
	out.append(action)

static func _columns(out: Array, context: Dictionary, settings: Dictionary, count: int, ceiling: bool = false, effect: String = "damage", extra: Dictionary = {}) -> void:
	var width = float(context.get("width", 640.0))
	var height = float(context.get("height", 336.0))
	var column_width = _v(settings, "hazard_width")
	var column_height = _v(settings, "hazard_height")
	var player: Vector2 = context.player
	for index in range(count):
		var x = clampf(player.x - column_width * 0.5 if index == 0 else width * float(index) / float(count), 0, width - column_width)
		_hazard(out, Rect2(x, 0.0 if ceiling else height - column_height, column_width, column_height), settings, effect, extra)

static func _rain(out: Array, context: Dictionary, settings: Dictionary, count: int, speed: float, extra: Dictionary = {}) -> void:
	var width = float(context.get("width", 640.0))
	for index in range(count):
		var pos = Vector2(width * (float(index) + 0.5) / float(count), 0)
		_bullet(out, pos, Vector2(0, speed), settings, extra)

static func _charge(out: Array, boss: Dictionary, context: Dictionary, settings: Dictionary, diagonal: bool = false, slow: bool = false) -> void:
	if boss.has("_charge"):
		return
	var player: Vector2 = context.player
	var pos: Vector2 = boss.pos
	var direction = pos.direction_to(player) if diagonal else Vector2(-1, 0)
	var size: Vector2 = boss.get("size", Vector2(140, 100))
	var end = pos + direction * _v(settings, "charge_speed") * _v(settings, "charge_duration")
	var rect = Rect2(pos - size * 0.25, size * 0.5).merge(Rect2(end - size * 0.25, size * 0.5))
	var extra = {"direction": direction, "charge": true}
	if slow:
		extra.merge({"slow": _v(settings, "slow"), "slow_duration": _v(settings, "slow_duration")})
	_hazard(out, rect, settings, "slow" if slow else "damage", extra)
	boss._charge = {"wait": _v(settings, "telegraph"), "left": _v(settings, "charge_duration"), "velocity": direction * _v(settings, "charge_speed")}

static func _move_charge(boss: Dictionary, dt: float) -> bool:
	if not boss.has("_charge"):
		return false
	var charge: Dictionary = boss._charge
	var remaining = dt
	if charge.wait > 0.0:
		var waited = minf(remaining, charge.wait)
		charge.wait -= waited
		remaining -= waited
	if remaining > 0.0:
		var moving = minf(remaining, charge.left)
		boss.pos += charge.velocity * moving
		charge.left -= moving
	if charge.left <= 0.0:
		boss.erase("_charge")
	return true

static func _movement(boss: Dictionary, context: Dictionary, settings: Dictionary, profile: String, phase: int, dt: float, fury: float) -> void:
	if _move_charge(boss, dt):
		return
	var age = float(boss.age)
	var phase_age = float(boss._phase_age)
	var anchor: Vector2 = boss._anchor
	var player: Vector2 = context.player
	var amplitude = _v(settings, "amplitude")
	var frequency = _v(settings, "frequency") * fury
	var width = float(context.get("width", 640.0))
	var height = float(context.get("height", 336.0))
	match profile:
		"nereis":
			if phase == 3:
				boss.pos = Vector2(anchor.x + sin(age * frequency) * amplitude * 0.5, move_toward(boss.pos.y, player.y, amplitude * dt))
			else:
				boss.pos = Vector2(anchor.x + cos(age * frequency) * amplitude * 0.25, anchor.y + sin(age * frequency) * amplitude)
		"leafqueen":
			boss.pos = anchor + Vector2(sin(age * frequency * 0.5) * amplitude * (float(phase) / 3.0), cos(age * frequency) * amplitude)
		"hadalsovereign":
			boss.pos = anchor + Vector2(cos(age * frequency) * _v(settings, "orbit_x"), sin(age * frequency) * _v(settings, "orbit_y"))
		"riftia":
			boss.pos = Vector2(width * _v(settings, "phase_x"), anchor.y)
		"epitoke":
			if phase == 3:
				boss.pos = Vector2(width * 0.5, height * 0.5) + Vector2(cos(age * frequency) * _v(settings, "orbit_x"), sin(age * frequency) * _v(settings, "orbit_y"))
			elif phase == 2:
				boss.pos = anchor + Vector2(sin(age * _v(settings, "fast_frequency")) * _v(settings, "orbit_x") * 0.5, cos(age * _v(settings, "fast_frequency")) * amplitude)
			else:
				boss.pos = anchor + Vector2(sin(age * frequency) * amplitude * 0.3, sin(age * frequency) * amplitude)
		"euniceTitan":
			if phase != 4:
				boss.pos = anchor + Vector2(0, sin(phase_age * frequency) * amplitude * float(phase))
		"pollutionCapit", "pollutionSpio", "pollutionCirrat":
			boss.pos = Vector2(anchor.x + sin(age * frequency) * amplitude, height * _v(settings, "lane") + cos(age * frequency) * amplitude)
		"mini":
			var config: Dictionary = boss.config
			var movement = _mini_movement(config)
			match movement:
				"M1": boss.pos = anchor + Vector2(-sin(age * frequency) * amplitude, 0)
				"M3": boss.pos = Vector2(anchor.x, move_toward(boss.pos.y, player.y, amplitude * dt))
				"M4": boss.pos = Vector2(anchor.x, anchor.y - maxf(0.0, _v(settings, "entry_height") - phase_age * _v(settings, "move_speed")))
				"M5": boss.pos = anchor
				"M6": boss.pos = Vector2(anchor.x, height - float(boss.get("size", Vector2(140, 100)).y) * 0.5)
				"M7": boss.pos = anchor + Vector2(sin(age * frequency) * amplitude * 0.5, 0)
				"M8": boss.pos = anchor + Vector2(cos(age * frequency), sin(age * frequency)) * amplitude
				_: boss.pos = anchor + Vector2(sin(age * frequency) * amplitude * 0.3, sin(age * frequency) * amplitude)
		_:
			boss.pos = anchor + Vector2(sin(age * frequency * 0.5) * amplitude * 0.25, sin(age * frequency) * amplitude)
	var size: Vector2 = boss.get("size", Vector2(140, 100))
	var margin = size * _v(settings, "body_margin")
	boss.pos = Vector2(clampf(boss.pos.x, margin.x, width - margin.x), clampf(boss.pos.y, margin.y, height - margin.y))

static func _flags(boss: Dictionary, context: Dictionary, settings: Dictionary, profile: String, phase: int) -> void:
	var flags = {"invisible": false, "weak_exposed": true, "armor": false, "split": false, "fusion": false, "antennae_only": false, "screen_effect": ""}
	var pos: Vector2 = boss.pos
	var size: Vector2 = boss.get("size", Vector2(140, 100))
	flags.weak_points = [pos - Vector2(size.x * _v(settings, "weak_offset"), 0)]
	if profile == "nereis" and phase == 3:
		flags.split = true
		flags.weak_points = [pos + Vector2(0, -_v(settings, "split_gap")), pos + Vector2(0, _v(settings, "split_gap"))]
	elif profile == "polyn" and phase >= 2:
		flags.armor = true
		flags.weak_exposed = fmod(float(boss._phase_age), _v(settings, "armor_closed") + _v(settings, "armor_open")) >= _v(settings, "armor_closed") or bool(boss.get("armor_broken", false))
	elif profile == "tere":
		if phase == 1:
			flags.weak_points = []
			var count = int(_phase_value(settings, "counts", phase))
			for index in range(count):
				var x = float(context.get("width", 640.0)) * (float(index) + 0.5) / float(count)
				flags.weak_points.append(Vector2(x, _v(settings, "hazard_height") if index % 2 == 0 else float(context.get("height", 336.0)) - _v(settings, "hazard_height")))
		else:
			flags.weak_points = [pos - Vector2(size.x * 0.5, -size.y * 0.5), pos - Vector2(size.x * 0.5, size.y * 0.5)]
	elif profile == "leafqueen" and phase == 1:
		flags.invisible = true
		flags.decoys = true
	elif profile == "tomo" and phase == 2:
		flags.invisible = int(float(boss._phase_age) / _v(settings, "visibility_period")) % 2 == 1
		flags.opacity = 0.2 if flags.invisible else 0.65
	elif profile == "capit" and phase == 3:
		flags.screen_effect = "sandstorm"
	elif profile == "eulagisca" and phase == 3:
		flags.screen_effect = "snow"
	elif profile.begins_with("robot_") and phase == 3:
		flags.fusion = true
	elif profile == "euniceTitan":
		flags.antennae_only = phase == 1
	elif profile == "mini" and _mini_movement(boss.config) == "M6":
		var cycle_age = fmod(float(boss._phase_age), _v(settings, "emerge_period"))
		flags.invisible = cycle_age < _v(settings, "telegraph") or cycle_age >= _v(settings, "telegraph") + _v(settings, "emerge_stay")
		flags.weak_exposed = not flags.invisible
	boss.flags = flags

static func _spawn(out: Array, settings: Dictionary, pos: Vector2, key: String = "spawn_enemy", count: int = -1) -> void:
	var total = int(settings.spawn_count) if count < 0 else count
	for index in range(total):
		out.append({"kind": "spawn", "enemy": str(settings[key]), "pos": pos + Vector2(0, (float(index) - float(total - 1) * 0.5) * _v(settings, "hazard_width"))})

static func _pollution(out: Array, variant: int, boss: Dictionary, context: Dictionary, settings: Dictionary, speed: float, count: int) -> void:
	match variant:
		0: _spawn(out, settings, boss.pos, "spawn_enemy")
		1: _ring(out, boss.pos, count, speed, settings, float(boss.age) * _v(settings, "angle_step"), {"bounce": 1, "return_after": _v(settings, "return_after"), "boomerang": true})
		2: _columns(out, context, settings, count, int(boss._attack_index) % 2 == 0, "cirrus")

static func _robot_fusion(out: Array, boss: Dictionary, context: Dictionary, settings: Dictionary, speed: float, count: int) -> void:
	_fan(out, boss.pos, context.player, count, speed, settings)
	_charge(out, boss, context, settings)
	var height = float(context.get("height", 336.0))
	_hazard(out, Rect2(0, height * 0.5 - _v(settings, "hazard_height") * 0.5, float(context.get("width", 640.0)), _v(settings, "hazard_height")), settings, "laser")

static func _jaws(out: Array, context: Dictionary, settings: Dictionary, count: int) -> void:
	var width = float(context.get("width", 640.0))
	var height = float(context.get("height", 336.0))
	var player: Vector2 = context.player
	for index in range(count):
		var x = clampf(player.x + float(index) * _v(settings, "jaw_width") - _v(settings, "jaw_width") * 0.5, 0.0, width - _v(settings, "jaw_width"))
		_hazard(out, Rect2(x, height - _v(settings, "jaw_height"), _v(settings, "jaw_width"), _v(settings, "jaw_height")), settings, "jaw", {"direction": Vector2.UP})

static func _attack(boss: Dictionary, context: Dictionary, settings: Dictionary, profile: String, phase: int, fury: float) -> Array:
	var out: Array = []
	var pos: Vector2 = boss.pos
	var player: Vector2 = context.player
	var speed = float(context.get("bullet_speed", _v(settings, "bullet_base_speed"))) * _v(settings, "speed_scale")
	var count = int(_phase_value(settings, "counts", phase))
	var width = float(context.get("width", 640.0))
	var height = float(context.get("height", 336.0))
	match profile:
		"nereis":
			if phase == 1:
				_burst(out, boss, context, settings, speed)
			elif phase == 2:
				_charge(out, boss, context, settings)
				_fan(out, pos, player, count, speed, settings)
			else:
				for point in boss.flags.weak_points:
					_ring(out, point, count, speed, settings, float(boss.age))
		"capit":
			if phase == 1:
				_columns(out, context, settings, count, false, "sand")
			elif phase == 2:
				_fan(out, pos, player, count, speed, settings, {"hook": true})
			else:
				_columns(out, context, settings, count, false, "sand")
				_charge(out, boss, context, settings, true)
		"polyn":
			if phase == 1:
				_fan(out, pos, player, count, speed, settings, {"bounce": 1})
			elif phase == 2:
				_ring(out, pos, count, speed, settings, float(boss.age), {"bounce": 1})
			else:
				_charge(out, boss, context, settings)
				_rain(out, context, settings, count, speed)
		"tere":
			if phase == 1:
				for index in range(count):
					var x = width * (float(index) + 0.5) / float(count)
					_hazard(out, Rect2(x, 0.0 if index % 2 == 0 else height - _v(settings, "hazard_height"), _v(settings, "hazard_width"), _v(settings, "hazard_height")), settings, "tentacle", {"weak_tip": true})
			elif phase == 2:
				_hazard(out, Rect2(player - Vector2.ONE * _v(settings, "hazard_width"), Vector2.ONE * _v(settings, "hazard_width") * 2.0), settings, "grapple", {"duration": _v(settings, "grapple_duration"), "release_on_weak_hit": true, "direction": player.direction_to(pos), "pull_speed": _v(settings, "grapple_speed")})
				_fan(out, pos, player, count, speed, settings)
			else:
				_hazard(out, Rect2(player - Vector2.ONE * _v(settings, "hazard_width"), Vector2(_v(settings, "hazard_height"), _v(settings, "hazard_height"))), settings, "slow", {"slow": _v(settings, "slow"), "damage": 0.0})
				_fan(out, pos, player, count, speed, settings)
		"hermo":
			if phase == 1:
				_fan(out, pos, player, count, speed, settings)
			elif phase == 2:
				_charge(out, boss, context, settings, true)
			else:
				_rain(out, context, settings, count, speed)
		"leafqueen":
			if phase == 1:
				for index in range(count):
					_hazard(out, Rect2(Vector2(width * float(index + 1) / float(count + 1), height * 0.5), Vector2.ONE * _v(settings, "hazard_width")), settings, "decoy", {"damage": 0.0, "strong": false, "duration": _v(settings, "decoy_duration")})
				_fan(out, pos, player, 1, speed, settings)
			elif phase == 2:
				_ring(out, pos, count, speed, settings, float(boss.age) * _v(settings, "angle_step"), {"bounce": 1, "rotating_leaf": true})
			else:
				_fan(out, pos, player, count, speed, settings, {"homing": _v(settings, "homing")})
		"orbin":
			if phase == 1:
				_columns(out, context, settings, count, false, "mud")
			elif phase == 2:
				_fan(out, pos, player, count, speed, settings, {"slow": _v(settings, "slow")})
				_hazard(out, Rect2(player - Vector2.ONE * _v(settings, "hazard_width"), Vector2.ONE * _v(settings, "hazard_height")), settings, "toxic", {"delay": _v(settings, "gas_delay"), "duration": _v(settings, "gas_duration")})
			else:
				_charge(out, boss, context, settings, true)
				_columns(out, context, settings, count, true, "roots")
		"pollutionCapit", "pollutionSpio", "pollutionCirrat":
			var variant = ["pollutionCapit", "pollutionSpio", "pollutionCirrat"].find(profile)
			_pollution(out, variant, boss, context, settings, speed, count)
			if phase >= 2:
				var combined = settings.duplicate(true)
				combined.spawn_enemy = _data.profiles.pollutionCapit.spawn_enemy
				_pollution(out, (variant + 1) % 3, boss, context, combined, speed, count)
				if phase >= 3 and int(context.get("survivors", 1)) == 1:
					_pollution(out, (variant + 2) % 3, boss, context, combined, speed, count)
		"tomo":
			if phase == 1:
				_fan(out, pos, player, count, speed, settings, {"homing": _v(settings, "homing")})
			elif phase == 2:
				_ring(out, pos, count, speed, settings, float(boss.age))
			else:
				_hazard(out, Rect2(0, 0, width, height), settings, "blind", {"duration": _v(settings, "blind_duration"), "damage": 0.0})
				_fan(out, pos, player, count, speed, settings)
		"eulagisca":
			if phase == 1:
				_columns(out, context, settings, count, true, "ice")
			elif phase == 2:
				_ring(out, pos, count, speed, settings, float(boss.age), {"bounce": 1, "ice_shield": true})
			else:
				_charge(out, boss, context, settings, true, true)
				_rain(out, context, settings, count, speed, {"slow": _v(settings, "slow"), "slow_duration": _v(settings, "snow_duration")})
		"osedax":
			if phase == 1:
				_columns(out, context, settings, count, false, "bone_roots")
			elif phase == 2:
				_spawn(out, settings, pos)
			else:
				var acid = settings.duplicate(true)
				acid.hazard_height = _v(settings, "hazard_height") + minf(float(boss._phase_age) * _v(settings, "acid_growth"), height * 0.25)
				_columns(out, context, acid, count, false, "acid", {"duration": _v(settings, "acid_duration")})
				_columns(out, context, acid, count, true, "acid", {"duration": _v(settings, "acid_duration")})
		"alvinella":
			if phase == 1:
				_columns(out, context, settings, count, false, "fire")
			elif phase == 2:
				var lava_height = _v(settings, "lava_max_height") * minf(float(boss._phase_age) / _v(settings, "lava_rise_duration"), 1.0)
				_hazard(out, Rect2(0, height - lava_height, width, lava_height), settings, "lava", {"duration": _v(settings, "lava_duration")})
			else:
				_columns(out, context, settings, count, false, "magma")
				_fan(out, pos, player, count, speed, settings)
		"hadalsovereign":
			if phase == 1:
				_charge(out, boss, context, settings, true)
			elif phase == 2:
				_fan(out, pos, player, count, speed, settings, {"bounce": 1})
			else:
				_charge(out, boss, context, settings, true)
				_ring(out, pos, count, speed * fury, settings)
		"riftia":
			if phase == 1:
				_fan(out, pos, player, count, speed, settings)
			elif phase == 2:
				_ring(out, pos, count, speed, settings)
			else:
				_ring(out, pos, count, speed, settings, float(boss.age))
				_fan(out, pos, player, count, speed, settings)
		"robot_pinza":
			if phase == 3:
				_robot_fusion(out, boss, context, settings, speed, count)
			else:
				if phase == 1:
					_burst(out, boss, context, settings, speed)
				else:
					_fan(out, pos, player, count, speed, settings)
				if phase == 2:
					_hazard(out, Rect2(player - Vector2(_v(settings, "hazard_width") * 0.5, _v(settings, "hazard_height") * 0.5), Vector2(_v(settings, "hazard_width"), _v(settings, "hazard_height"))), settings, "jaw")
		"robot_torreta":
			if phase == 3:
				_robot_fusion(out, boss, context, settings, speed, count)
			else:
				_fan(out, pos, player, count, speed, settings)
				if phase == 2:
					_hazard(out, Rect2(0, player.y, width, _v(settings, "hazard_height")), settings, "laser")
		"robot_taladro":
			if phase == 3:
				_robot_fusion(out, boss, context, settings, speed, count)
			else:
				_charge(out, boss, context, settings, phase == 2)
				if phase == 2:
					_rain(out, context, settings, count, speed)
		"epitoke":
			if phase == 1:
				_fan(out, pos, player, count, speed, settings)
			elif phase == 2:
				_fan(out, pos, player, count, speed, settings, {"homing": _v(settings, "angle_step")})
			else:
				_ring(out, pos, count, speed * _v(settings, "gamete_speed"), settings, float(boss.age), {"gamete": true})
		"scientist":
			if phase == 1:
				_spawn(out, settings, pos)
				_hazard(out, Rect2(0, player.y, width, _v(settings, "hazard_height")), settings, "laser")
			elif phase == 2:
				_spawn(out, settings, Vector2(width * 0.7, height * 0.5), "escort_enemy", count)
				_fan(out, pos, player, count, speed, settings)
			else:
				for sign_y in [-1.0, 1.0]:
					_hazard(out, Rect2(0, player.y + sign_y * _v(settings, "hazard_height"), width, _v(settings, "hazard_height")), settings, "mecha_arm", {"direction": Vector2.LEFT})
		"euniceTitan":
			if phase == 1:
				_jaws(out, context, settings, count)
			elif phase == 2:
				for index in range(count):
					var y = height * float(index + 1) / float(count + 1)
					_hazard(out, Rect2(0, y, width, _v(settings, "segment_height")), settings, "segment", {"direction": Vector2.LEFT})
			elif phase == 3:
				_jaws(out, context, settings, count)
				_rain(out, context, settings, int(settings.debris_count), speed)
			else:
				_jaws(out, context, settings, int(_phase_value(settings, "counts", 3)))
				_ring(out, pos, count, speed, settings, float(boss.age))
		_: # Unique-world miniboss: enlarged original firing plus a warned charge.
			var fallback = "F5" if str(boss.config.get("arquetipo", "")) == "mini_robot" else "F3"
			var firing = str(boss.config.get("disparo", boss.config.get("firing", fallback)))
			match firing:
				"F0": pass
				"F1": _fan(out, pos, player, 1, speed, settings, {}, PI)
				"F2": _fan(out, pos, player, 1, speed, settings)
				"F4": _ring(out, pos, count, speed, settings)
				"F5": _burst(out, boss, context, settings, speed)
				_: _fan(out, pos, player, count, speed, settings)
			_charge(out, boss, context, settings, phase == 2)
	return out

static func step(boss: Dictionary, context: Dictionary, dt: float) -> Array:
	if dt <= 0.0 or not context.get("player") is Vector2:
		return []
	var config: Dictionary = boss.get("config", {})
	var profile = str(config.get("arquetipo", "mini"))
	if bool(boss.get("is_mini", false)) or bool(config.get("is_miniboss", false)) or profile.begins_with("mini"):
		profile = "mini"
	var settings = _settings(profile, config)
	if settings.is_empty():
		return []
	if not _data.profiles.has(profile):
		profile = "mini"
	var phase = maxi(1, int(boss.get("phase", 1)))
	if not boss.has("_anchor"):
		boss._anchor = boss.pos
		boss._phase_age = 0.0
		boss._pattern_phase = phase
		boss._attack_index = 0
		boss._special_clock = 0.0
	elif boss._pattern_phase != phase:
		boss._pattern_phase = phase
		boss._phase_age = 0.0
		boss._special_clock = 0.0
		boss.attack_clock = 0.0
		boss.erase("_charge")
		boss.erase("_bursts")
	boss.age = float(boss.get("age", 0.0)) + dt
	boss._phase_age += dt
	var fury = float(boss.get("fury_multiplier", 1.0))
	if profile.begins_with("pollution") and int(context.get("survivors", 3)) < 3:
		fury = maxf(fury, _v(settings, "fury"))
	elif profile == "hadalsovereign" and bool(context.get("partner_dead", false)):
		fury = maxf(fury, _v(settings, "fury"))
	if profile == "hadalsovereign":
		settings.charge_speed = _v(settings, "charge_speed") * fury
	_movement(boss, context, settings, profile, phase, dt, fury)
	_flags(boss, context, settings, profile, phase)
	boss.attack_clock = float(boss.get("attack_clock", 0.0)) + dt * fury
	var interval = _phase_value(settings, "intervals", phase)
	var actions: Array = []
	_advance_bursts(actions, boss, context, settings, dt)
	if profile == "mini" and _mini_movement(config) == "M6":
		var cycle = int(float(boss._phase_age) / _v(settings, "emerge_period"))
		if cycle != int(boss.get("_burrow_cycle", -1)):
			boss._burrow_cycle = cycle
			var size: Vector2 = boss.get("size", Vector2(140, 100))
			_hazard(actions, Rect2(boss.pos - size * 0.5, size), settings, "emerge", {"duration": _v(settings, "emerge_stay")})
	var emitted = 0
	while boss.attack_clock >= interval and emitted < int(settings.max_catchup):
		boss.attack_clock -= interval
		boss._attack_index += 1
		actions.append_array(_attack(boss, context, settings, profile, phase, fury))
		emitted += 1
	if profile == "hermo" and phase == 3:
		boss._special_clock += dt
		while boss._special_clock >= _v(settings, "ring_interval"):
			boss._special_clock -= _v(settings, "ring_interval")
			_ring(actions, boss.pos, int(settings.ring_count), float(context.get("bullet_speed", _v(settings, "bullet_base_speed"))), settings)
	return actions
