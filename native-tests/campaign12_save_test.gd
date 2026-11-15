extends SceneTree

const Shop = preload("../src/shop/shop.gd")
const Saves = preload("../src/save/saves.gd")
const Game = preload("../src/core/game.gd")
var checks := 0
var failures := 0
var originals: Dictionary = {}
var initial_migration_files: Dictionary = {}

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run_tests")

func legacy_path(slot: int = 1, sandbox: bool = false) -> String:
	return "user://%s/slot_%d.json" % ["pruebas" if sandbox else "normal", slot]

func current_path(slot: int = 1, sandbox: bool = false) -> String:
	return "user://%s/campaign12/slot_%d.json" % ["pruebas" if sandbox else "normal", slot]

func remember(path: String) -> void:
	if not originals.has(path):
		originals[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null

func remove(path: String) -> void:
	remember(path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func write(path: String, content: String) -> void:
	remember(path)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(content)
	file.close()

func reset_slot(slot: int = 1, sandbox: bool = false) -> void:
	for path in [legacy_path(slot, sandbox), current_path(slot, sandbox)]:
		for suffix in ["", ".bak", ".tmp"]:
			remove(path + suffix)

func legacy(world: int = 1, version: int = 2, sandbox: bool = false) -> Dictionary:
	return {
		"version": version, "edition": "pruebas" if sandbox else "normal", "slot": 1,
		"difficulty": "hard", "world": world, "lab_boss": 0, "credits": 3456,
		"upgrades": {"dano": 2, "cadencia": 1}, "equipment": {"sonar": true, "draga": true, "rov": false},
		"weapons": {"shot": 4, "missile": 2, "bomb": 3}, "bombs": 2,
		"skins": ["original", "coral", "abisal"], "skin": "coral",
		"colors": {"hull": "#75c9df", "lights": "#d7ffed", "trail": "#4a9cff"},
		"deaths": {}, "time": 123.5, "cleared": [], "seed": 147001, "completed": false
	}

func migration_files(sandbox: bool = false) -> Dictionary:
	var result: Dictionary = {}
	var path := current_path(1, sandbox).get_base_dir().path_join("migration")
	var directory := DirAccess.open(path)
	if directory != null:
		for name in directory.get_files():
			var target := path.path_join(name)
			result[target] = FileAccess.get_file_as_bytes(target)
	return result

func check_legacy_mapping() -> void:
	var destinations := [1, 2, 2, 3, 4, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]
	for version in [1, 2]:
		for world in range(1, 16):
			reset_slot()
			var p := legacy(world, version)
			p.entry_world = world
			p.lander_used_world = world
			p.optional_history = {"counter": 17, "list": [4, 3.25]}
			var raw: String = Saves._encode(p)
			write(legacy_path(), raw)
			var before := FileAccess.get_file_as_bytes(legacy_path())
			var loaded: Dictionary = Saves.load_slot(1)
			check(loaded.ok, "legacy v%d world%d accepted: %s" % [version, world, loaded.error])
			if not loaded.ok:
				continue
			var actual: Dictionary = loaded.profile
			check(actual.version == 3 and actual.world == destinations[world - 1], "v%d old%d has safe destination" % [version, world])
			check(actual.entry_world == destinations[world - 1] and actual.lander_used_world == destinations[world - 1], "entry/lander mapped")
			check(loaded.get("migrated", false) and not str(loaded.get("migration_notice", "")).is_empty(), "legacy load requires migration confirmation")
			check(actual.credits == 3456 and actual.upgrades == p.upgrades and actual.equipment == p.equipment and actual.weapons == p.weapons and actual.skins == p.skins and actual.skin == "coral", "migration preserves money and build")
			check(actual.optional_history.counter is int and actual.optional_history.list[0] is int, "optional integer metadata survives migration")
			check(not FileAccess.file_exists(current_path()) and FileAccess.get_file_as_bytes(legacy_path()) == before, "load is read only")
			if world in [3, 6]:
				check(str(loaded.get("migration_notice", "")).contains(str(world)) and str(loaded.get("migration_notice", "")).contains(str(destinations[world - 1])), "removed world explicit notice")
				check(actual.get("migration_meta", {}).get("decision") == "removed_world_to_previous_entry", "removed world decision recorded")
	reset_slot()
	write(legacy_path(), '{"version":1,"coins":456,"current_world":14,"lab_boss":4}')
	var loaded: Dictionary = Saves.load_slot(1)
	check(loaded.ok and loaded.profile.world == 12 and loaded.profile.lab_boss == 3 and loaded.profile.credits == 456 and loaded.profile.equipment == {"sonar": true}, "v1 defaults use old campaign and lab limits")
	for lab in range(5):
		reset_slot()
		var p := legacy(14)
		p.lab_boss = lab
		p.resume = "rest"
		write(legacy_path(), JSON.stringify(p))
		loaded = Saves.load_slot(1)
		check(loaded.ok and loaded.profile.lab_boss == [0, 1, 1, 2, 3][lab] and loaded.profile.resume == "rest", "legacy lab%d maps without lost rest" % lab)
	for world in [3, 6]:
		reset_slot()
		var p := legacy(world)
		p.resume = "rest"
		p.world_elapsed = 190.0
		p.checkpoint = {"time": 90.0, "cursor": 8}
		write(legacy_path(), JSON.stringify(p))
		loaded = Saves.load_slot(1)
		check(loaded.ok and loaded.profile.resume == "playing" and loaded.profile.get("world_elapsed", 0) == 0 and not loaded.profile.has("checkpoint"), "removed rest returns to safe entry without foreign checkpoint")

func check_history_and_replay() -> void:
	reset_slot()
	var p := legacy(14)
	p.lab_boss = 3
	p.cleared = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
	p.deaths = {"3": 7, "4": 2, "6": 11, "8": 5, "14": 1, "15": 3}
	p.rewarded = {"3:0": true, "4:0": true, "6:0": true, "8:0": true, "14:0": true, "14:1": true, "14:2": true, "14:3": true}
	p.claimed_drops = {"4:0:wave_7_2_coin": true, "14:1:wave_4_1_coin": true, "14:2:wave_3_2_coin": true, "3:0:wave_5_1_coin": true}
	p.replay_mode = true
	p.replay_return = legacy(6)
	p.replay_return.resume = "rest"
	p.replay_return.replay_return = legacy(15)
	p.replay_return.replay_return.completed = true
	p.replay_return.replay_return.resume = "completed"
	write(legacy_path(), Saves._encode(p))
	var result: Dictionary = Saves.load_slot(1)
	check(result.ok, "nested history accepted: " + result.error)
	if not result.ok:
		return
	var actual: Dictionary = result.profile
	check(actual.cleared == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], "cleared only surviving main worlds")
	check(actual.deaths == {"retired:3": 7, "3": 2, "retired:6": 11, "6": 5, "12": 1, "13": 3}, "death totals kept with disjoint retired keys")
	check(actual.rewarded.get("3:0", false) and actual.rewarded.get("6:0", false) and actual.rewarded.get("12:0", false) and actual.rewarded.get("12:1", false) and actual.rewarded.get("12:2", false), "surviving boss rewards stay deduplicated")
	check(actual.rewarded.get("historical:world:3:0", false) and actual.rewarded.get("historical:world:6:0", false) and actual.rewarded.get("historical:epitoka:14:1", false), "retired victories cannot collide with active rewards")
	check(actual.claimed_drops.get("3:0:wave_7_2_coin", false) and actual.claimed_drops.get("12:1:wave_3_2_coin", false) and actual.claimed_drops.get("historical:epitoka:14:1:wave_4_1_coin", false), "drop UIDs retain legacy event indices")
	check(actual.get("migration_meta", {}).get("historical_cleared", []) == [3, 6, 15], "retired cleared history is recoverable")
	check(actual.replay_return.world == 4 and actual.replay_return.resume == "playing" and actual.replay_return.replay_return.world == 13 and actual.replay_return.replay_return.completed and actual.replay_return.replay_return.resume == "completed", "replay return recursively migrated and completion preserved")

func check_deep_replay_notices() -> void:
	for version in [1, 2]:
		for retired_world in [3, 6]:
			reset_slot()
			var p := legacy(1, version)
			p.credits = 901
			p.history = {"coins": [17, 23], "label": "root"}
			p.replay_mode = true
			p.replay_return = legacy(4, version)
			p.replay_return.credits = 802
			p.replay_return.history = {"visits": 7, "label": "survivor"}
			p.replay_return.replay_return = legacy(retired_world, version)
			p.replay_return.replay_return.credits = 703
			p.replay_return.replay_return.history = {"visits": 9, "label": "retired"}
			p.replay_return.replay_return.resume = "rest"
			var raw: String = Saves._encode(p)
			write(legacy_path(), raw)
			for source in ["load", "preview"]:
				var result: Dictionary = Saves.load_slot(1) if source == "load" else Saves.preview_import(1, raw)
				check(result.ok, "deep retired notice input v%d/%d/%s valid" % [version, retired_world, source])
				if not result.ok:
					continue
				var notice: String = result.migration_notice
				var destination := 2 if retired_world == 3 else 4
				check(notice.contains("antiguo mundo %d" % retired_world) and notice.contains("mundo %d" % destination), "deep retired%d destination notice reaches %s root" % [retired_world, source])
				var actual: Dictionary = result.profile
				check(actual.world == 1 and actual.replay_return.world == 3 and actual.replay_return.replay_return.world == destination and actual.replay_return.replay_return.resume == "playing", "deep safe destination preserves surviving replay path")
				check(actual.credits == 901 and actual.history == p.history and actual.replay_return.credits == 802 and actual.replay_return.history == p.replay_return.history and actual.replay_return.replay_return.credits == 703 and actual.replay_return.replay_return.history == p.replay_return.replay_return.history, "deep warning propagation preserves all credits and optional history")
			check(FileAccess.get_file_as_string(legacy_path()) == raw and not FileAccess.file_exists(current_path()), "deep notice load/preview remain read only")
	reset_slot()
	var repeated := legacy(1)
	repeated.replay_return = legacy(4)
	repeated.replay_return.replay_return = legacy(3)
	repeated.replay_return.replay_return.replay_return = legacy(6)
	repeated.replay_return.replay_return.replay_return.replay_return = legacy(3)
	var result: Dictionary = Saves.preview_import(1, Saves._encode(repeated))
	check(result.ok, "repeated deep retired worlds accepted")
	if result.ok:
		check(result.profile.migration_meta.get("retired_worlds", []) == [3, 6], "deep warning tracks unique retired worlds")
		check(result.migration_notice.count("antiguo mundo 3") == 1 and result.migration_notice.count("antiguo mundo 6") == 1 and result.migration_notice.count("Partida antigua") == 1, "deep warnings summarize each retired world once without repeated generic text")

func phase_coin_game(profile: Dictionary, owner: String):
	var g = Game.new()
	g.start(Shop.create_profile())
	# The production UID formatter needs only the persisted world/room and
	# owner. No archived encounter or actor reconstruction is needed to use it.
	g.profile = profile
	g.refresh_stats()
	check(g.enemy_bullet(Vector2(200, 100), Vector2.ZERO), "phase fixture creates a real pooled projectile")
	g.clear_enemy_bullets(true, owner, 2)
	check(g.enemy_bullets.is_empty() and g.drops.size() == 1, "production phase clear converts real projectile to one coin")
	return g

func check_phase_coin_uid_migration() -> void:
	var cases := [
		{"world": 4, "room": 0, "owner": "boss:boss_w04_tere", "old_key": "4:0:phase:boss:boss_w04_tere:2:0", "new_key": "3:0:phase:boss:boss_w03_tere:2:0", "boss": "boss_w03_tere"},
		{"world": 5, "room": 0, "owner": "boss:boss_w05_hermo", "old_key": "5:0:phase:boss:boss_w05_hermo:2:0", "new_key": "4:0:phase:boss:boss_w04_hermo:2:0", "boss": "boss_w04_hermo"},
		{"world": 14, "room": 2, "owner": "boss:boss_w14_scientist", "old_key": "14:2:phase:boss:boss_w14_scientist:2:0", "new_key": "12:1:phase:boss:boss_w12_scientist:2:0", "boss": "boss_w12_scientist"},
		{"world": 14, "room": 3, "owner": "boss:boss_w14_eunice_titan", "old_key": "14:3:phase:boss:boss_w14_eunice_titan:2:0", "new_key": "12:2:phase:boss:boss_w12_eunice_titan:2:0", "boss": "boss_w12_eunice_titan"},
		{"world": 14, "room": 0, "owner": "robot_group", "old_key": "14:0:phase:robot_group:2:0", "new_key": "12:0:phase:robot_group:2:0", "boss": ""}
	]
	for version in [1, 2]:
		for row in cases:
			var p := legacy(int(row.world), version)
			p.lab_boss = int(row.room)
			var source = phase_coin_game(p, row.owner)
			if source.drops.size() != 1:
				continue
			var coin: Dictionary = source.drops[0].duplicate(true)
			check(coin.uid == row.old_key, "legacy phase key matches production owner shape")
			source.collect_drop(coin)
			var credited: float = float(p.credits)
			check(credited > 3456 and p.claimed_drops.has(row.old_key), "legacy phase coin actually credited and persisted")
			# Nested replay migration must translate the same semantic owner.
			p.replay_return = legacy(4, version)
			p.replay_return.claimed_drops = {"4:0:phase:boss:boss_w04_tere:2:0": true}
			p.replay_return.replay_return = legacy(14, version)
			p.replay_return.replay_return.lab_boss = 2
			p.replay_return.replay_return.claimed_drops = {"14:2:phase:boss:boss_w14_scientist:2:0": true}
			var preview: Dictionary = Saves.preview_import(1, Saves._encode(p))
			check(preview.ok, "collected legacy phase coin profile migrates")
			if not preview.ok:
				continue
			check(preview.profile.claimed_drops.has(row.new_key) and preview.profile.replay_return.claimed_drops.has("3:0:phase:boss:boss_w03_tere:2:0") and preview.profile.replay_return.replay_return.claimed_drops.has("12:1:phase:boss:boss_w12_scientist:2:0"), "phase owner mapped in campaign and nested regular/lab replay")
			var current = Game.new()
			current.start(preview.profile)
			var owner := "robot_group"
			if row.boss != "":
				check(current.boss_system.spawn(current, row.boss), "current final actor supplies its genuine runtime owner")
				owner = str(current.enemies[-1].uid)
			var unclaimed: Dictionary = preview.profile.duplicate(true)
			unclaimed.claimed_drops = {}
			var fresh = phase_coin_game(unclaimed, owner)
			check(fresh.drops.size() == 1 and fresh.drops[0].uid == row.new_key, "current production clear creates the independently expected phase UID")
			check(current.enemy_bullet(Vector2(200, 100), Vector2.ZERO), "current phase fixture emits projectile")
			current.clear_enemy_bullets(true, owner, 2)
			check(current.drops.is_empty() and current.profile.credits == credited, "migrated phase claim suppresses current coin emission without double credit")
			coin = fresh.drops[0].duplicate(true)
			current.collect_drop(coin)
			current.collect_drop(coin)
			check(current.profile.credits == credited, "direct repeated phase pickup cannot credit a migrated claim")
			current.retry()
			current.enemy_bullet(Vector2(200, 100), Vector2.ZERO)
			current.clear_enemy_bullets(true, owner, 2)
			check(current.drops.is_empty() and current.profile.credits == credited, "phase claim remains deduplicated after actual retry")
	var historical := legacy(4)
	historical.claimed_drops = {
		"3:0:phase:boss:boss_w03_polyn:2:0": true,
		"6:0:phase:boss:boss_w06_leafqueen:2:0": true,
		"14:1:phase:boss:boss_w14_epitoke:2:0": true,
		"4:0:enemy:boss_w04_tere": true,
		"4:0:phase:custom:boss_w04_tere:2:0": true,
		"4:0:wave_7_boss_w04_tere": true
	}
	var migrated: Dictionary = Saves.preview_import(1, Saves._encode(historical))
	check(migrated.ok, "historical and unrelated owner-shaped UID input accepted")
	if migrated.ok:
		check(migrated.profile.claimed_drops == {
			"historical:world:3:0:phase:boss:boss_w03_polyn:2:0": true,
			"historical:world:6:0:phase:boss:boss_w06_leafqueen:2:0": true,
			"historical:epitoka:14:1:phase:boss:boss_w14_epitoke:2:0": true,
			"3:0:enemy:boss_w04_tere": true,
			"3:0:phase:custom:boss_w04_tere:2:0": true,
			"3:0:wave_7_boss_w04_tere": true
		}, "semantic owner migration preserves retired/Epitoka history and unrelated UID text")

func check_storage_and_validation() -> void:
	reset_slot()
	check(not Saves.load_slot(1).ok and Saves.load_slot(1).error == "slot_empty", "absent slot remains absent")
	var p := legacy(4)
	var raw := Saves._encode(p)
	write(legacy_path(), raw)
	write(legacy_path() + ".bak", raw.replace("3456", "2345"))
	var originals_before := {legacy_path(): FileAccess.get_file_as_bytes(legacy_path()), legacy_path() + ".bak": FileAccess.get_file_as_bytes(legacy_path() + ".bak")}
	var evidence_before := migration_files()
	var loaded: Dictionary = Saves.load_slot(1)
	check(migration_files() == evidence_before, "load does not create migration evidence")
	check(loaded.ok and Saves.save_slot(1, loaded.profile).ok, "first migrated save writes new namespace")
	var evidence := migration_files()
	var copies := evidence.values()
	check(copies.has(originals_before[legacy_path()]) and copies.has(originals_before[legacy_path() + ".bak"]), "first save preserves byte identical primary and backup")
	check(FileAccess.get_file_as_bytes(legacy_path()) == originals_before[legacy_path()] and FileAccess.get_file_as_bytes(legacy_path() + ".bak") == originals_before[legacy_path() + ".bak"], "save never alters legacy originals")
	loaded = Saves.load_slot(1)
	check(loaded.ok and not loaded.get("migrated", true) and loaded.profile.world == 3, "current v3 world3 not remapped")
	check(Saves.save_slot(1, loaded.profile).ok and migration_files() == evidence, "evidence immutable on repeated save")
	write(current_path(), "{bad current")
	loaded = Saves.load_slot(1)
	check(loaded.ok and loaded.recovered and not loaded.get("migrated", true) and loaded.profile.world == 3 and loaded.error == "invalid_json", "corrupt v3 recovers v3 backup")
	remove(current_path() + ".bak")
	check(not Saves.load_slot(1).ok, "corrupt current never silently reverts to valid old progress")
	remove(current_path())
	write(legacy_path(), "{bad old")
	loaded = Saves.load_slot(1)
	check(loaded.ok and loaded.recovered and loaded.get("migrated", false) and loaded.profile.credits == 2345, "corrupt old primary recovers and migrates backup")
	# A real obstructing directory forces copy/IO failure without touching old files.
	reset_slot(2)
	write(legacy_path(2), raw)
	loaded = Saves.load_slot(2)
	var migration_blocker := current_path(2) + ".tmp"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(migration_blocker))
	check(loaded.ok and not Saves.save_slot(2, loaded.profile).ok and FileAccess.get_file_as_string(legacy_path(2)) == raw and not FileAccess.file_exists(current_path(2)), "IO failure never overwrites legacy primary")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(migration_blocker))
	# Immutable-copy collision must stop a save, even if writable current data exists.
	if not evidence.is_empty():
		var evidence_path := ""
		for candidate in evidence:
			if evidence[candidate] == originals_before[legacy_path()]:
				evidence_path = candidate
				break
		var bytes: PackedByteArray = evidence[evidence_path]
		write(evidence_path, "evidence was damaged")
		reset_slot()
		write(legacy_path(), raw)
		loaded = Saves.load_slot(1)
		check(loaded.ok and not Saves.save_slot(1, loaded.profile).ok and not FileAccess.file_exists(current_path()), "damaged immutable copy cancels migration save")
		var file := FileAccess.open(evidence_path, FileAccess.WRITE)
		file.store_buffer(bytes)
		file.close()
	for version in [1, 2, 3, 4]:
		reset_slot()
		var invalid := legacy(16, version)
		var path := current_path() if version >= 3 else legacy_path()
		write(path, JSON.stringify(invalid))
		check(not Saves.load_slot(1).ok, "out of range world/future version rejected v%d" % version)
	reset_slot()
	var future := Shop.create_profile()
	future.version = 4
	write(current_path(), JSON.stringify(future))
	check(not Saves.load_slot(1).ok and Saves.load_slot(1).error == "unsupported_version", "future4 with otherwise valid data rejected")
	for world in [14, 15]:
		var invalid := Shop.create_profile()
		invalid.world = world
		write(current_path(), JSON.stringify(invalid))
		check(not Saves.load_slot(1).ok, "v3 cannot accept legacy ID%d" % world)
	write(current_path(), JSON.stringify(legacy(4)))
	check(not Saves.load_slot(1).ok and Saves.load_slot(1).error == "campaign_namespace_mismatch", "v2 cannot silently migrate from current namespace")
	reset_slot()
	write(current_path() + ".bak", JSON.stringify(Shop.create_profile()))
	write(legacy_path(), raw)
	loaded = Saves.load_slot(1)
	check(loaded.ok and loaded.recovered and not loaded.migrated and loaded.profile.world == 1, "backup-only v3 takes priority over old primary")
	write(current_path() + ".bak", "{bad backup")
	check(not Saves.load_slot(1).ok and Saves.load_slot(1).error == "invalid_json", "corrupt backup-only v3 cannot fall back to legacy")
	reset_slot()
	write(legacy_path() + ".bak", raw)
	loaded = Saves.load_slot(1)
	check(loaded.ok and loaded.recovered and loaded.migrated and loaded.profile.world == 3 and not FileAccess.file_exists(current_path()), "backup-only legacy migrates read only")
	for field in ["upgrades", "equipment", "credits", "deaths", "rewarded", "claimed_drops", "replay_return"]:
		reset_slot()
		var invalid := legacy(4)
		match field:
			"upgrades": invalid.upgrades = {"dano": 99}
			"equipment": invalid.equipment = {"sonar": true, "unknown": true}
			"credits": invalid.credits = -1
			"deaths": invalid.deaths = {"16": 1}
			"rewarded": invalid.rewarded = {"16:0": true}
			"claimed_drops": invalid.claimed_drops = {"4:5:wave_0": true}
			"replay_return": invalid.replay_return = legacy(4, 2, true)
		write(legacy_path(), JSON.stringify(invalid))
		check(not Saves.load_slot(1).ok, "legacy validated before mapping " + field)
	var current := Shop.create_profile()
	current.coins_total = INF
	check(not Saves.save_slot(1, current).ok, "native infinity rejected")
	current.coins_total = NAN
	check(not Saves.save_slot(1, current).ok, "native NaN rejected")
	current.erase("coins_total")
	current.replay_return = current
	check(not Saves.save_slot(1, current).ok, "native replay cycle rejected")
	current.erase("replay_return")
	reset_slot(1, true)
	write(legacy_path(1, true), JSON.stringify(legacy(15, 2, true)))
	loaded = Saves.load_slot(1, true)
	check(loaded.ok and loaded.profile.world == 13 and loaded.profile.credits == 999999999 and loaded.profile.equipment.rov == false, "sandbox migration is isolated and purchases stay pending")
	write(current_path(), JSON.stringify(Shop.create_profile(true)))
	check(not Saves.load_slot(1).ok and Saves.load_slot(1).error == "edition_mismatch", "edition mismatch rejected")
	for edition in [false, true]:
		var options := {"master": 8, "screen": "fullscreen", "bindings": {"fire": "Z"}, "music": 4 if edition else 6}
		var path := legacy_path(1, edition).get_base_dir().path_join("options.json")
		remember(path)
		remember(path + ".bak")
		check(Saves.save_options(options, edition).ok and Saves.load_options(edition).options == options and FileAccess.file_exists(path), "existing edition options path and exact values preserved")
		check(not FileAccess.file_exists(current_path(1, edition).get_base_dir().path_join("options.json")), "options not moved into campaign namespace")
	check(Saves.load_options().options.music == 6 and Saves.load_options(true).options.music == 4, "options editions remain separate")

func check_atomic_backup() -> void:
	reset_slot(2)
	var p := Shop.create_profile()
	p.credits = 100
	check(Saves.save_slot(2, p).ok, "first atomic generation")
	p.credits = 200
	check(Saves.save_slot(2, p).ok, "second atomic generation")
	var main_bytes := FileAccess.get_file_as_bytes(current_path(2))
	var backup_bytes := FileAccess.get_file_as_bytes(current_path(2) + ".bak")
	var blocker := current_path(2) + ".bak.tmp"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(blocker))
	p.credits = 300
	check(not Saves.save_slot(2, p).ok and FileAccess.get_file_as_bytes(current_path(2)) == main_bytes and FileAccess.get_file_as_bytes(current_path(2) + ".bak") == backup_bytes, "failed backup IO preserves both committed generations")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(blocker))
	write(current_path(2), "{bad primary")
	p.credits = 400
	check(Saves.save_slot(2, p).ok and FileAccess.get_file_as_bytes(current_path(2) + ".bak") == backup_bytes, "repair does not promote corrupt primary over valid backup")

func check_fractional_time_roundtrip() -> void:
	reset_slot(2)
	var elapsed := 0.0
	for _tick in range(9149):
		elapsed += 1.0 / 30.0
	var p := Shop.create_profile()
	p.slot = 2
	p.resume = "rest"
	p.time = elapsed
	p.world_elapsed = elapsed
	p.history = {"fractional_time": elapsed, "integer_count": 9149}
	check(Saves.save_slot(2, p).ok, "fractional rest profile saved")
	var loaded: Dictionary = Saves.load_slot(2)
	check(loaded.ok, "fractional rest profile loaded")
	if loaded.ok:
		check(loaded.profile.time == elapsed, "accumulated 1/30 total time survives exactly")
		check(loaded.profile.world_elapsed == elapsed, "accumulated 1/30 world time survives exactly")
		check(loaded.profile == p, "fractional rest profile and integer metadata round trip exactly")
	var preview: Dictionary = Saves.preview_import(2, Saves._encode(p))
	check(preview.ok and preview.profile == p, "fractional time export/import preview preserves exact profile")

func check_seed_bounds() -> void:
	for sandbox in [false, true]:
		for seed_value in [0, 2147483647, 2147483648, 4294967295]:
			reset_slot(2, sandbox)
			reset_slot(3, sandbox)
			var p := Shop.create_profile(sandbox)
			p.slot = 2
			p.seed = seed_value
			check(Saves.save_slot(2, p).ok, "new uint32 seed%d saves in edition%s" % [seed_value, sandbox])
			var loaded: Dictionary = Saves.load_slot(2, sandbox)
			check(loaded.ok and loaded.profile.seed == seed_value and loaded.profile.seed is int, "new uint32 seed restores exactly as integer")
			var imported: Dictionary = Saves.import_slot(3, Saves._encode(p), sandbox)
			check(imported.ok and imported.profile.seed == seed_value and Saves.load_slot(3, sandbox).profile.seed == seed_value, "v3 import preserves full uint32 seed")
			for version in [1, 2]:
				reset_slot(2, sandbox)
				var old := legacy(14, version, sandbox)
				old.seed = seed_value
				var raw: String = Saves._encode(old)
				write(legacy_path(2, sandbox), raw)
				loaded = Saves.load_slot(2, sandbox)
				check(loaded.ok and loaded.migrated and loaded.profile.seed == seed_value and loaded.profile.seed is int, "legacy v%d uint32 seed migrates unchanged" % version)
				if loaded.ok:
					check(Saves.save_slot(2, loaded.profile).ok and Saves.load_slot(2, sandbox).profile.seed == seed_value, "migrated uint32 seed survives new namespace roundtrip")
				check(FileAccess.get_file_as_string(legacy_path(2, sandbox)) == raw, "seed migration never rewrites original")
				imported = Saves.import_slot(3, raw, sandbox)
				check(imported.ok and imported.migrated and imported.profile.seed == seed_value and Saves.load_slot(3, sandbox).profile.seed == seed_value, "legacy uint32 import persists exact seed")
		# Invalid native/JSON inputs must not replace the last valid generation.
		var before := FileAccess.get_file_as_bytes(current_path(3, sandbox))
		for seed_value in [-1, 4294967296, 0.25, NAN]:
			var p := Shop.create_profile(sandbox)
			p.seed = seed_value
			check(not Saves.save_slot(3, p).ok, "invalid native seed rejected")
			for version in [1, 2, 3]:
				reset_slot(2, sandbox)
				var invalid := legacy(1, version, sandbox)
				invalid.seed = seed_value
				var raw: String
				if seed_value is float and not is_finite(seed_value):
					invalid.seed = 147001
					raw = JSON.stringify(invalid).replace('"seed":147001', '"seed":NaN')
				else:
					raw = Saves._encode(invalid)
				write(current_path(2, sandbox) if version == 3 else legacy_path(2, sandbox), raw)
				check(not Saves.load_slot(2, sandbox).ok and not Saves.preview_import(3, raw, sandbox).ok and not Saves.import_slot(3, raw, sandbox).ok, "invalid seed rejected by load/preview/import v%d" % version)
			check(FileAccess.get_file_as_bytes(current_path(3, sandbox)) == before, "invalid seed operations preserve prior committed slot")
		var bad_credits := Shop.create_profile(sandbox)
		bad_credits.seed = 4294967295
		bad_credits.credits = 2147483648
		check(not Saves.save_slot(3, bad_credits).ok, "unsigned seed acceptance does not relax credit limits")

func check_import_preview() -> void:
	# Missing preview previously forced the UI to write a migrated import before
	# the player could read or cancel the removed-world destination notice.
	var api = Saves.new()
	if not api.has_method("preview_import"):
		check(false, "import preview must expose migration notice without writing")
		return
	reset_slot(2)
	var p := Shop.create_profile()
	p.credits = 888
	check(Saves.save_slot(2, p).ok and Saves.save_slot(2, p).ok, "existing generations for cancelled import")
	write(legacy_path(2), JSON.stringify(legacy(4)))
	write(legacy_path(2) + ".bak", "{old backup raw")
	var before: Dictionary = migration_files()
	for path in [current_path(2), current_path(2) + ".bak", legacy_path(2), legacy_path(2) + ".bak"]:
		before[path] = FileAccess.get_file_as_bytes(path)
	for version in [1, 2, 3]:
		var incoming := legacy(6, version) if version < 3 else Shop.create_profile()
		if version == 1:
			incoming = {"version": 1, "coins": 456, "current_world": 3}
		var result: Dictionary = api.call("preview_import", 2, JSON.stringify(incoming))
		check(result.ok and result.profile.slot == 2 and result.profile.world == [2, 4, 1][version - 1] and result.profile.version == 3, "preview migrates and targets selected slot v%d" % version)
		check(result.get("migrated", false) == (version < 3) and (version == 3 or not str(result.get("migration_notice", "")).is_empty()), "preview supplies confirmation metadata v%d" % version)
	var invalid: Dictionary = api.call("preview_import", 0, JSON.stringify(legacy()))
	check(not invalid.ok and invalid.error == "invalid_slot", "preview rejects invalid slot")
	invalid = api.call("preview_import", 2, JSON.stringify(legacy(4, 2, true)))
	check(not invalid.ok and invalid.error == "edition_mismatch", "preview rejects other edition")
	invalid = api.call("preview_import", 2, "{bad incoming")
	check(not invalid.ok and invalid.error == "invalid_json", "preview rejects corrupt input")
	var after := migration_files()
	for path in [current_path(2), current_path(2) + ".bak", legacy_path(2), legacy_path(2) + ".bak"]:
		after[path] = FileAccess.get_file_as_bytes(path)
	check(after == before and not FileAccess.file_exists(current_path(2) + ".tmp"), "all previews are read only including legacy originals and evidence")
	var imported: Dictionary = Saves.import_slot(2, JSON.stringify(legacy(6)))
	var loaded: Dictionary = Saves.load_slot(2)
	check(imported.ok and imported.migrated and loaded.ok and loaded.profile.world == 4 and loaded.profile.credits == 3456, "confirmed import uses validated new writer")
	check(FileAccess.get_file_as_bytes(legacy_path(2)) == before[legacy_path(2)] and FileAccess.get_file_as_bytes(legacy_path(2) + ".bak") == before[legacy_path(2) + ".bak"], "confirmed import preserves both old raw generations")

func check_shop_and_rest() -> void:
	var p := Shop.create_profile()
	check(p.version == 3 and p.equipment == {"sonar": true}, "new v3 profile with initial sonar only")
	var expected := [1, 1, 1, 2, 2, 2, 3, 3, 3, 3, 3, 3, 4]
	for world in range(1, 14):
		p.world = world
		check(Shop.available_act(p) == expected[world - 1], "new world%d act boundary" % world)
	p.world = 12
	p.lab_boss = 1
	check(Shop.available_act(p) == 4, "act4 unlocks after first lab final")
	var gear := ["draga", "niskin", "rov", "deflector"]
	var costs := [600, 900, 1500, 2000]
	for index in range(4):
		reset_slot(3)
		p = Shop.create_profile()
		p.slot = 3
		p.world = [1, 4, 7, 12][index]
		p.lab_boss = 1 if index == 3 else 0
		p.resume = "rest"
		p.credits = 10000
		check(Saves.save_slot(3, p).ok, "save rest before purchase")
		var loaded: Dictionary = Saves.load_slot(3)
		if not loaded.ok:
			check(false, "reload rest succeeds")
			continue
		p = loaded.profile
		var visit := Shop.visit()
		var transaction: Dictionary = Shop.purchase(p, "gear:" + gear[index], visit)
		check(transaction.ok and transaction.cost == costs[index] and p.credits == 10000 - costs[index], "act gear original price")
		check(Shop.refund(p, "gear:" + gear[index], visit).ok and p.credits == 10000, "same visit exact refund")
		check(not Shop.refund(p, "gear:" + gear[index], visit).ok and p.credits == 10000, "refund cannot mint coins")
		check(Shop.purchase(p, "gear:" + gear[index], visit).ok and Saves.save_slot(3, p).ok, "purchase persists at rest")
		Shop.close_visit(visit)
		loaded = Saves.load_slot(3)
		check(loaded.ok and loaded.profile.resume == "rest" and loaded.profile.equipment.get(gear[index], false) and loaded.profile.credits == 10000 - costs[index], "close/reload preserves rest purchase")
		check(not Shop.refund(loaded.profile, "gear:" + gear[index], Shop.visit()).ok, "new visit cannot refund saved purchase")
	var sandbox := Shop.create_profile(true)
	check(Shop.available_act(sandbox) == 4 and Shop.stats(sandbox) == Shop.stats(Shop.create_profile()), "sandbox unlocks without automatic stats")
	var sandbox_visit := Shop.visit()
	check(Shop.purchase(sandbox, "gear:deflector", sandbox_visit).ok and sandbox.credits == 999999999 and Shop.refund(sandbox, "gear:deflector", sandbox_visit).ok and sandbox.credits == 999999999, "sandbox infinite money obeys purchase/refund tokens")

func run_tests() -> void:
	if OS.get_cmdline_user_args().has("--phase-coins-only"):
		check_phase_coin_uid_migration()
		print("CAMPAIGN12 PHASE COIN %s: %d checks; %d failures" % ["PASS" if failures == 0 else "FAIL", checks, failures])
		quit(0 if failures == 0 else 1)
		return
	for sandbox in [false, true]:
		initial_migration_files.merge(migration_files(sandbox))
	check_legacy_mapping()
	check_history_and_replay()
	check_deep_replay_notices()
	check_phase_coin_uid_migration()
	check_storage_and_validation()
	check_atomic_backup()
	check_fractional_time_roundtrip()
	check_seed_bounds()
	check_import_preview()
	check_shop_and_rest()
	for path in originals:
		if originals[path] == null:
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		else:
			var file := FileAccess.open(path, FileAccess.WRITE)
			file.store_buffer(originals[path])
			file.close()
	for sandbox in [false, true]:
		for path in migration_files(sandbox):
			if not initial_migration_files.has(path):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("CAMPAIGN12 SAVE %s: %d checks; %d failures" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)
