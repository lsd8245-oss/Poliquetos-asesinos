extends SceneTree
const Game=preload("res://src/core/game.gd")
const Shop=preload("res://src/shop/shop.gd")
const Save=preload("res://src/save/saves.gd")
func _initialize():
	var g=Game.new()
	var p=Shop.create_profile()
	p.world=3
	p.cleared=[1,2,3]
	g.start(p)
	g.begin_replay(1)
	g.add_coins(10000)
	g.finish_encounter()
	assert(g.profile.credits==150,"Replay total capped at half base")
	g.profile.resume="rest"
	assert(Save.save_slot(2,g.profile).ok)
	var loaded=Save.load_slot(2,false)
	var restored=Game.new()
	restored.start(loaded.profile)
	restored.continue_campaign()
	assert(restored.profile.world==3,"Replay survives save/reload without changing progression")
	assert(restored.world.id==3)
	assert(restored.profile.credits==150)
	p=Shop.create_profile()
	p.equipment.lander=true
	g.start(p)
	g.damage_player(1000,"test")
	assert(g.player.shield==50 and g.profile.deaths.is_empty())
	g.invulnerability=0
	g.damage_player(1000,"test")
	g.retry()
	g.invulnerability=0
	g.damage_player(1000,"test")
	assert(g.state=="dying","Lander only once per world across retries")
	p=Shop.create_profile()
	p.world=14
	p.lab_boss=2
	g.start(p)
	assert(not g.stage_system.enemy_index.is_empty(),"Loaded lab room initializes spawn catalog")
	p=Shop.create_profile()
	g.start(p)
	g.spawn_drop("rojo",g.player.pos,"retry-carrier")
	g.collect_drop(g.drops[0])
	assert(p.weapons.shot==2)
	g.retry()
	g.spawn_drop("rojo",g.player.pos,"retry-carrier")
	assert(g.drops.size()==1,"Weapon carrier respawns after entry-level reset")
	g.collect_drop(g.drops[0])
	assert(p.weapons.shot==2)
	print("INTEGRATION REGRESSIONS PASS: replay cap/progress/reload, one Lander per world, lab reload")
	quit()
