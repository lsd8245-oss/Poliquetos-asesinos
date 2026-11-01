class_name PoliWeapons
extends RefCounted

func step(g, dt: float, input: Dictionary):
	g.player.missile_clock -= dt
	if g.player.missile_clock<=0:
		fire_missiles(g)
	if input.get("bomb",false):
		bomb(g)
	var gear: Dictionary=g.data.combat.gear
	g.player.gear_time += dt
	g.player.multicorer_time += dt
	g.player.rov_clock -= dt
	if g.equipment("niskin") and g.player.gear_time>=float(gear.niskin_interval):
		g.player.gear_time=0.0
		g.effects.append({"kind":"pulse","pos":g.player.pos,"ttl":float(gear.niskin_duration),"radius":float(gear.niskin_radius)})
		for e in g.enemies:
			if e.pos.distance_to(g.player.pos)<=float(gear.niskin_radius):
				e.slow_left=float(gear.niskin_duration)
				e.slow_factor=float(gear.niskin_boss_slow) if e.get("boss",false) else float(gear.niskin_slow)
	if g.equipment("multicorer") and g.player.multicorer_time>=float(gear.multicorer_interval):
		g.player.multicorer_time=0.0
		var shot:Dictionary=g.data.combat.shot[int(g.profile.weapons.shot)-1]
		for n in range(int(gear.multicorer_count)):
			var angle=(float(n)/maxf(1,int(gear.multicorer_count)-1)-0.5)*0.6
			g.friendly_bullet(g.player.pos,Vector2.RIGHT.rotated(angle)*float(shot.speed),float(shot.damage)*float(gear.multicorer_damage)*float(g.stats.damage_mult),1)
	if g.equipment("rov") and g.player.rov_clock<=0:
		g.player.rov_clock=float(gear.rov_interval)
		var row:Dictionary=g.data.combat.shot[int(g.profile.weapons.shot)-1]
		var origin=g.player.pos+Vector2.from_angle(g.total_time*3)*30
		g.friendly_bullet(origin,Vector2.RIGHT*float(row.speed),float(row.dps)*float(gear.rov_dps_fraction)*float(gear.rov_interval)*float(g.stats.damage_mult)*float(g.stats.rate_mult))

func fire_missiles(g):
	var level=maxi(int(g.profile.weapons.missile),int(g.stats.min_missile))
	var row:Dictionary=g.data.combat.missile[clampi(level-1,0,7)]
	g.player.missile_clock=float(row.interval)/float(g.stats.rate_mult)
	for n in range(int(row.count)):
		var sign_y=-1.0 if n%2==0 and int(row.count)>1 else 1.0
		g.friendly_bullet(g.player.pos,Vector2(float(row.speed),float(row.launch_velocity_y)*sign_y),float(row.damage)*float(g.stats.damage_mult),0,{"missile":true,"homing":row.homing,"area":row.area,"arc_gravity":float(row.arc_gravity)*sign_y,"size":Vector2(12,6),"ttl":6.0})

func bomb(g) -> bool:
	if int(g.profile.bombs)<=0 or float(g.player.bomb_cd)>0:
		return false
	var row:Dictionary=g.data.combat.bomb[clampi(int(g.profile.weapons.bomb)-1,0,7)]
	g.profile.bombs -= 1
	g.player.bomb_cd=float(g.data.combat.timings.bomb_cooldown)
	g.effects.append({"kind":"bomb","pos":g.player.pos,"ttl":0.5,"radius":float(row.radius)})
	for i in range(g.enemy_bullets.size()-1,-1,-1):
		if row.full_screen or g.enemy_bullets[i].pos.distance_to(g.player.pos)<=float(row.radius):
			g.recycle_bullet(i)
	for e in g.enemies:
		if row.full_screen or e.pos.distance_to(g.player.pos)<=float(row.radius):
			if e.get("boss",false) and e.config.arquetipo=="polyn":
				e.flags.weak_exposed=true
				e["armor_open"]=4.0
			g.hit_enemy(e,float(row.damage)*float(g.stats.damage_mult),e.pos,true)
	return true
