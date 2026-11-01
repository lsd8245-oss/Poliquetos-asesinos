extends SceneTree
const Main = preload("res://src/core/main.gd")
func _initialize(): call_deferred("run")
func run():
	var ui=Main.new()
	root.add_child(ui)
	await process_frame
	ui.set_process(false)
	assert(ui.has_method("_background_tiles"), "Native parallax must preserve each PNG width")
	var wide=ui._background_tiles(Vector2(1280,336),640.0,1.0)
	assert(wide[0]==Rect2(-640,0,1280,336))
	assert(wide[1]==Rect2(640,0,1280,336))
	var legacy=ui._background_tiles(Vector2(640,336),700.0,1.0)
	assert(legacy[0]==Rect2(-60,0,640,336))
	assert(legacy[1]==Rect2(580,0,640,336))
	assert(ui.assets.has_sprite("w01_ui_cover_idle"), "Approved cover must be a loaded PNG")
	ui._show("title")
	for b in ui.buttons:
		assert(b.rect.end.x<=360 and b.rect.end.y<320, "Cover must retain readable working menu controls")
	assert(ui.buttons.size()==(6 if ui.sandbox else 5))
	for edition in [false,true]:
		ui.sandbox=edition
		for action in ["new","load","options","credits"]+(["sandbox"] if edition else []):
			ui._show("title")
			var button=ui.buttons.filter(func(b):return b.action==action)[0]
			var click=InputEventMouseButton.new()
			click.button_index=MOUSE_BUTTON_LEFT
			click.pressed=true
			click.position=button.rect.get_center()
			ui._input(click)
			assert(ui.screen=={"new":"new","load":"slots","options":"options","credits":"credits","sandbox":"sandbox"}[action],"Illustrated menu click must activate "+action)
		ui._show("title")
		var down=InputEventKey.new()
		down.keycode=KEY_DOWN
		down.pressed=true
		ui._input(down)
		assert(ui.selected==1)
		var accept=InputEventKey.new()
		accept.keycode=KEY_ENTER
		accept.pressed=true
		ui._input(accept)
		assert(ui.screen=="slots","Illustrated menu keyboard must open Continue")
	var key="w01_boss_boss_w01_nereis_move"
	var e={"hp":1,"id":"boss_w01_nereis","pos":Vector2(500,168),"size":Vector2(180,120),"phase":1}
	assert(ui.has_method("_enemy_visual_layers"), "Nereidae must use independently replaceable PNG pieces")
	var layers=ui._enemy_visual_layers(e,key)
	assert(layers.size()==3,"Head, body and jaws must be separate")
	var settings=ui.game.boss_system.Patterns.balance("nereis",ui.game.data.bosses[0])
	var piece_size=Vector2(180,120)*Vector2(settings.split_size_x,settings.split_size_y)
	e.parts=[{"pos":Vector2(400,80),"size":piece_size},{"pos":Vector2(480,220),"size":piece_size}]
	e.phase=3
	layers=ui._enemy_visual_layers(e,key)
	assert(layers.size()==2 and layers[0].key!=layers[1].key,"Split phase must draw front and tail, not two complete heads")
	assert(layers[0].rect==Rect2(Vector2(400,80)-piece_size/2,piece_size))
	assert(layers[1].rect==Rect2(Vector2(480,220)-piece_size/2,piece_size))
	assert(ui._enemy_visual_layers({"hp":0,"pos":Vector2.ZERO,"size":Vector2.ONE},key).is_empty())
	var refs=ui.audio._streams.values().map(func(v):return weakref(v))
	ui.queue_free()
	await process_frame
	for n in range(100):
		var alive=false
		for r in refs:
			if r.get_ref()!=null:alive=true
		if not alive:break
		await create_timer(0.01).timeout
	print("ART W01 PASS: native tile widths, cover controls, articulated and split Nereidae")
	quit()
