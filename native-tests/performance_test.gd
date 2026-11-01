extends SceneTree
const Main=preload("res://src/core/main.gd")
const Shop=preload("res://src/shop/shop.gd")
func _initialize():call_deferred("run")
func run():
	Engine.max_fps=0
	var ui=Main.new()
	root.add_child(ui)
	await process_frame
	ui.set_process(false)
	var profile=Shop.create_profile()
	profile.weapons={"shot":8,"missile":8,"bomb":8}
	profile.upgrades.dano=5
	profile.upgrades.cadencia=4
	profile.equipment.rov=true
	profile.equipment.multicorer=true
	ui._start(profile)
	ui.intro_clock=0
	ui.game.state="boss"
	ui.game.invulnerability=100000
	for n in range(50):
		var e=ui.game.stage_system.spawn_enemy(ui.game,"hydroides",Vector2(550+n%10*5,80+n%5*20))
		e.hp=1000000
		e.max_hp=1000000
	for n in range(200):
		ui.game.enemy_bullet(Vector2(180+n%20*19,40+n/20*23),Vector2.ZERO)
	var samples=[]
	for frame in range(240):
		var begin=Time.get_ticks_usec()
		ui.clock+=1.0/60.0
		ui.game.step(1.0/60.0,{"fire":true})
		ui.queue_redraw()
		await RenderingServer.frame_post_draw
		if frame>=20:samples.append((Time.get_ticks_usec()-begin)/1000.0)
	samples.sort()
	var sum=0.0
	for value in samples:sum+=value
	var mean=sum/samples.size()
	var report={"renderer":RenderingServer.get_video_adapter_name(),"os":OS.get_name(),"frames":samples.size(),"mean_ms":mean,"p95_ms":samples[int(samples.size()*0.95)],"mean_fps":1000.0/mean,"enemy_count":ui.game.enemies.size(),"bullet_count":ui.game.enemy_bullets.size(),"friendly_count":ui.game.bullets.size(),"player_firing":true,"scope":"Local Linux software OpenGL renderer; Windows hardware may differ."}
	var file=FileAccess.open("/tmp/native-performance.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print("PERFORMANCE ",JSON.stringify(report))
	var audio_refs=ui.audio._streams.values().map(func(value):return weakref(value))
	ui.queue_free()
	await process_frame
	for poll in range(100):
		var alive=false
		for reference in audio_refs:
			if reference.get_ref()!=null:alive=true
		if not alive:break
		await create_timer(0.01).timeout
	quit()
