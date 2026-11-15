extends SceneTree
## Synthetic UI/resource fixtures, separate from the no-cheat Windows recordings.
const Main=preload("res://src/core/main.gd")
const Shop=preload("res://src/shop/shop.gd")
const Save=preload("res://src/save/saves.gd")
const Policy=preload("res://src/visuals/display_policy.gd")
var folder="/workspace/05a-qa/visual-fixtures"
var records=[]
func _initialize():call_deferred("run")
func snap(ui,label):
	ui.queue_redraw()
	await create_timer(.15).timeout
	await RenderingServer.frame_post_draw
	var path=folder+"/"+label+".png"
	assert(root.get_texture().get_image().save_png(path)==OK)
	assert(DisplayServer.screen_get_image(0).save_png(folder+"/desktop-"+label+".png")==OK)
	var metrics=Policy.metrics(root,str(ui.options.screen))
	metrics.fixture=true;metrics.capture=label;records.append(metrics)
func run():
	var ui=Main.new();root.add_child(ui);await process_frame;ui.set_process(false)
	folder+="/pruebas" if ui.sandbox else "/normal"
	DirAccess.make_dir_recursive_absolute(folder)
	for mode in ["window1","window2","fullscreen_fill"]:
		ui.options.screen=mode;ui._apply_options()
		for i in range(4):await process_frame
		ui._show("title");await snap(ui,mode+"-title")
		ui._show("sandbox");ui.sandbox_world=12;ui.sandbox_lab=2;ui._show("sandbox")
		await snap(ui,mode+"-laboratory-selector")
		ui.sandbox_world=13;ui._show("sandbox");await snap(ui,mode+"-escape-selector")
		for old_world in [3,6]:
			var old=Shop.create_profile(ui.sandbox);old.version=2;old.world=old_world
			var preview=Save.preview_import(1,Save._encode(old),ui.sandbox)
			assert(preview.ok and preview.migrated)
			ui.pending_migration_notice=preview.migration_notice;ui._show("migration")
			await snap(ui,mode+"-migration-"+str(old_world))
		var p=Shop.create_profile(ui.sandbox);p.world=3
		ui._start(p);ui.intro_clock=0;ui.game.notice="FIXTURE 05A / KELP ANTIGUO 4 A NUEVO 3";ui.game.notice_time=999
		await snap(ui,mode+"-kelp-alias")
	var f=FileAccess.open(folder+"/metrics.json",FileAccess.WRITE);f.store_string(JSON.stringify(records,"\t"));f.close()
	var refs=ui.audio._streams.values().map(func(v):return weakref(v))
	ui.queue_free();await process_frame
	for poll in range(100):
		if refs.all(func(r):return r.get_ref()==null):break
		await create_timer(.01).timeout
	print("CAMPAIGN12 VISUAL PROBE PASS: labelled fixture matrix, migration warnings, selectors and kelp resources")
	quit()
