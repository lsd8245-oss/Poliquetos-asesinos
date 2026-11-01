class_name PoliSave
extends RefCounted

const Shop = preload("../shop/shop.gd")
const VERSION := 2

static func file_path(slot: int, sandbox: bool = false) -> String:
	return "user://%s/slot_%d.json" % ["pruebas" if sandbox else "normal", slot]

static func _valid_slot(slot: int) -> bool:
	return slot >= 1 and slot <= 3

static func _load_result(ok: bool, profile: Dictionary = {}, recovered: bool = false, error: String = "") -> Dictionary:
	return {"ok": ok, "profile": profile, "recovered": recovered, "error": error}

static func _integer(value, minimum: int, maximum: int = 2147483647) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and value >= minimum and value <= maximum

static func _json_value(value) -> bool:
	if value is Dictionary:
		for key in value:
			if not (key is String or key is StringName) or not _json_value(value[key]):
				return false
		return true
	if value is Array:
		for item in value:
			if not _json_value(item):
				return false
		return true
	return value == null or value is String or value is bool or value is int or (value is float and is_finite(value))

static func _integer_paths(value, path: Array, paths: Array) -> void:
	if value is int:
		paths.append(path)
	elif value is Dictionary:
		for key in value:
			_integer_paths(value[key], path + [str(key)], paths)
	elif value is Array:
		for index in range(value.size()):
			_integer_paths(value[index], path + [index], paths)

static func _encode(value: Dictionary) -> String:
	# Godot's JSON parser reads every number as float. Keep integer locations in
	# plain JSON metadata so weapon ranks, counters and optional state round-trip.
	var paths: Array = []
	_integer_paths(value, [], paths)
	var copy := value.duplicate(true)
	copy["_integer_paths"] = paths
	return JSON.stringify(copy, "\t")

static func _restore_integer_paths(value: Dictionary) -> Dictionary:
	var paths = value.get("_integer_paths", [])
	value.erase("_integer_paths")
	if not paths is Array:
		return value
	for path in paths:
		if not path is Array or path.is_empty():
			continue
		var parent = value
		var valid := true
		for offset in range(path.size() - 1):
			var key = int(path[offset]) if parent is Array and _integer(path[offset], 0) else path[offset]
			if (parent is Dictionary and parent.has(key)) or (parent is Array and key is int and key >= 0 and key < parent.size()):
				parent = parent[key]
			else:
				valid = false
				break
		if not valid:
			continue
		var last = path[-1]
		if parent is Array and _integer(last, 0):
			last = int(last)
		if (parent is Dictionary and parent.has(last)) or (parent is Array and last is int and last >= 0 and last < parent.size()):
			var number = parent[last]
			if (number is int or number is float) and is_finite(float(number)) and float(number) == floor(float(number)):
				parent[last] = int(number)
	return value

static func _validate(profile: Dictionary, sandbox: bool) -> String:
	for key in ["version", "edition", "slot", "difficulty", "world", "lab_boss", "credits", "upgrades", "equipment", "weapons", "bombs", "skins", "skin", "colors", "deaths", "time", "cleared", "seed", "completed"]:
		if not profile.has(key):
			return "missing_" + key
	if profile.version != VERSION:
		return "unsupported_version"
	if profile.edition != ("pruebas" if sandbox else "normal"):
		return "edition_mismatch"
	if not _integer(profile.slot, 1, 3) or profile.difficulty not in ["easy", "normal", "hard"]:
		return "invalid_slot_or_difficulty"
	if not _integer(profile.world, 1, 15) or not _integer(profile.lab_boss, 0, 4) or not _integer(profile.credits, 0):
		return "invalid_progress"
	if not profile.upgrades is Dictionary or not profile.equipment is Dictionary or not profile.weapons is Dictionary:
		return "invalid_build"
	var data: Dictionary = Shop.catalog()
	var upgrade_ids := []
	for upgrade in data.mejoras:
		upgrade_ids.append(upgrade.id)
		if not _integer(profile.upgrades.get(upgrade.id, 0), 0, int(upgrade.rangos)):
			return "invalid_upgrade_rank"
	for key in profile.upgrades:
		if key not in upgrade_ids:
			return "unknown_upgrade"
	var equipment_ids := ["sonar"]
	for gear in data.equipo:
		equipment_ids.append(gear.id)
	if not profile.equipment.get("sonar", false):
		return "missing_initial_sonar"
	for key in profile.equipment:
		if key not in equipment_ids or not profile.equipment[key] is bool:
			return "invalid_equipment"
	for key in ["shot", "missile", "bomb"]:
		if not _integer(profile.weapons.get(key, 0), 1, 8):
			return "invalid_weapon"
	if not _integer(profile.bombs, 0, 5):
		return "invalid_bombs"
	if not profile.skins is Array or not profile.skin is String or profile.skin not in profile.skins:
		return "invalid_skin"
	var skin_ids := []
	for skin in Shop.cosmetics():
		skin_ids.append(skin.id)
	for skin in profile.skins:
		if skin not in skin_ids:
			return "unknown_skin"
	if not profile.colors is Dictionary or not profile.deaths is Dictionary or not profile.cleared is Array:
		return "invalid_history_or_colors"
	for zone in ["hull", "lights", "trail"]:
		if not profile.colors.get(zone) is String or not Color.html_is_valid(profile.colors[zone]):
			return "invalid_color"
	for deaths in profile.deaths.values():
		if not _integer(deaths, 0):
			return "invalid_deaths"
	for world in profile.cleared:
		if not _integer(world, 1, 15):
			return "invalid_cleared_world"
	if not (profile.time is int or profile.time is float) or not is_finite(float(profile.time)) or profile.time < 0:
		return "invalid_time"
	if not _integer(profile.seed, 0) or not profile.completed is bool or not _json_value(profile):
		return "invalid_profile_value"
	return ""

static func _decode(text: String, sandbox: bool) -> Dictionary:
	var parser := JSON.new()
	if parser.parse(text) != OK or not parser.data is Dictionary:
		return _load_result(false, {}, false, "invalid_json")
	var profile := _restore_integer_paths(parser.data)
	var version = profile.get("version", 0)
	if not _integer(version, 1, VERSION):
		return _load_result(false, {}, false, "unsupported_version")
	if profile.has("edition") and profile.edition != ("pruebas" if sandbox else "normal"):
		return _load_result(false, {}, false, "edition_mismatch")
	if int(version) == 1:
		var migrated := Shop.create_profile(sandbox)
		for key in profile:
			migrated[key] = profile[key]
		migrated.version = VERSION
		migrated.credits = profile.get("credits", profile.get("coins", migrated.credits))
		migrated.world = profile.get("world", profile.get("current_world", 1))
		profile = migrated
	var error := _validate(profile, sandbox)
	if not error.is_empty():
		return _load_result(false, {}, false, error)
	if sandbox:
		profile.credits = Shop.SANDBOX_CREDITS
	return _load_result(true, profile)

static func _read(path: String, sandbox: bool) -> Dictionary:
	if not FileAccess.file_exists(path):
		return _load_result(false, {}, false, "slot_empty")
	return _decode(FileAccess.get_file_as_string(path), sandbox)

static func _write(path: String, text: String, backup_valid: bool) -> Dictionary:
	var directory := ProjectSettings.globalize_path(path.get_base_dir())
	var error := DirAccess.make_dir_recursive_absolute(directory)
	if error != OK:
		return {"ok": false, "error": "directory_error_%d" % error}
	var temp := path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "write_error_%d" % FileAccess.get_open_error()}
	file.store_string(text)
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		return {"ok": false, "error": "write_error_%d" % write_error}
	# Preserve the last validated generation; a corrupt primary never destroys .bak.
	if backup_valid:
		error = DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(path + ".bak"))
		if error != OK:
			return {"ok": false, "error": "backup_error_%d" % error}
	error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temp), ProjectSettings.globalize_path(path))
	return {"ok": error == OK, "error": "" if error == OK else "rename_error_%d" % error}

static func save_slot(slot: int, profile: Dictionary) -> Dictionary:
	if not _valid_slot(slot):
		return {"ok": false, "error": "invalid_slot"}
	var sandbox: bool = profile.get("edition", "normal") == "pruebas"
	var copy := profile.duplicate(true)
	copy.slot = slot
	var error := _validate(copy, sandbox)
	if not error.is_empty():
		return {"ok": false, "error": error}
	if sandbox:
		copy.credits = Shop.SANDBOX_CREDITS
	var path := file_path(slot, sandbox)
	return _write(path, _encode(copy), _read(path, sandbox).ok)

static func load_slot(slot: int, sandbox: bool = false) -> Dictionary:
	if not _valid_slot(slot):
		return _load_result(false, {}, false, "invalid_slot")
	var path := file_path(slot, sandbox)
	var result := _read(path, sandbox)
	if result.ok:
		result.profile.slot = slot
		return result
	var backup := _read(path + ".bak", sandbox)
	if backup.ok:
		backup.recovered = true
		backup.error = result.error
		backup.profile.slot = slot
		return backup
	return result

static func export_slot(slot: int, sandbox: bool = false) -> String:
	var result := load_slot(slot, sandbox)
	return _encode(result.profile) if result.ok else ""

static func import_slot(slot: int, json: String, sandbox: bool = false) -> Dictionary:
	if not _valid_slot(slot):
		return _load_result(false, {}, false, "invalid_slot")
	var result := _decode(json, sandbox)
	if not result.ok:
		return result
	result.profile.slot = slot
	var saved := save_slot(slot, result.profile)
	return result if saved.ok else _load_result(false, {}, false, saved.error)

static func default_options() -> Dictionary:
	return {"master": 10, "music": 7, "effects": 8, "screen": "window2", "autofire": false, "shake": true, "reduce_flashes": false, "bindings": {}}

static func _options_path(sandbox: bool) -> String:
	return "user://%s/options.json" % ("pruebas" if sandbox else "normal")

static func _decode_options(text: String) -> Dictionary:
	var parser := JSON.new()
	if parser.parse(text) != OK or not parser.data is Dictionary or not _json_value(parser.data):
		return {"ok": false, "options": default_options(), "recovered": false, "error": "invalid_options"}
	var options := _restore_integer_paths(parser.data)
	for key in ["master", "music", "effects"]:
		if options.has(key) and not _integer(options[key], 0, 10):
			return {"ok": false, "options": default_options(), "recovered": false, "error": "invalid_volume"}
	for key in ["autofire", "shake", "reduce_flashes", "show_hitbox"]:
		if options.has(key) and not options[key] is bool:
			return {"ok": false, "options": default_options(), "recovered": false, "error": "invalid_option_type"}
	if options.has("bindings") and not options.bindings is Dictionary:
		return {"ok": false, "options": default_options(), "recovered": false, "error": "invalid_bindings"}
	return {"ok": true, "options": options, "recovered": false, "error": ""}

static func save_options(options: Dictionary, sandbox: bool = false) -> Dictionary:
	if not _json_value(options):
		return {"ok": false, "error": "invalid_options"}
	var text := _encode(options)
	var decoded := _decode_options(text)
	if not decoded.ok:
		return {"ok": false, "error": decoded.error}
	var path := _options_path(sandbox)
	var valid_backup: bool = FileAccess.file_exists(path) and _decode_options(FileAccess.get_file_as_string(path)).ok
	return _write(path, text, valid_backup)

static func load_options(sandbox: bool = false) -> Dictionary:
	var path := _options_path(sandbox)
	var result := {"ok": true, "options": default_options(), "recovered": false, "error": ""}
	if FileAccess.file_exists(path):
		result = _decode_options(FileAccess.get_file_as_string(path))
		if result.ok:
			return result
	if FileAccess.file_exists(path + ".bak"):
		var backup := _decode_options(FileAccess.get_file_as_string(path + ".bak"))
		if backup.ok:
			backup.recovered = true
			backup.error = result.error
			return backup
	return result
