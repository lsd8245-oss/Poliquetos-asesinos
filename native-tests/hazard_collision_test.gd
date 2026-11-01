extends SceneTree
const Game=preload("res://src/core/game.gd")
const Shop=preload("res://src/shop/shop.gd")
func _initialize():
	var g=Game.new()
	var p=Shop.create_profile()
	p.world=8
	g.start(p)
	g.stage_system.spawn_hazard(g,{"id":"barriles","y":140})
	var h=g.hazards[-1]
	h.rect=Rect2(100,140,48,56)
	g.player.pos=h.rect.get_center()
	var enemy=g.stage_system.spawn_enemy(g,"syll",Vector2(145,168))
	g.friendly_bullet(h.rect.get_center(),Vector2.ZERO,10)
	g.step_projectiles(0.01)
	assert(h.duration==0,"Barrel detonates when shot")
	assert(enemy.hp<=0,"Barrel area damages enemy")
	assert(g.player.shield==80,"Barrel area damages player")
	g.hazards.clear()
	g.invulnerability=0
	g.stage_system.spawn_hazard(g,{"id":"laseres","y":100,"duracion_seg":12})
	h=g.hazards[-1]
	h.rect=Rect2(100,100,100,24)
	g.player.pos=h.rect.get_center()
	g.step_hazards(0.2)
	assert(g.player.shield==80,"Laser warns before damage")
	g.step_hazards(0.4)
	assert(g.player.shield==60)
	g.invulnerability=0
	g.step_hazards(1.0)
	assert(g.player.shield==60,"Inactive pulse gap")
	g.step_hazards(1.5)
	assert(g.player.shield==60,"Cycle3 warning repeats")
	g.step_hazards(0.5)
	assert(g.player.shield==40,"Cycle3 damage repeats")
	print("HAZARD COLLISION PASS: destructible barrel area and laser3sec warning/active cycles")
	quit()
