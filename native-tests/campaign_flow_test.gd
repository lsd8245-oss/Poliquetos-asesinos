extends SceneTree
const Game=preload("res://src/core/game.gd")
const Shop=preload("res://src/shop/shop.gd")
const Save=preload("res://src/save/saves.gd")
func _initialize():
	var g=Game.new()
	g.start(Shop.create_profile())
	var visits=0
	var lab_stages=0
	var all_spawned=0
	for frame in range(20000):
		g.invulnerability=10000
		g.step(0.5,{})
		for e in g.enemies:
			if e.hp>0:g.hit_enemy(e,10000000,e.pos)
		for d in g.drops:g.collect_drop(d)
		g.drops.clear()
		if g.state=="results":
			visits+=1
			if int(g.profile.world)==14 and int(g.profile.lab_boss)==1:lab_stages+=1
			if int(g.profile.world)<14 or int(g.profile.lab_boss)==1:
				assert(g.regular_spawned==int(g.world.enemigos_total),"Exact stage count")
				all_spawned+=g.regular_spawned
			g.state="rest"
			g.profile.resume="rest"
			var saved=Save.save_slot(1,g.profile)
			assert(saved.ok,str(saved))
			var restored=Save.load_slot(1,false)
			assert(restored.ok and restored.profile==g.profile,"Exact rest roundtrip")
			g.continue_campaign()
		if g.state=="victory":break
	assert(g.state=="victory","Full campaign reaches ending")
	assert(visits==17,"17 shop visits")
	assert(lab_stages==1,"One lab stage")
	assert(all_spawned==2424,"14 worlds exact enemy budget")
	assert(g.regular_spawned==90,"Escape exact90")
	assert(g.profile.completed)
	assert(g.profile.skins.has("dorado"))
	assert(g.profile.cleared.size()==14)
	assert(g.profile.escape_score==1000)
	assert(g.world_time>=300 and g.world_time<301)
	print("CAMPAIGN FLOW PASS: 14worlds/2424 enemies,17 rests,4lab encounters,300s escape/90 enemies,ending/save roundtrip")
	quit()
