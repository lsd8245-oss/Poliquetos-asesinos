extends SceneTree
const Main=preload("res://src/core/main.gd")
func _initialize():call_deferred("run")
func run():
	var ui=Main.new()
	root.add_child(ui)
	await process_frame
	ui.set_process(false)
	ui._show("title")
	var button=ui.buttons.filter(func(b):return b.action=="quit")[0]
	var click=InputEventMouseButton.new()
	click.button_index=MOUSE_BUTTON_LEFT
	click.pressed=true
	click.position=button.rect.get_center()
	ui._input(click)
	assert(ui.screen=="confirm" and ui.confirm_action=="Salir del juego")
	var confirm=ui.buttons.filter(func(b):return b.action=="accept_confirm")[0]
	click.position=confirm.rect.get_center()
	ui._input(click)
	assert(not ui.is_processing_input(),"Ignore repeated confirmations during shutdown")
	print("W01 QUIT PASS: title Salir mouse event, edition=", "pruebas" if ui.sandbox else "normal")
	# Deliberately no quit() here: the real menu action must terminate the process.
