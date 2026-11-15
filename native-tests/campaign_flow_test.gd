extends SceneTree
const Game=preload("res://src/core/game.gd")
const Shop=preload("res://src/shop/shop.gd")
const Save=preload("res://src/save/saves.gd")
const Combat=preload("res://native-tests/fixtures/campaign_combat.gd")
var max_clock_roundtrip_error=0.0
func same_rest(a:Dictionary,b:Dictionary)->bool:
	# Godot's decimal parser can round a correctly printed double by one ULP.
	# Only clocks allow a sub-nanosecond error; every other saved field is exact.
	var expected=a.duplicate(true)
	for key in ["time","world_elapsed"]:
		if a.has(key) and b.has(key):
			if typeof(a[key])!=typeof(b[key]):return false
			var error=absf(float(a[key])-float(b[key]))
			max_clock_roundtrip_error=maxf(max_clock_roundtrip_error,error)
			if error>1e-9:return false
			expected[key]=b[key]
	return expected==b
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
			if e.hp>0 and not e.get("boss",false):g.hit_enemy(e,10000000,e.pos)
		assert(g.mini_spawn_count==0 and not g.mini_defeated,"No disabled mini victory")
		if g.state=="boss":assert(Combat.defeat(g),"Final must be defeated with actual projectiles, never cleared by timer")
		for d in g.drops:g.collect_drop(d)
		g.drops.clear()
		if g.state=="results":
			visits+=1
			if int(g.profile.world)==12 and int(g.profile.lab_boss)==1:lab_stages+=1
			if int(g.profile.world)<12 or int(g.profile.lab_boss)==1:
				assert(g.regular_spawned==int(g.world.enemigos_total),"Exact stage count")
				all_spawned+=g.regular_spawned
			g.state="rest"
			g.profile.resume="rest"
			var saved=Save.save_slot(1,g.profile)
			assert(saved.ok,str(saved))
			var restored=Save.load_slot(1,false)
			assert(restored.ok and same_rest(g.profile,restored.profile),"All rest fields exact; clock rounding <=1ns")
			g.continue_campaign()
		if g.state=="victory":break
	assert(g.state=="victory","Full campaign reaches ending")
	assert(visits==14,"14 shop visits")
	assert(lab_stages==1,"One lab stage")
	assert(all_spawned==2139,"12 worlds exact enemy budget")
	assert(g.regular_spawned==90,"Escape exact90")
	assert(g.profile.completed)
	assert(g.profile.skins.has("dorado"))
	assert(g.profile.cleared.size()==12)
	assert(g.profile.escape_score==1000)
	assert(g.world_time>=300 and g.world_time<301)
	print("CLOCK ROUNDTRIP MAX DELTA: ",max_clock_roundtrip_error," seconds")
	print("CAMPAIGN FLOW PASS (synthetic regular clears/aim/survival; production boss projectile victories): 12worlds/2139 enemies,14 rests,3lab encounters,300s escape/90 enemies,ending/save roundtrip")
	quit()
