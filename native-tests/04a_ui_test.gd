extends SceneTree
const Main=preload("res://src/core/main.gd")
const Shop=preload("res://src/shop/shop.gd")
const Save=preload("res://src/save/saves.gd")
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
	if not ok:printerr("04A UI FAIL: ",label);quit(1)
	return ok
func key(code):
	var e=InputEventKey.new();e.pressed=true;e.keycode=code;e.physical_keycode=code
	return e
func run():
	var before=Save.load_options(false).options.duplicate(true)
	var ui=Main.new();root.add_child(ui);await process_frame;ui.set_process(false)
	ui._show("controls")
	var controls=ui.buttons.filter(func(b):return b.action.begins_with("bind:"))
	if not check(controls.size()==16,"eight key/joy actions"):return
	for b in controls:
		if not check(b.rect.end.y<=280,"Sonar row visible above footer"):return
	ui._activate("bind:key:sonar");ui._input(key(KEY_E))
	if not check(ui.options.bindings.get("key:sonar")==KEY_E and ui._sonar_key_name()=="E","rebind persisted HUD"):return
	if not check(Save.load_options(false).options.bindings.get("key:sonar")==KEY_E,"preference saved"):return
	ui._start(Shop.create_profile());ui.intro_clock=0
	ui._input(key(KEY_Q))
	if not check(not ui.pending_sonar,"old Q inactive after E remap"):return
	ui._input(key(KEY_E));ui._process(1.0/60.0)
	if not check(ui.sonar.cooldown==12 and ui.sonar.remaining==4 and ui.game.player.shield==100 and ui.game.profile.credits==0,"real event activates informational sonar"):return
	ui._input(key(KEY_ESCAPE));ui._process(2)
	if not check(ui.sonar.cooldown==12,"pause freezes sonar"):return
	ui._activate("resume");ui._process(0.2)
	if not check(ui.sonar.cooldown==12,"resume countdown freezes sonar"):return
	ui.options.bindings.erase("joy:sonar");ui.sonar.reset();ui.game.state="playing";ui._show("game")
	var joy=InputEventJoypadButton.new();joy.pressed=true;joy.button_index=JOY_BUTTON_Y
	ui._input(joy);ui._process(1.0/60.0)
	if not check(ui.sonar.remaining==4,"default Y event"):return
	ui._activate("retry")
	if not check(ui.sonar.cooldown==0 and ui.sonar.remaining==0,"retry clears only runtime sonar"):return
	ui.options.screen="window3";ui._show("options")
	ui._activate("option:screen")
	if not check(ui.options.screen=="fullscreen_fill","fill accessible"):return
	ui._activate("option:screen")
	if not check(ui.options.screen=="fullscreen_pixel","pixel accessible"):return
	ui._activate("option:screen")
	if not check(ui.options.screen=="window1","return window"):return
	Save.save_options(before,false)
	var refs=ui.audio._streams.values().map(func(v):return weakref(v))
	ui.queue_free();await process_frame
	for poll in range(100):
		if refs.all(func(r):return r.get_ref()==null):break
		await create_timer(.01).timeout
	print("04A UI PASS: layout, configurable Q/E/Y input, saved binding, no damage, freeze, fill/pixel/window")
	quit()
