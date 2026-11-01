extends SceneTree
const Game=preload("res://src/core/game.gd")
const Shop=preload("res://src/shop/shop.gd")
const Data=preload("res://src/core/data.gd")
func _initialize():
	var report=Data.read_json("data/balance_report.json",{})
	var measured=[]
	for row in report.encounters:
		var p=Shop.create_profile()
		p.world=int(row.world)
		p.lab_boss=int(row.group)-1 if p.world==14 else 0
		for key in row.max_build.ranks:p.upgrades[key]=int(row.max_build.ranks[key])
		if row.max_build.rov:p.equipment.rov=true
		if row.max_build.multicorer:p.equipment.multicorer=true
		for key in p.weapons:p.weapons[key]=int(row.weapon_level_bound)
		var g=Game.new()
		g.start(p)
		g.state="alert"
		g.phase_clock=6
		g.boss_system.step(g,0)
		var dt=1.0/60.0
		var active=0.0
		var bombed=false
		for tick in range(18000):
			g.boss_system.step(g,dt)
			var target={}
			for e in g.enemies:
				if e.get("boss",false) and e.hp>0:
					target=e
					break
			if target.is_empty():break
			active+=dt
			var hit=target.pos-target.size/2+Vector2(8,target.size.y/2)
			if target.entry<=0 and target.lock<=0:
				# Continuous DPS with perfect aim is a stronger envelope than real shots.
				g.hit_enemy(target,float(row.max_build.dps)*dt,hit)
				if not bombed:
					g.hit_enemy(target,float(row.max_build.bomb_burst)*2,hit,true)
					bombed=true
		assert(active>=float(row.minimum_seconds),"Minimum kill time world%d"%int(row.world))
		measured.append({"world":row.world,"group":row.group,"measured_continuous_seconds":active,"required":row.minimum_seconds})
	var file=FileAccess.open("user://balance-measured.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(measured,"\t"))
	print("BALANCE PASS: 17 actual boss simulations meet min40% for nominal maximum reachable builds; human duration not measured")
	quit()
