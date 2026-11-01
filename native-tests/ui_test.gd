extends SceneTree
const Main = preload("res://src/core/main.gd")
const Shop = preload("res://src/shop/shop.gd")
const Save = preload("res://src/save/saves.gd")
var checks = 0
func check(value: bool, description: String):
	checks += 1
	if not value:
		push_error("UI TEST FAILED: " + description)
		quit(1)
		assert(false, description)
func _initialize():
	call_deferred("run")
func key(code):
	var event = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	return event
func run():
	var ui = Main.new()
	root.add_child(ui)
	await process_frame
	ui.set_process(false)
	check(ui.screen == "splash", "native cover starts before menu")
	check(ui.assets.has_sprite("w01_ui_ship_original_move"), "PNG renderer loaded")
	ui._input(key(KEY_ENTER))
	check(ui.screen == "title", "Start opens title")
	check(ui.buttons.size() == (6 if ui.sandbox else 5), "edition only exposes permitted actions")
	ui._activate("new")
	ui._activate("difficulty:hard")
	check(ui.screen == "slots" and ui.difficulty == "hard", "new game selects difficulty before slot")
	var profile = Shop.create_profile(false, "normal")
	profile.credits = 5000
	profile.slot = 3
	ui._start(profile)
	ui.intro_clock = 0
	check(ui.game.player.shield == ui.game.stats.max_shield, "normal profile starts at base shield")
	ui._input(key(KEY_ESCAPE))
	check(ui.screen == "pause" and ui.game.state == "pause", "pause freezes engine")
	ui._activate("resume")
	check(ui.game.state == "countdown" and ui.screen == "game", "resume uses engine countdown")
	ui.game.state = "playing"
	ui._show("pause")
	ui._activate("restart")
	check(ui.screen == "confirm", "restart requires confirmation")
	ui._activate("cancel_confirm")
	check(ui.screen == "pause", "cancel returns to pause")
	ui._enter_rest()
	check(ui.screen == "rest" and ui.game.profile.resume == "rest", "rest marks exact resume phase")
	var saved = Save.load_slot(3, false)
	check(saved.ok and saved.profile.resume == "rest", "rest autosaves active slot")
	ui._activate("shop")
	var visit = ui.shop_visit
	ui.shop_item = "upgrade:escudo_max"
	var before = int(ui.game.profile.credits)
	ui._activate("buy")
	check(int(ui.game.profile.upgrades.escudo_max) == 1 and ui.game.profile.credits < before, "shop mutates shared profile")
	check(ui.game.stats.max_shield > 100, "shop refreshes engine stats")
	ui._activate("refund")
	check(int(ui.game.profile.upgrades.escudo_max) == 0 and int(ui.game.profile.credits) == before, "same visit refund restores credits and rank")
	ui._activate("rest")
	check(visit.closed and not Shop.purchase(profile, "upgrade:escudo_max", visit).ok, "leaving shop invalidates refund visit")
	ui._activate("options")
	var old_volume = ui.options.master
	ui._activate("option:master", -1)
	check(ui.options.master == posmod(old_volume - 1, 11), "volume adjusts down")
	ui._activate("option:master", 1)
	ui._activate("change_difficulty")
	check(ui.game.profile.difficulty == "hard", "difficulty adjustable from rest options")
	ui._activate("controls")
	ui._activate("bind:key:fire")
	ui._input(key(KEY_C))
	check(ui.options.bindings.get("key:fire") == KEY_C, "keyboard remapping persists")
	ui._activate("bind:joy:bomb")
	var joy = InputEventJoypadButton.new()
	joy.button_index = JOY_BUTTON_Y
	joy.pressed = true
	ui._input(joy)
	check(ui.options.bindings.get("joy:bomb") == JOY_BUTTON_Y, "gamepad remapping persists")
	ui._activate("reset_bindings")
	ui._show("rest")
	var colors = ui.game.profile.colors.duplicate(true)
	var stats = ui.game.stats.duplicate(true)
	ui._activate("shipyard")
	ui._activate("color:hull")
	check(ui.game.profile.colors != colors and ui.game.stats == stats, "shipyard changes cosmetics without combat stats")
	ui._show("skins")
	ui._activate("skin:dorado")
	check(ui.game.profile.skin == "original", "locked skins cannot equip")
	ui._enter_rest()
	var loaded = Save.load_slot(3, false)
	ui._start(loaded.profile, true)
	check(ui.screen == "rest" and ui.game.state == "rest", "loading rest save does not start a stage")
	ui.game.killer = "Nereis"
	ui.game.killer_boss = true
	ui.game.death_streak = 5
	ui.game.state = "dead"
	ui._show("dead")
	check(ui.heading == "EL JEFE TE HA DEVORADO", "boss death title")
	check(ui.buttons[0].action == "retry" and ui.selected == 0, "retry selected by default")
	check(ui.buttons[-1].action == "easy_retry", "repeated deaths offer easy difficulty")
	ui.game.state = "results"
	ui.game.result = {"kills": 3, "reward": 200}
	ui._show("results")
	ui._activate("results_skip")
	check(ui.screen == "rest", "results can skip immediately to saved rest")
	ui.sandbox = true
	ui._show("title")
	check(ui.buttons[-1].action == "sandbox", "sandbox exposes explicit selector")
	var sandbox_profile = Shop.create_profile(true)
	ui._start(sandbox_profile)
	ui._activate("sandbox")
	ui.sandbox_world = 14
	ui.sandbox_lab = 3
	ui.sandbox_weapons = {"shot": 8, "missile": 3, "bomb": 2}
	ui._activate("dev_start")
	check(ui.game.profile.world == 14 and ui.game.profile.lab_boss == 3, "selector starts exact laboratory encounter")
	check(ui.game.profile.weapons.shot == 8 and ui.game.profile.weapons.bomb == 2, "selector applies only explicit weapon levels")
	check(ui.game.stats.max_shield == 100 and ui.game.invulnerability == 0, "sandbox does not grant shield or invulnerability")
	for page in ["title", "new", "slots", "options", "controls", "credits", "rest", "shop", "shipyard", "skins", "save", "replay", "sandbox", "dead", "results", "victory"]:
		ui._show(page)
		for button in ui.buttons:
			check(button.rect.position.y >= 0 and button.rect.end.y <= 336 and button.rect.position.x >= 0 and button.rect.end.x <= 640, "button fits viewport: " + page)
		await process_frame
	var audio_refs=ui.audio._streams.values().map(func(value):return weakref(value))
	ui.queue_free()
	await process_frame
	for poll in range(100):
		var alive=false
		for reference in audio_refs:
			if reference.get_ref()!=null:alive=true
		if not alive:break
		await create_timer(0.01).timeout
	print("UI TESTS PASS: %d checks" % checks)
	quit()
