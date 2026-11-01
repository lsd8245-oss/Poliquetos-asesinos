extends SceneTree
## Labelled deterministic fixtures; NOT normal progression or human play.
const Main=preload("res://src/core/main.gd")
const Shop=preload("res://src/shop/shop.gd")
var folder="res://docs/verificacion/pulido-w01/fixtures"
func _initialize():call_deferred("run")
func snap(ui,name):
	ui.game.notice="FIXTURE B1 / NO PARTIDA HUMANA"
	ui.game.notice_time=1000
	ui.queue_redraw()
	await RenderingServer.frame_post_draw
	var desktop=DisplayServer.screen_get_image(root.current_screen)
	var image=desktop.get_region(Rect2i(DisplayServer.window_get_position(),DisplayServer.window_get_size()))
	assert(image.save_png(folder+"/"+name+".png")==OK)
func run():
	DirAccess.make_dir_recursive_absolute(folder)
	var ui=Main.new();root.add_child(ui)
	await process_frame
	ui.set_process(false)
	for resolution in [Vector2i(640,360),Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size=resolution;root.position=Vector2i.ZERO
		await process_frame
		var suffix="-%dx%d"%[resolution.x,resolution.y]
		for sector in range(3):
			ui._start(Shop.create_profile())
			ui.intro_clock=0;ui.clock=15*sector+0.25
			ui.game.scroll=900*sector
			ui.game.world_time=15*sector
			ui.game.player.pos=Vector2(100,160)
			for i in range(7):
				var id=["hydroides","euphrosine","fabric","pision","lacy","syll","phyll"][i]
				var enemy=ui.game.stage_system.spawn_enemy(ui.game,id,Vector2(230+i%4*100,95+i/4*110))
				enemy.age=i*0.3
			for i in range(3):
				ui.game.friendly_bullet(Vector2(145+i*50,160),Vector2.RIGHT*200,1,0,{"missile":i==1,"beam":i==2})
				ui.game.enemy_bullet(Vector2(330+i*60,185),Vector2.LEFT*100,{"homing":i==1,"bounce":1 if i==2 else 0})
			await snap(ui,"sector%d"%(sector+1)+suffix)
		ui.game.weapon_system.bomb(ui.game)
		for effect in ui.game.effects:
			effect.age=0.2;effect.ttl=0.3
		await snap(ui,"bomba"+suffix)
		ui.game.enemies.clear();ui.game.effects.clear();ui.game.bullets.clear();ui.game.enemy_bullets.clear()
		ui.game.boss_system.spawn(ui.game,"mini_w01_pision",true)
		ui.game.enemies[0].entry=0
		await snap(ui,"minijefe"+suffix)
		ui.game.enemies.clear()
		ui.game.boss_system.spawn(ui.game,"boss_w01_nereis")
		var boss=ui.game.enemies[0];boss.entry=0;boss.age=4;boss.pos=Vector2(440,156)
		ui.game.boss_system.Patterns.sync_parts(boss,{"player":ui.game.player.pos},0.0)
		ui.game.state="boss"
		await snap(ui,"jefe"+suffix)
		ui.options.reduce_flashes=true
		ui.game.damage_player(10,"fixture")
		ui.presentation.muzzle=0.04;ui.presentation.collection=0.15
		await snap(ui,"destellos-reducidos"+suffix)
		ui.options.reduce_flashes=false
	var refs=ui.audio._streams.values().map(func(value):return weakref(value))
	ui.queue_free();await process_frame
	for poll in range(100):
		if refs.all(func(r):return r.get_ref()==null):break
		await create_timer(.01).timeout
	print("B1 VISUAL PASS: labelled fixtures x1/x2/x3, sectors, projectiles, bomb, mini, boss, reduce flashes")
	quit()
