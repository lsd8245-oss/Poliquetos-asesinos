extends Node2D
const Assets = preload("res://src/core/assets.gd")
var assets
var hitboxes = false
func _ready():
	assets = Assets.new()
	assets.load_all()
	queue_redraw()
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		hitboxes = not hitboxes
		queue_redraw()
func _draw():
	if assets == null:
		return
	assets.sprite(self,"w01_bg_layer1_idle",Rect2(0,0,640,336))
	assets.sprite(self,"w01_ui_ship_original_move",Rect2(80,160,48,24))
	assets.panel(self,Rect2(0,336,640,24))
	assets.text(self,"POLIQUETOS ASESINOS · MOTOR NATIVO",Vector2(32,40))
	assets.text(self,"FASE 1: PNG / ATLAS / FUENTE BITMAP",Vector2(32,58))
	if hitboxes:
		draw_rect(Rect2(99,169,10,6),Color.CYAN,false,1)
