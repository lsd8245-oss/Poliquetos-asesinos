extends SceneTree
const Main=preload("res://src/core/main.gd")
const Shop=preload("res://src/shop/shop.gd")
func _initialize():call_deferred("run")
func run():
	var ui=Main.new();root.add_child(ui);await process_frame;ui.set_process(false)
	if not ui.has_method("_campaign_trace_payload"):
		printerr("CAMPAIGN12 TRACE FAIL: missing read-only runtime payload");quit(1);return
	ui._start(Shop.create_profile());ui.intro_clock=0
	var before=ui.game.profile.duplicate(true);var before_time=ui.game.total_time;var before_hp=ui.game.player.shield
	var payload=ui._campaign_trace_payload()
	assert(payload.world==1 and payload.screen=="game" and payload.minis==0,"trace identifies actual campaign without fake victories")
	assert(payload.boss_spawns==0 and payload.state=="playing" and payload.shield==100,"trace starts with real stats")
	assert(ui.game.profile==before and ui.game.total_time==before_time and ui.game.player.shield==before_hp,"trace never advances or mutates gameplay")
	assert(payload.buttons==[],"no debug controls injected into play")
	var refs=ui.audio._streams.values().map(func(v):return weakref(v))
	ui.queue_free();await process_frame
	for poll in range(100):
		if refs.all(func(r):return r.get_ref()==null):break
		await create_timer(.01).timeout
	print("CAMPAIGN12 TRACE PASS: opt-in read-only observation, no injected game state or controls");quit()
