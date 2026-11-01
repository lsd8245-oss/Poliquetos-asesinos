extends SceneTree
const Main=preload("res://src/core/main.gd")
const Shop=preload("res://src/shop/shop.gd")
func _initialize():call_deferred("run")
func snap(ui,name):
	ui.queue_redraw()
	await RenderingServer.frame_post_draw
	var im=root.get_texture().get_image()
	var err=im.save_png("/tmp/poli-"+name+".png")
	assert(err==OK)
func run():
	var ui=Main.new()
	root.add_child(ui)
	await process_frame
	ui.set_process(false)
	ui._show("title")
	await snap(ui,"title")
	ui._start(Shop.create_profile())
	ui.intro_clock=0
	ui.game.invulnerability=10000
	for n in range(900):ui.game.step(1.0/60.0,{"fire":true})
	await snap(ui,"game")
	ui._enter_rest()
	ui._activate("shop")
	await snap(ui,"shop")
	var p=Shop.create_profile()
	p.world=8
	ui._start(p)
	ui.intro_clock=0
	ui.game.state="alert"
	ui.game.phase_clock=6.0
	ui.game.step(0.1,{})
	await snap(ui,"bosses")
	var audio_refs=ui.audio._streams.values().map(func(value):return weakref(value))
	ui.queue_free()
	await process_frame
	for poll in range(100):
		var alive=false
		for reference in audio_refs:
			if reference.get_ref()!=null:alive=true
		if not alive:break
		await create_timer(0.01).timeout
	print("VISUAL PASS: title,game,shop,bosses PNG captured")
	quit()
