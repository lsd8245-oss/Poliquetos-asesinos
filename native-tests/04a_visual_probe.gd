extends SceneTree
## Full desktop captures of explicitly labelled synthetic presentation states.
const Main=preload("res://src/core/main.gd")
const Shop=preload("res://src/shop/shop.gd")
const Policy=preload("res://src/visuals/display_policy.gd")
var folder="res://docs/verificacion/04a/matriz-x11"
var records=[]
class Captions extends Node2D:
	var assets
	func _draw():
		for y in [56,206]:
			for pair in [[90,"NORMAL"],[215,"BOTIN GRUPO"],[350,"CARGA"],[480,"CTD VULNERABLE"]]:
				assets.text(self,pair[1],Vector2(pair[0]-16,y),Color.WHITE)
func _initialize():call_deferred("run")
func snap(ui,label):
	ui.queue_redraw()
	await create_timer(.2).timeout
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(folder+"/viewport-640")
	assert(root.get_texture().get_image().save_png(folder+"/viewport-640/"+label+".png")==OK)
	var im=DisplayServer.screen_get_image(root.current_screen)
	assert(im.save_png(folder+"/"+label+".png")==OK)
	var metric=Policy.metrics(root,str(ui.options.screen));metric["fixture"]=true;metric["capture"]=label
	if str(ui.options.screen).begins_with("fullscreen_"):
		assert(root.mode==Window.MODE_EXCLUSIVE_FULLSCREEN,"actual mode 4")
		assert(root.size==DisplayServer.screen_get_size(root.current_screen),"actual fullscreen dimensions")
		assert(root.position==DisplayServer.screen_get_position(root.current_screen),"actual fullscreen origin")
	assert(root.get_visible_rect().size==Vector2(640,360),"fixed full viewport/HUD")
	records.append(metric)
func run():
	var size=DisplayServer.screen_get_size(0)
	if OS.get_cmdline_user_args().has("--pruebas"):folder+="/edicion-pruebas"
	folder+="/%dx%d"%[size.x,size.y]
	DirAccess.make_dir_recursive_absolute(folder)
	var ui=Main.new();root.add_child(ui);await process_frame;ui.set_process(false)
	var p=Shop.create_profile(ui.sandbox);p.equipment.ctd=true
	ui._start(p);ui.intro_clock=0;ui.hitboxes=false;ui.clock=2.2;ui.game.total_time=2.2
	ui.game.player.pos=Vector2(320,175)
	for row in range(2):
		for column in range(4):
			var pos=Vector2(100+column*135,102+row*148)
			var e=ui.game.stage_system.spawn_enemy(ui.game,"euphrosine",pos)
			e.age=2.2
			if column==1:e.carrier="rojo"
			if column==2:e["_charge"]={"wait":0.8}
			if column==3:e.flags={"weak_exposed":true,"weak_points":[pos+Vector2(-10,0)]}
	ui.game.notice="FIXTURE 04A / ESTADOS VISUALES, NO PARTIDA"
	ui.game.notice_time=10000
	var text=Captions.new();text.assets=ui.assets;root.add_child(text)
	for mode in ["window1","fullscreen_fill","fullscreen_pixel"]:
		ui.options.screen=mode;ui._apply_options()
		for frame in range(4):await process_frame
		await snap(ui,"auras-"+mode)
	ui.options.screen="fullscreen_fill";ui._apply_options()
	for frame in range(4):await process_frame
	ui.game.profile.equipment.ctd=false
	ui.sonar.activate(ui.game.profile,ui.game.player.pos);ui.sonar.advance(0.4)
	await snap(ui,"sonar-sin-ctd")
	ui.sonar.advance(3.6)
	await snap(ui,"sonar-recarga-08")
	ui.options.screen="window2";ui._apply_options()
	for frame in range(4):await process_frame
	await snap(ui,"restaurar-ventana")
	text.visible=false
	ui.game.enemies.clear();ui.sonar.reset()
	ui.game.boss_system.spawn(ui.game,"boss_w01_nereis")
	var boss=ui.game.enemies[0];boss.entry=0;boss.age=4;boss.pos=Vector2(450,160)
	ui.game.boss_system.Patterns.sync_parts(boss,{"player":ui.game.player.pos},0.0)
	ui.game.notice="FIXTURE 04A / NEREIDAE: BARRA Y HUD COMPLETOS"
	for mode in ["fullscreen_fill","fullscreen_pixel"]:
		ui.options.screen=mode;ui._apply_options()
		for frame in range(4):await process_frame
		await snap(ui,"jefe-"+mode)
	var f=FileAccess.open(folder+"/metrics.json",FileAccess.WRITE);f.store_string(JSON.stringify(records,"\t"));f.close()
	var refs=ui.audio._streams.values().map(func(v):return weakref(v))
	text.queue_free();ui.queue_free();await process_frame
	for poll in range(100):
		if refs.all(func(r):return r.get_ref()==null):break
		await create_timer(.01).timeout
	print("04A VISUAL PROBE PASS ",size," full desktop captures, labels, modes, sonar without CTD")
	quit()
