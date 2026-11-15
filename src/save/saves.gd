class_name PoliSave
extends RefCounted

const Shop = preload("../shop/shop.gd")
const Data = preload("../core/data.gd")
const Campaign = preload("../core/campaign.gd")
const VERSION := 3

static func file_path(slot: int, sandbox: bool = false) -> String:
	return "user://%s/campaign12/slot_%d.json" % ["pruebas" if sandbox else "normal", slot]

static func legacy_file_path(slot: int, sandbox: bool = false) -> String:
	return "user://%s/slot_%d.json" % ["pruebas" if sandbox else "normal", slot]

static func _valid_slot(slot: int) -> bool:
	return slot >= 1 and slot <= 3

static func _load_result(ok: bool, profile: Dictionary = {}, recovered: bool = false, error: String = "", migrated: bool = false, migration_notice: String = "") -> Dictionary:
	return {"ok": ok, "profile": profile, "recovered": recovered, "error": error, "migrated": migrated, "migration_notice": migration_notice}

static func _integer(value, minimum: int, maximum: int = 2147483647) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and value >= minimum and value <= maximum

static func _json_value(value, ancestors: Array = [], depth: int = 0) -> bool:
	if depth > 64:
		return false
	if value is Dictionary or value is Array:
		for ancestor in ancestors:
			if is_same(value, ancestor):
				return false
		ancestors = ancestors + [value]
	if value is Dictionary:
		for key in value:
			if not (key is String or key is StringName) or not _json_value(value[key], ancestors, depth + 1):
				return false
		return true
	if value is Array:
		for item in value:
			if not _json_value(item, ancestors, depth + 1):
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
	# Keep accumulated fractional combat clocks exact as well as integer types.
	return JSON.stringify(copy, "\t", true, true)

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

static func _boolean_map(value) -> bool:
	if not value is Dictionary:
		return false
	for key in value:
		if not (key is String or key is StringName) or not value[key] is bool:
			return false
	return true

static func _weapon_levels(value) -> bool:
	if not value is Dictionary or value.size() != 3:
		return false
	for key in ["shot", "missile", "bomb"]:
		if not _integer(value.get(key), 1, 8):
			return false
	return true

static func _world_limit(legacy_campaign: bool) -> int:
	if legacy_campaign:
		# Validate against the archived edition, never the shorter active campaign.
		return int(Data.read_json("data/archive/04a/escape.json", {}).get("id", 15))
	return Campaign.escape_id()

static func _lab_limit(legacy_campaign: bool) -> int:
	return int(Data.read_json("data/archive/04a/escape.json", {}).get("laboratory_encounters", 4)) if legacy_campaign else Campaign.lab_encounter_count()

static func _world_key(key: String, legacy_campaign: bool) -> bool:
	if not legacy_campaign and key in ["retired:3", "retired:6"]:
		return true
	return key.is_valid_int() and str(int(key)) == key and _integer(int(key), 1, _world_limit(legacy_campaign))

static func _progress_key(key: String, legacy_campaign: bool) -> bool:
	var parts := key.split(":")
	if not legacy_campaign and parts.size() >= 4 and parts[0] == "historical":
		if parts[1] == "world" and parts[2] in ["3", "6"]:
			return parts[3].is_valid_int() and _integer(int(parts[3]), 0, 4)
		return parts[1] == "epitoka" and parts[2] == "14" and parts[3] == "1"
	return parts.size() >= 2 and _world_key(parts[0], legacy_campaign) and parts[1].is_valid_int() and _integer(int(parts[1]), 0, _lab_limit(legacy_campaign))

static func _validate_optional(profile: Dictionary, sandbox: bool, legacy_campaign: bool) -> String:
	for key in ["claimed_drops", "rewarded"]:
		if profile.has(key) and not _boolean_map(profile[key]):
			return "invalid_" + key
		if profile.has(key):
			for progress_key in profile[key]:
				if not _progress_key(str(progress_key), legacy_campaign):
					return "invalid_" + key + "_key"
	if profile.has("world_entry_weapons") and not _weapon_levels(profile.world_entry_weapons):
		return "invalid_world_entry_weapons"
	for key in ["entry_world", "lander_used_world"]:
		if profile.has(key) and not _integer(profile[key], 1 if key == "entry_world" else 0, _world_limit(legacy_campaign)):
			return "invalid_" + key
	for key in ["coins_total", "replay_earned", "world_elapsed", "kills_total", "spawned_total"]:
		if profile.has(key):
			var value = profile[key]
			if not (value is int or value is float) or not is_finite(float(value)) or value < 0:
				return "invalid_" + key
	if profile.has("replay_mode") and not profile.replay_mode is bool:
		return "invalid_replay_mode"
	if profile.get("replay_mode", false) and not profile.has("replay_return"):
		return "missing_replay_return"
	if profile.has("replay_return"):
		if not profile.replay_return is Dictionary:
			return "invalid_replay_return"
		var nested_error := _validate(profile.replay_return, sandbox, legacy_campaign)
		if not nested_error.is_empty():
			return "invalid_replay_return_" + nested_error
	if profile.has("resume") and profile.resume not in ["playing", "rest", "completed"]:
		return "invalid_resume"
	return ""

static func _validate(profile: Dictionary, sandbox: bool, legacy_campaign: bool = false) -> String:
	# Reject native cycles/nonfinite values before duplication, traversal or JSON.
	if not _json_value(profile):
		return "invalid_profile_value"
	for key in ["version", "edition", "slot", "difficulty", "world", "lab_boss", "credits", "upgrades", "equipment", "weapons", "bombs", "skins", "skin", "colors", "deaths", "time", "cleared", "seed", "completed"]:
		if not profile.has(key):
			return "missing_" + key
	if (legacy_campaign and not _integer(profile.version, 1, 2)) or (not legacy_campaign and profile.version != VERSION):
		return "unsupported_version"
	if profile.edition != ("pruebas" if sandbox else "normal"):
		return "edition_mismatch"
	if not _integer(profile.slot, 1, 3) or profile.difficulty not in ["easy", "normal", "hard"]:
		return "invalid_slot_or_difficulty"
	if not _integer(profile.world, 1, _world_limit(legacy_campaign)) or not _integer(profile.lab_boss, 0, _lab_limit(legacy_campaign)) or not _integer(profile.credits, 0):
		return "invalid_progress"
	if not profile.upgrades is Dictionary or not profile.equipment is Dictionary or not profile.weapons is Dictionary:
		return "invalid_build"
	var data: Dictionary = Data.read_json("data/archive/04a/shop.json", {}) if legacy_campaign else Shop.catalog()
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
	if not _weapon_levels(profile.weapons):
		return "invalid_weapon"
	if not _integer(profile.bombs, 0, 5):
		return "invalid_bombs"
	if not profile.skins is Array or not profile.skin is String or profile.skin not in profile.skins:
		return "invalid_skin"
	var skin_ids := []
	var cosmetics: Array = Data.read_json("data/archive/04a/cosmetics.json", []) if legacy_campaign else Shop.cosmetics()
	for skin in cosmetics:
		skin_ids.append(skin.id)
	for skin in profile.skins:
		if skin not in skin_ids:
			return "unknown_skin"
	if not profile.colors is Dictionary or not profile.deaths is Dictionary or not profile.cleared is Array:
		return "invalid_history_or_colors"
	for zone in ["hull", "lights", "trail"]:
		if not profile.colors.get(zone) is String or not Color.html_is_valid(profile.colors[zone]):
			return "invalid_color"
	for key in profile.deaths:
		if not _world_key(str(key), legacy_campaign) or not _integer(profile.deaths[key], 0):
			return "invalid_deaths"
	for world in profile.cleared:
		if not _integer(world, 1, _world_limit(true) if legacy_campaign else Campaign.world_count()):
			return "invalid_cleared_world"
	if not (profile.time is int or profile.time is float) or not is_finite(float(profile.time)) or profile.time < 0:
		return "invalid_time"
	if not _integer(profile.seed, 0, 4294967295) or not profile.completed is bool:
		return "invalid_profile_value"
	return _validate_optional(profile, sandbox, legacy_campaign)

static func _legacy_defaults(profile: Dictionary, sandbox: bool) -> Dictionary:
	if profile.get("version") == 1:
		var defaults := Shop.create_profile(sandbox)
		for key in profile:
			defaults[key] = profile[key]
		defaults.version = 1
		defaults.credits = profile.get("credits", profile.get("coins", defaults.credits))
		defaults.world = profile.get("world", profile.get("current_world", 1))
		profile = defaults
	if profile.get("replay_return") is Dictionary:
		profile.replay_return = _legacy_defaults(profile.replay_return, sandbox)
	return profile

static func _mapped_world(world: int) -> int:
	var config := Campaign.config()
	return int(config.old_to_new.get(str(world), config.removed_world_destinations.get(str(world), world)))

static func _migrate_keys(value: Dictionary) -> Dictionary:
	var migrated: Dictionary = {}
	var config := Campaign.config()
	for key in value:
		var parts: PackedStringArray = str(key).split(":")
		var world := int(parts[0])
		if config.removed_world_destinations.has(str(world)):
			migrated["historical:world:" + str(key)] = value[key]
		elif world == 14 and parts[1] == "1":
			# Old encounter1 was Epitoka. Its payment must not suppress or pay
			# again the scientist now occupying encounter1.
			migrated["historical:epitoka:" + str(key)] = value[key]
		else:
			parts[0] = str(_mapped_world(world))
			if world == 14:
				parts[1] = str(int(config.legacy_lab_to_new.get(parts[1], int(parts[1]))))
			# Phase conversion coins embed the semantic boss owner in their UID.
			# Other owner shapes and historical UIDs keep their original text.
			if parts.size() == 7 and parts[2] == "phase" and parts[3] == "boss" and parts[5].is_valid_int() and parts[6].is_valid_int():
				parts[4] = str(config.legacy_boss_to_current.get(parts[4], parts[4]))
			migrated[":".join(parts)] = value[key]
	return migrated

static func _migrate(profile: Dictionary) -> Dictionary:
	var old_world := int(profile.world)
	var removed: bool = Campaign.config().removed_world_destinations.has(str(old_world))
	var original_lab := int(profile.lab_boss)
	var historical_cleared: Array = []
	var cleared: Array = []
	for world in profile.cleared:
		if Campaign.config().old_to_new.has(str(int(world))) and int(world) != 15:
			var destination := _mapped_world(int(world))
			if not cleared.has(destination):
				cleared.append(destination)
		else:
			historical_cleared.append(int(world))
	var deaths: Dictionary = {}
	for key in profile.deaths:
		var retired: bool = Campaign.config().removed_world_destinations.has(str(key))
		deaths["retired:" + str(key) if retired else str(_mapped_world(int(key)))] = profile.deaths[key]
	for key in ["rewarded", "claimed_drops"]:
		if profile.has(key):
			profile[key] = _migrate_keys(profile[key])
	for key in ["entry_world", "lander_used_world"]:
		if profile.has(key) and int(profile[key]) > 0:
			profile[key] = _mapped_world(int(profile[key]))
	profile.world = _mapped_world(old_world)
	profile.lab_boss = int(Campaign.config().legacy_lab_to_new[str(original_lab)]) if old_world == 14 else 0
	profile.cleared = cleared
	profile.deaths = deaths
	var notice := "Partida antigua adaptada a la campaña de 12 mundos. Se conservan los créditos, compras, skins e historial. Los archivos antiguos y su .bak se conservarán."
	if removed:
		notice += " El antiguo mundo %d fue retirado: volverás a la entrada del mundo %d, sin avanzar a una etapa posterior." % [old_world, profile.world]
		profile.resume = "playing"
		profile.world_elapsed = 0.0
		profile.erase("checkpoint")
		if profile.has("world_entry_weapons"):
			profile.world_entry_weapons = profile.weapons.duplicate(true)
	elif old_world == 14:
		notice += " El laboratorio continúa con robots, científico y Eunice; Epitoka queda en el historial."
	profile.migration_meta = {"source_version": int(profile.version), "source_campaign": "legacy14", "source_world": old_world, "source_lab_boss": original_lab, "destination_world": int(profile.world), "decision": "removed_world_to_previous_entry" if removed else "renumber", "historical_cleared": historical_cleared, "retired_worlds": [old_world] if removed else [], "notice": notice}
	profile.version = VERSION
	if profile.has("replay_return"):
		profile.replay_return = _migrate(profile.replay_return)
		# Propagate descendant destinations through surviving replay profiles,
		# without copying their generic notices or repeating retired worlds.
		for retired_world in profile.replay_return.migration_meta.retired_worlds:
			if not profile.migration_meta.retired_worlds.has(retired_world):
				profile.migration_meta.retired_worlds.append(retired_world)
				profile.migration_meta.notice += " Al volver de la repetición, el antiguo mundo %d fue retirado: volverás a la entrada del mundo %d, sin avanzar a una etapa posterior." % [retired_world, _mapped_world(retired_world)]
	profile.migration_meta.retired_worlds.sort()
	return profile

static func _decode(text: String, sandbox: bool, namespace_version: int = 0) -> Dictionary:
	var parser := JSON.new()
	if parser.parse(text) != OK or not parser.data is Dictionary:
		return _load_result(false, {}, false, "invalid_json")
	var profile := _restore_integer_paths(parser.data)
	var version = profile.get("version", 0)
	if not _integer(version, 1, VERSION):
		return _load_result(false, {}, false, "unsupported_version")
	if profile.has("edition") and profile.edition != ("pruebas" if sandbox else "normal"):
		return _load_result(false, {}, false, "edition_mismatch")
	var legacy_campaign := int(version) < VERSION
	if (namespace_version == VERSION and legacy_campaign) or (namespace_version == 2 and not legacy_campaign):
		return _load_result(false, {}, false, "campaign_namespace_mismatch")
	if legacy_campaign:
		profile = _legacy_defaults(profile, sandbox)
	var error := _validate(profile, sandbox, legacy_campaign)
	if not error.is_empty():
		return _load_result(false, {}, false, error)
	if legacy_campaign:
		profile = _migrate(profile)
		error = _validate(profile, sandbox)
		if not error.is_empty():
			return _load_result(false, {}, false, "migration_" + error)
	if sandbox:
		profile.credits = Shop.SANDBOX_CREDITS
	return _load_result(true, profile, false, "", legacy_campaign, str(profile.get("migration_meta", {}).get("notice", "")) if legacy_campaign else "")

static func _read(path: String, sandbox: bool, namespace_version: int = VERSION) -> Dictionary:
	if not FileAccess.file_exists(path):
		return _load_result(false, {}, false, "slot_empty")
	return _decode(FileAccess.get_file_as_string(path), sandbox, namespace_version)

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
		var backup_temp := path + ".bak.tmp"
		var backup_file := FileAccess.open(backup_temp, FileAccess.WRITE)
		if backup_file == null:
			return {"ok": false, "error": "backup_error_%d" % FileAccess.get_open_error()}
		var bytes := FileAccess.get_file_as_bytes(path)
		backup_file.store_buffer(bytes)
		backup_file.flush()
		var backup_error := backup_file.get_error()
		backup_file.close()
		if backup_error != OK:
			return {"ok": false, "error": "backup_error_%d" % backup_error}
		if FileAccess.get_file_as_bytes(backup_temp) != bytes:
			return {"ok": false, "error": "backup_copy_mismatch"}
		error = DirAccess.rename_absolute(ProjectSettings.globalize_path(backup_temp), ProjectSettings.globalize_path(path + ".bak"))
		if error != OK:
			return {"ok": false, "error": "backup_rename_error_%d" % error}
	error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temp), ProjectSettings.globalize_path(path))
	return {"ok": error == OK, "error": "" if error == OK else "rename_error_%d" % error}

static func _preserve_legacy(slot: int, sandbox: bool) -> Dictionary:
	# These are raw independent JSON files: the previous installation can read
	# them without the new campaign or this migration code. Include a corrupt
	# primary when recovery used .bak, and never replace a preexisting copy.
	var source := legacy_file_path(slot, sandbox)
	for suffix in ["", ".bak"]:
		var path: String = source + suffix
		if not FileAccess.file_exists(path):
			continue
		var input := FileAccess.open(path, FileAccess.READ)
		if input == null:
			return {"ok": false, "error": "migration_read_error_%d" % FileAccess.get_open_error()}
		var bytes := input.get_buffer(input.get_length())
		var read_error := input.get_error()
		input.close()
		if read_error != OK:
			return {"ok": false, "error": "migration_read_error_%d" % read_error}
		var hash := HashingContext.new()
		hash.start(HashingContext.HASH_SHA256)
		hash.update(bytes)
		var digest := hash.finish().hex_encode()
		var name := "slot_%d_legacy_%s_%s.json" % [slot, "primary" if suffix.is_empty() else "backup", digest]
		var destination := file_path(slot, sandbox).get_base_dir().path_join("migration").path_join(name)
		if FileAccess.file_exists(destination):
			if FileAccess.get_file_as_bytes(destination) != bytes:
				return {"ok": false, "error": "migration_copy_conflict"}
			continue
		var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(destination.get_base_dir()))
		if error != OK:
			return {"ok": false, "error": "migration_directory_error_%d" % error}
		var temp := destination + ".tmp"
		var output := FileAccess.open(temp, FileAccess.WRITE)
		if output == null:
			return {"ok": false, "error": "migration_copy_error_%d" % FileAccess.get_open_error()}
		output.store_buffer(bytes)
		output.flush()
		var write_error := output.get_error()
		output.close()
		if write_error != OK or FileAccess.get_file_as_bytes(temp) != bytes:
			return {"ok": false, "error": "migration_copy_error_%d" % write_error}
		error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temp), ProjectSettings.globalize_path(destination))
		if error != OK:
			return {"ok": false, "error": "migration_copy_rename_error_%d" % error}
	return {"ok": true, "error": ""}

static func save_slot(slot: int, profile: Dictionary) -> Dictionary:
	if not _valid_slot(slot):
		return {"ok": false, "error": "invalid_slot"}
	if not _json_value(profile):
		return {"ok": false, "error": "invalid_profile_value"}
	var sandbox: bool = profile.get("edition", "normal") == "pruebas"
	var copy := profile.duplicate(true)
	copy.slot = slot
	var error := _validate(copy, sandbox)
	if not error.is_empty():
		return {"ok": false, "error": error}
	if sandbox:
		copy.credits = Shop.SANDBOX_CREDITS
	var preserved := _preserve_legacy(slot, sandbox)
	if not preserved.ok:
		return preserved
	var path := file_path(slot, sandbox)
	return _write(path, _encode(copy), _read(path, sandbox).ok)

static func load_slot(slot: int, sandbox: bool = false) -> Dictionary:
	if not _valid_slot(slot):
		return _load_result(false, {}, false, "invalid_slot")
	var path := file_path(slot, sandbox)
	# Once the new namespace has any generation, corruption must be visible;
	# silently loading an old slot here would roll back money and progress.
	var current := FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak")
	if not current:
		path = legacy_file_path(slot, sandbox)
	var namespace_version := VERSION if current else 2
	var result := _read(path, sandbox, namespace_version)
	if result.ok:
		result.profile.slot = slot
		return result
	var backup := _read(path + ".bak", sandbox, namespace_version)
	if backup.ok:
		backup.recovered = true
		backup.error = result.error
		backup.profile.slot = slot
		return backup
	return backup if result.error == "slot_empty" and backup.error != "slot_empty" else result

static func export_slot(slot: int, sandbox: bool = false) -> String:
	var result := load_slot(slot, sandbox)
	return _encode(result.profile) if result.ok else ""

static func preview_import(slot: int, json: String, sandbox: bool = false) -> Dictionary:
	if not _valid_slot(slot):
		return _load_result(false, {}, false, "invalid_slot")
	var result := _decode(json, sandbox)
	if result.ok:
		result.profile.slot = slot
	return result

static func import_slot(slot: int, json: String, sandbox: bool = false) -> Dictionary:
	var result := preview_import(slot, json, sandbox)
	if not result.ok:
		return result
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
