extends SceneTree
const Main=preload("res://src/core/main.gd")
var failures=[]
func check(ok:bool,label:String):
	if not ok:failures.append(label)
func _initialize():call_deferred("run")
func run():
	var ui=Main.new();root.add_child(ui);await process_frame;ui.set_process(false);ui.sandbox=true
	ui.sandbox_world=13;ui._show("sandbox")
	check(ui.buttons[0].label.contains("Escape") and not ui.buttons[0].label.contains("Mundo: 13"),"escape is special, not a thirteenth main world")
	check(ui.buttons[1].label.contains("de 3"),"three actual laboratory encounters")
	ui._activate("dev_world")
	check(ui.sandbox_world==1,"selector wraps after twelve worlds and special escape")
	ui.sandbox_world=12;ui.sandbox_lab=2;ui._activate("dev_lab")
	check(ui.sandbox_lab==0,"laboratory selector wraps after Eunice")
	for world_id in range(1,14):
		ui.sandbox_world=world_id;ui.sandbox_lab=0;ui._activate("dev_start")
		check(int(ui.game.profile.world)==world_id and int(ui.game.world.id)==world_id,"selected world actually starts: %d"%world_id)
		check(ui.game.profile.credits==999999999 and ui.game.player.shield==100,"Pruebas starts without stat boosts")
		check(ui.game.profile.equipment=={"sonar":true},"Pruebas purchases remain pending")
	# A loaded, already-cleared rest profile is a transition fixture, not a playthrough.
	var completed_profile=ui.game.Shop.create_profile()
	completed_profile.cleared=[1];completed_profile.rewarded={"1:0":true};completed_profile.resume="rest"
	ui.sandbox=false;ui._start(completed_profile,true)
	ui._activate("next")
	check(int(ui.game.profile.world)==2 and ui.screen=="game","real Next button must preserve rest until Game validates progression")
	var refs=ui.audio._streams.values().map(func(v):return weakref(v))
	ui.queue_free();await process_frame
	for poll in range(100):
		if refs.all(func(r):return r.get_ref()==null):break
		await create_timer(.01).timeout
	if failures.is_empty():print("CAMPAIGN12 UI PASS: real 1-12+escape selector, three lab encounters, no free purchases");quit()
	else:printerr("CAMPAIGN12 UI FAIL: ",failures);quit(1)
