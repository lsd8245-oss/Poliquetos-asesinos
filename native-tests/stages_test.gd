extends SceneTree
const Game=preload("res://src/core/game.gd")
const Shop=preload("res://src/shop/shop.gd")
func _initialize():
	var g=Game.new()
	g.start(Shop.create_profile())
	g.invulnerability=100000
	for tick in range(1200):
		if g.world_time>=169.9:break
		g.step(0.25,{})
		for e in g.enemies:
			if e.get("mini",false) and e.hp>0:g.hit_enemy(e,1000000,e.pos)
	print("stage1 time/state/budget ",g.world_time," ",g.state," ",g.regular_spawned)
	assert(g.regular_spawned==90,"World1 exact regular budget")
	assert(g.mini_defeated)
	assert(g.checkpoint.mini_defeated)
	assert(g.state=="alert")
	assert(absf(g.world_time-170)<0.5)
	var frozen=g.world_time
	g.pause()
	g.step(1,{})
	assert(g.world_time==frozen)
	g.start(Shop.create_profile())
	g.invulnerability=100000
	for tick in range(1200):
		if g.world_time>=125:break
		g.step(0.25,{})
	print("stage2 time/state/budget ",g.world_time," ",g.state," ",g.regular_spawned)
	assert(not g.mini_defeated)
	assert(g.regular_spawned>36,"Intense waves resume despite living mini")
	assert(g.state=="playing")
	print("STAGES TESTS PASS: exact90, timeline, mini checkpoint, pause, overlap")
	quit()
