class_name PoliData
extends RefCounted

static func path_for(relative: String) -> String:
	# Exported games may override content by dropping PNG/JSON next to the EXE.
	var external = OS.get_executable_path().get_base_dir().path_join(relative)
	if FileAccess.file_exists(external):
		return external
	return "res://" + relative

static func read_json(relative: String, fallback = null):
	var path = path_for(relative)
	if not FileAccess.file_exists(path):
		return fallback
	var parsed = JSON.new()
	var err = parsed.parse(FileAccess.get_file_as_string(path))
	if err != OK:
		push_error("JSON inválido: %s, línea %d: %s" % [relative, parsed.get_error_line(), parsed.get_error_message()])
		return fallback
	return parsed.data

static func all() -> Dictionary:
	var d = {}
	for name in ["combat", "worlds", "enemies", "bosses", "shop", "cosmetics", "escape", "boss_patterns"]:
		d[name] = read_json("data/%s.json" % name, {} if name in ["combat", "shop", "escape", "boss_patterns"] else [])
	d["waves"] = {}
	for n in range(1, 15):
		d.waves[n] = read_json("data/waves/world_%02d.json" % n, {"eventos":[]})
	return d
