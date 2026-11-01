extends SceneTree
const Main=preload("res://src/core/main.gd")
const Shop=preload("res://src/shop/shop.gd")
func _initialize():call_deferred("run")
func run():
	var ui=Main.new()
	root.add_child(ui)
	await process_frame
	ui.set_process(false)
	ui._start(Shop.create_profile())
	ui.intro_clock=0
	ui.game.finish_encounter()
	ui._process(0.1)
	assert(ui.screen=="results")
	ui._process(4.1)
	assert(ui.screen=="rest")
	ui._activate("shop")
	ui._process(0.1)
	assert(ui.screen=="shop","Results timer must not force rest again")
	ui._activate("rest")
	ui._activate("next")
	ui._process(0.1)
	assert(ui.screen=="game" and int(ui.game.profile.world)==2)
	var completed=Shop.create_profile()
	completed.world=15
	completed.completed=true
	completed.resume="completed"
	ui._start(completed,true)
	assert(ui.screen=="victory" and ui.game.state=="victory","Completed load must not restart escape")
	assert(ui._enemy_draw_parts({"hp":0,"pos":Vector2.ZERO,"size":Vector2.ONE}).is_empty(),"Dead bosses not drawn")
	ui._start(Shop.create_profile())
	ui.intro_clock=0
	ui.game.profile.completed=true
	ui.game.state="victory"
	ui._process(0.01)
	assert(ui.screen=="ending")
	ui._process(float(ui.game.data.combat.ui.ending_seconds)+0.1)
	assert(ui.screen=="credits")
	ui._process(float(ui.game.data.combat.ui.credits_seconds)+0.1)
	assert(ui.screen=="victory")
	var audio_refs=ui.audio._streams.values().map(func(value):return weakref(value))
	ui.queue_free()
	await process_frame
	for poll in range(100):
		var alive=false
		for reference in audio_refs:
			if reference.get_ref()!=null:alive=true
		if not alive:break
		await create_timer(0.01).timeout
	print("FRAME FLOW PASS: results→rest→shop→next remains interactive")
	quit()
