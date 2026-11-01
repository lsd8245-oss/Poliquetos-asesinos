extends SceneTree

const Shop = preload("../src/shop/shop.gd")
const Saves = preload("../src/save/saves.gd")
var failures := 0
var checks := 0
var original_files := {}

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	# Restore every touched real file when done, including preexisting backups.
	for sandbox in [false, true]:
		var files: Array = []
		for slot in range(1, 4):
			files.append(Saves.file_path(slot, sandbox))
		files.append(Saves.file_path(1, sandbox).get_base_dir().path_join("options.json"))
		for path in files:
			for suffix in ["", ".bak", ".tmp"]:
				var target: String = path + suffix
				original_files[target] = FileAccess.get_file_as_bytes(target) if FileAccess.file_exists(target) else null
				if FileAccess.file_exists(target):
					DirAccess.remove_absolute(ProjectSettings.globalize_path(target))
	var p: Dictionary = Shop.create_profile()
	check(p.get("version") == 2 and p.get("credits") == 0, "new normal profile")
	var stats: Dictionary = Shop.stats(p)
	check(stats.max_shield == 100 and stats.speed == 160 and stats.max_bombs == 2, "base stats")
	var visit: Dictionary = Shop.visit()
	check(not Shop.purchase(p, "upgrade:dano", visit).ok, "insufficient funds")
	p.credits = 30000
	check(Shop.purchase(p, "upgrade:dano", visit).ok and p.credits == 29700, "purchase exact rank price")
	check(is_equal_approx(Shop.stats(p).damage_mult, 1.12), "upgrade applied")
	check(Shop.purchase(p, "upgrade:dano", visit).ok, "second rank")
	check(Shop.refund(p, "upgrade:dano", visit).ok and p.upgrades.dano == 1 and p.credits == 29700, "refund latest rank first")
	check(Shop.refund(p, "upgrade:dano", visit).ok and p.credits == 30000, "refund full first price")
	check(not Shop.refund(p, "upgrade:dano", visit).ok and p.credits == 30000, "no repeat refund money")
	for _i in range(5):
		check(Shop.purchase(p, "upgrade:dano", visit).ok, "rank below max")
	check(not Shop.purchase(p, "upgrade:dano", visit).ok, "max rank enforced")
	Shop.close_visit(visit)
	visit.closed = false
	check(not Shop.refund(p, "upgrade:dano", visit).ok, "closed visit cannot refund")
	check(not Shop.purchase(p, "gear:draga", visit).ok, "closed visit cannot buy")
	var next_visit: Dictionary = Shop.visit()
	check(not Shop.refund(p, "upgrade:dano", next_visit).ok, "new visit cannot refund earlier purchase")
	check(not Shop.purchase(p, "gear:niskin", next_visit).ok, "act2 locked")
	p.world = 5
	check(Shop.purchase(p, "gear:niskin", next_visit).ok, "act2 unlocked")
	check(not Shop.purchase(p, "gear:rov", next_visit).ok, "act3 locked")
	p.world = 9
	check(Shop.purchase(p, "gear:rov", next_visit).ok, "act3 unlocked")
	p.world = 14
	check(not Shop.purchase(p, "gear:deflector", next_visit).ok, "act4 requires first lab boss")
	p.lab_boss = 1
	check(Shop.purchase(p, "gear:deflector", next_visit).ok, "act4 unlocked")
	var impostor: Dictionary = p.duplicate(true)
	check(not Shop.refund(impostor, "gear:deflector", next_visit).ok, "visit bound to original profile")
	var sandbox: Dictionary = Shop.create_profile(true)
	check(sandbox.credits == 999999999 and sandbox.equipment == {"sonar": true}, "sandbox starts rich with sonar only")
	check(Shop.stats(sandbox) == Shop.stats(Shop.create_profile()), "sandbox has no automatic buffs")
	check(sandbox.weapons.shot == 1 and sandbox.skins.size() == 9, "sandbox cosmetics and weapons")
	var sandbox_visit: Dictionary = Shop.visit()
	check(Shop.purchase(sandbox, "gear:deflector", sandbox_visit).ok, "sandbox all gears available")
	check(sandbox.credits == 999999999, "sandbox purchase restores sentinel")
	check(Shop.refund(sandbox, "gear:deflector", sandbox_visit).ok and sandbox.credits == 999999999, "sandbox refund restores sentinel")
	for upgrade in Shop.catalog().mejoras:
		for _rank in range(int(upgrade.rangos)):
			check(Shop.purchase(sandbox, "upgrade:" + upgrade.id, sandbox_visit).ok, "sandbox purchase rank")
	var maximum: Dictionary = Shop.stats(sandbox)
	check(maximum.max_shield == 200 and maximum.min_missile == 5 and maximum.max_bombs == 5 and maximum.regen == 3, "maximum integer upgrade effects")
	check(is_equal_approx(maximum.damage_mult, 1.6) and is_equal_approx(maximum.rate_mult, 1.4) and is_equal_approx(maximum.speed, 198.4) and maximum.magnet == 144, "maximum fractional upgrade effects")
	check(Shop.purchase(sandbox, "gear:draga", sandbox_visit).ok and Shop.stats(sandbox).magnet == 144, "draga uses maximum radius rather than adding")
	check(p.edition == "normal" and p.credits < 999999999, "sandbox isolated from normal")
	# Save exact native dictionaries, even optional core checkpoint state.
	p.slot = 1
	p.time = 123.5
	p.deaths = {"1": 2}
	p.cleared = [1, 2, 3]
	p.checkpoint = {"time": 67.2, "weapons": {"shot": 4, "missile": 2, "bomb": 1}}
	var save_result: Dictionary = Saves.save_slot(1, p)
	check(save_result.ok, "save real profile")
	var loaded: Dictionary = Saves.load_slot(1)
	check(loaded.ok and not loaded.recovered and loaded.profile == p, "exact profile restored")
	check(Saves.save_slot(1, sandbox).ok, "save sandbox separately")
	check(Saves.load_slot(1).profile == p and Saves.load_slot(1, true).profile.edition == "pruebas", "edition separate files")
	check(not Saves.save_slot(0, p).ok and not Saves.load_slot(4).ok, "only three slots")
	var other: Dictionary = Shop.create_profile()
	other.slot = 2
	other.credits = 123
	check(Saves.save_slot(2, other).ok, "second slot")
	Saves.load_slot(3)
	check(Saves.load_slot(2).profile.credits == 123, "missing slot leaves other slot intact")
	check(Saves.save_slot(1, p).ok, "second save makes backup")
	var file := FileAccess.open(Saves.file_path(1, false), FileAccess.WRITE)
	file.store_string("{broken JSON")
	file.close()
	loaded = Saves.load_slot(1)
	check(loaded.ok and loaded.recovered and loaded.profile == p, "corrupt primary recovers valid backup")
	var legacy := {"version": 1, "coins": 456, "current_world": 3, "difficulty": "hard"}
	var migrated: Dictionary = Saves.import_slot(3, JSON.stringify(legacy))
	check(migrated.ok and migrated.profile.version == 2 and migrated.profile.credits == 456 and migrated.profile.world == 3, "basic version1 migration")
	check(not Saves.import_slot(3, '{"version":99}').ok, "future version rejected")
	check(not Saves.import_slot(3, '{}').ok, "version required")
	check(not Saves.import_slot(3, '{"version":2,"credits":-1}').ok, "invalid profile rejected")
	check(not Saves.import_slot(3, JSON.stringify(sandbox)).ok, "sandbox import cannot overwrite normal edition")
	check(Saves.import_slot(2, Saves.export_slot(3)).ok and Saves.load_slot(2).profile.credits == 456, "export import round trip")
	var malformed: Dictionary = p.duplicate(true)
	malformed.upgrades.dano = 99
	check(not Saves.import_slot(3, JSON.stringify(malformed)).ok, "out of range rank rejected")
	malformed = p.duplicate(true)
	malformed.weapons.shot = 9
	check(not Saves.import_slot(3, JSON.stringify(malformed)).ok, "out of range weapon rejected")
	check(Saves.load_slot(3).profile.credits == 456, "invalid imports preserve existing save")
	var options := {"master": 8, "music": 4, "effects": 6, "screen": "window2", "autofire": true, "shake": false, "reduce_flashes": true, "bindings": {"fire": "Z"}}
	check(Saves.save_options(options).ok, "save options")
	check(Saves.load_options().options == options, "restore exact options")
	check(Saves.load_options(true).options != options, "options isolated by edition")
	check(Saves.save_options(options).ok, "options backup generation")
	file = FileAccess.open(Saves.file_path(1).get_base_dir().path_join("options.json"), FileAccess.WRITE)
	file.store_string("[]")
	file.close()
	check(Saves.load_options().recovered and Saves.load_options().options == options, "corrupt options recover backup")
	check(not Saves.save_options({"master": 11}).ok, "invalid volume rejected")
	for path in original_files:
		if original_files[path] == null:
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		else:
			file = FileAccess.open(path, FileAccess.WRITE)
			file.store_buffer(original_files[path])
			file.close()
	print("shop/save: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
