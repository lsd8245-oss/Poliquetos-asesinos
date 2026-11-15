extends SceneTree
const Game=preload("res://src/core/game.gd")
const Shop=preload("res://src/shop/shop.gd")
func _initialize():
	var p=Shop.create_profile();p.equipment.rov=false
	var g=Game.new();g.start(p)
	var before=p.duplicate(true)
	g.player.missile_clock=1000;g.player.rov_clock=0
	g.weapon_system.step(g,0,{})
	if g.equipment("rov") or not g.bullets.is_empty():
		printerr("CAMPAIGN12 EQUIPMENT FAIL: valid unbought rov:false must not equip or fire");quit(1);return
	assert(g.equipment("sonar") and not g.equipment("deflector"),"true initial sonar, absent gear inactive")
	assert(p==before,"checking gear and pending ROV never changes profile")
	p.equipment.rov=true
	g.weapon_system.step(g,0,{})
	assert(g.equipment("rov") and g.bullets.size()==1,"installed ROV still fires production projectile")
	print("CAMPAIGN12 EQUIPMENT PASS: false/missing gear inactive, bought true gear fires normally");quit()
