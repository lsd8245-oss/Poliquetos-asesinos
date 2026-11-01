extends SceneTree
func _initialize():
	var script=load("res://src/visuals/combat_presentation.gd")
	if script==null:
		print("FAIL B1 presentation resource missing")
		quit(1)
		return
	var source={"pos":Vector2(50,70),"velocity":Vector2(0,200),"size":Vector2(8,8),"damage":11,"ttl":2.0}
	var before=source.duplicate(true)
	var visual=script.bullet_visual(source,"homing")
	assert(is_equal_approx(visual.angle,PI/2))
	assert(visual.size.x>=source.size.x and visual.size.y>=source.size.y)
	assert(visual.size.x<=source.size.x+6 and visual.size.y<=source.size.y+6)
	assert(source==before,"Render must never alter projectile collision or damage")
	assert(script.effect_time(0.5,0.5,8,16)==0.0)
	assert(script.effect_time(0.0,0.5,8,16)>0.4)
	assert(int(floor(script.effect_time(0.001,0.5,8,16)*16))==7,"Last fade frame must be visible before TTL expiration")
	print("B1 PRESENTATION PASS: direction, visual halo, immutable projectile, effect lifetime")
	quit()
