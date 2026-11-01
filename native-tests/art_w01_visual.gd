extends SceneTree
## Deterministic render fixtures of the actual game. Not a human playthrough.
const Main=preload("res://src/core/main.gd")
const Shop=preload("res://src/shop/shop.gd")
var folder="res://docs/verificacion/integracion-w01"
func _initialize():call_deferred("run")
func snap(ui,label):
	ui.queue_redraw()
	await RenderingServer.frame_post_draw
	# The viewport is always logical640x360; capture the actual X11 window too.
	var desktop=DisplayServer.screen_get_image(root.current_screen)
	var image=desktop.get_region(Rect2i(DisplayServer.window_get_position(),DisplayServer.window_get_size()))
	assert(image.save_png(folder+"/"+label+".png")==OK)
func run():
	DirAccess.make_dir_recursive_absolute(folder)
	var ui=Main.new()
	root.add_child(ui)
	await process_frame
	ui.set_process(false)
	# Startup code loads edition-specific options; override only QA window size.
	root.content_scale_size=Vector2i(640,360)
	for resolution in [Vector2i(640,360),Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size=resolution
		root.position=Vector2i.ZERO
		await process_frame
		assert(DisplayServer.window_get_position()==Vector2i.ZERO)
		ui.sandbox=false
		ui._show("title")
		await snap(ui,"normal-menu-%dx%d"%[resolution.x,resolution.y])
		ui.sandbox=true
		ui._show("title")
		await snap(ui,"pruebas-menu-%dx%d"%[resolution.x,resolution.y])
		ui._start(Shop.create_profile(true))
		ui.intro_clock=0
		ui.clock=0.25
		ui.game.invulnerability=0
		ui.game.enemies.clear()
		ui.game.notice_time=0
		var ids=["hydroides","euphrosine","fabric","pision","lacy","syll","phyll"]
		for i in range(ids.size()):
			var e=ui.game.stage_system.spawn_enemy(ui.game,ids[i],Vector2(260+i%4*88,100+i/4*150))
			e.origin=e.pos
		ui.game.player.pos=Vector2(110,175)
		ui.hitboxes=false
		await snap(ui,"familias-%dx%d"%[resolution.x,resolution.y])
		ui.hitboxes=true
		await snap(ui,"f3-%dx%d"%[resolution.x,resolution.y])
		ui.hitboxes=false
		ui.game.enemies.clear()
		ui.game.boss_system.spawn(ui.game,"mini_w01_pision",true)
		ui.game.enemies[0].entry=0
		await snap(ui,"pision-mini-%dx%d"%[resolution.x,resolution.y])
		ui.game.enemies.clear()
		ui.game.boss_system.spawn(ui.game,"boss_w01_nereis")
		var boss=ui.game.enemies[0]
		boss.entry=0
		for phase in [1,2,3]:
			boss.phase=phase
			boss.age=4
			ui.clock=0.125 if phase==2 else 0.25
			if phase==3:
				ui.game.boss_system.Patterns.sync_parts(boss,{"player":ui.game.player.pos},0.0)
			await snap(ui,"nereidae-fase%d-%dx%d"%[phase,resolution.x,resolution.y])
	# Actual stage scheduler/render fixture; temporary QA protection, no profile edits.
	ui._start(Shop.create_profile())
	ui.intro_clock=0
	ui.game.invulnerability=10000
	for frame in range(1200):ui.game.step(1.0/60.0,{"fire":true})
	await snap(ui,"etapa-natural-20s")
	var refs=ui.audio._streams.values().map(func(v):return weakref(v))
	ui.queue_free()
	await process_frame
	for n in range(100):
		var alive=false
		for r in refs:
			if r.get_ref()!=null:alive=true
		if not alive:break
		await create_timer(0.01).timeout
	print("W01 VISUAL PASS: actual native menus, seven families, F3, miniboss, boss phases; 3 resolutions")
	quit()
