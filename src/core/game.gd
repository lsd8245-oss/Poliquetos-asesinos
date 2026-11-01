class_name PoliGame
extends RefCounted

const Data = preload("res://src/core/data.gd")
var data: Dictionary
var profile: Dictionary
var player: Dictionary
var world: Dictionary
var stats: Dictionary
var enemies: Array = []
var bullets: Array = []
var enemy_bullets: Array = []
var drops: Array = []
var hazards: Array = []
var effects: Array = []
var free_bullets: Array = []
var state = "playing"
var previous_state = "playing"
var world_time = 0.0
var encounter_time = 0.0
var total_time = 0.0
var scroll = 0.0
var phase_clock = 0.0
var notice = ""
var notice_time = 0.0
var killer = ""
var killer_boss = false
var cursor = 0
var serial = 0
var regular_spawned = 0
var regular_kills = 0
var world_collected = 0
var wave_state: Dictionary = {}
var claimed_drops: Dictionary = {}
var mini_defeated = false
var mini_spawned = false
var boss_spawned = false
var checkpoint: Dictionary = {}
var result: Dictionary = {}
var replay = false
var replay_return: Dictionary = {}
var lander_used = false
var net_stock = 5
var slow_timer = 0.0
var slow_factor = 1.0
var death_streak = 0
var death_timer = 0.0
var invulnerability = 0.0
var shot_clock = 0.0
var resume_clock = 0.0
var max_bullets_seen = 0
var stage_system
var weapon_system
var boss_system
var rng = RandomNumberGenerator.new()

func _init():
	data = Data.all()
	if FileAccess.file_exists("res://src/stages/stages.gd"):
		stage_system = load("res://src/stages/stages.gd").new()
	if FileAccess.file_exists("res://src/weapons/weapons.gd"):
		weapon_system = load("res://src/weapons/weapons.gd").new()
	if FileAccess.file_exists("res://src/bosses/bosses.gd"):
		boss_system = load("res://src/bosses/bosses.gd").new()

func equipment(id: String) -> bool:
	return profile.get("equipment",{}).has(id)

func refresh_stats():
	if FileAccess.file_exists("res://src/shop/shop.gd"):
		stats = load("res://src/shop/shop.gd").stats(profile)
	else:
		var base:Dictionary=data.combat.player
		stats={"max_shield":float(base.shield),"damage_mult":1.0,"rate_mult":1.0,"min_missile":1,"max_bombs":int(base.initial_bombs),"regen":0.0,"magnet":float(base.magnet_radius),"speed":float(base.speed)}

func start(p: Dictionary, restore_checkpoint: Dictionary = {}):
	profile = p
	refresh_stats()
	world = world_config(int(profile.get("world",1)))
	world_time = 0.0
	encounter_time = 0.0
	total_time = float(profile.get("time",0.0))
	scroll = 0.0
	phase_clock = 0.0
	cursor = 0
	serial = 0
	regular_spawned = 0
	regular_kills = 0
	world_collected = 0
	wave_state.clear()
	claimed_drops = profile.get("claimed_drops",{}).duplicate(true)
	mini_spawned = false
	mini_defeated = false
	boss_spawned = false
	lander_used = int(profile.get("lander_used_world",0)) == int(profile.world)
	net_stock = int(data.combat.get("gear",{}).get("net_capacity",5))
	rng.seed = int(profile.get("seed",12345)) + int(profile.world)
	enemies.clear()
	bullets.clear()
	enemy_bullets.clear()
	free_bullets.clear()
	drops.clear()
	hazards.clear()
	effects.clear()
	for i in range(int(data.combat.enemy.bullet_pool)):
		free_bullets.append({})
	var config: Dictionary = data.combat.player
	var start_pos = config.get("start_pos",[80,168])
	player = {"pos":Vector2(start_pos[0],start_pos[1]),"shield":float(stats.max_shield),"since_damage":0.0,"bomb_cd":0.0,"grapple":0.0,"slow":0.0,"gear_time":0.0,"multicorer_time":0.0,"rov_clock":0.0,"missile_clock":0.0}
	if not profile.has("world_entry_weapons") or int(profile.get("entry_world",0)) != int(profile.world):
		profile.world_entry_weapons = profile.weapons.duplicate(true)
		profile.entry_world = int(profile.world)
	profile.weapons.missile = maxi(int(profile.weapons.missile),int(stats.min_missile))
	profile.bombs = mini(int(profile.get("bombs",2)),int(stats.max_bombs))
	state = "playing"
	invulnerability = 0.0
	shot_clock = 0.0
	if not restore_checkpoint.is_empty():
		world_time = float(restore_checkpoint.get("time",0.0))
		cursor = int(restore_checkpoint.get("cursor",0))
		mini_spawned = bool(restore_checkpoint.get("mini_defeated",false))
		mini_defeated = mini_spawned
		regular_spawned = int(restore_checkpoint.get("regular_spawned",0))
		regular_kills = int(restore_checkpoint.get("regular_kills",0))
		world_collected = int(restore_checkpoint.get("world_collected",0))
		boss_spawned = false
		scroll = world_time*float(world.get("scroll_px_s",60))
	checkpoint = {"time":world_time,"cursor":cursor,"mini_defeated":mini_defeated,"regular_spawned":regular_spawned,"regular_kills":regular_kills,"world_collected":world_collected}
	if stage_system != null:
		stage_system.begin(self)
	if int(profile.world)==14 and int(profile.get("lab_boss",0))>0:
		world_time = float(world.duracion_hasta_jefe_seg)
		mini_defeated = true
		mini_spawned = true
		state = "alert"
		phase_clock = 0.0
		set_notice("SALA %d DEL LABORATORIO" % (int(profile.lab_boss)+1),2.0)

func world_config(id: int) -> Dictionary:
	if id == 15:
		var escape = data.escape.duplicate(true)
		escape["nombre"] = "Escape del laboratorio"
		escape["acto"] = 4
		escape["id"] = 15
		escape["duracion_hasta_jefe_seg"] = escape.get("duracion_seg",300)
		return escape
	for w in data.worlds:
		if int(w.id)==id:
			return w
	return data.worlds[0]

func set_notice(text: String, duration: float = 2.0):
	notice = text
	notice_time = duration

func difficulty() -> Dictionary:
	return data.combat.difficulty.get(profile.get("difficulty","normal"),data.combat.difficulty.get("normal",{}))

func step(dt: float, input: Dictionary = {}):
	if state == "pause" or state in ["dead","rest","results","victory"]:
		return
	if state == "countdown":
		resume_clock -= dt
		if resume_clock <= 0:
			state = previous_state
		return
	if state == "dying":
		death_timer -= dt
		if death_timer <= 0:
			state = "dead"
		return
	total_time += dt
	profile.time = total_time
	phase_clock += dt
	if notice_time>0:
		notice_time -= dt
	invulnerability = maxf(0,invulnerability-dt)
	player.since_damage += dt
	player.bomb_cd = maxf(0,player.bomb_cd-dt)
	player.slow = maxf(0,player.slow-dt)
	player.grapple = maxf(0,player.grapple-dt)
	var movement: Vector2 = input.get("move",Vector2.ZERO)
	if movement.length()>1:
		movement = movement.normalized()
	var speed = float(stats.speed)
	if player.slow>0:
		speed *= slow_factor
	if player.grapple>0:
		speed *= float(data.combat.get("gear",{}).get("grapple_speed",0.25))
	player.pos += movement*speed*dt
	var hb = data.combat.player.hitbox
	player.pos.x = clampf(player.pos.x,float(hb[0])/2.0,640.0-float(hb[0])/2.0)
	player.pos.y = clampf(player.pos.y,float(hb[1])/2.0,336.0-float(hb[1])/2.0)
	if stats.regen>0 and player.since_damage >= float(data.combat.get("gear",{}).get("regen_delay",5)):
		player.shield = minf(stats.max_shield,player.shield+stats.regen*dt)
	shot_clock -= dt
	if input.get("fire",false) and shot_clock<=0:
		shoot_primary()
	if weapon_system != null:
		weapon_system.step(self,dt,input)
	if stage_system != null:
		stage_system.step(self,dt)
	if boss_system != null:
		boss_system.step(self,dt)
	step_projectiles(dt)
	step_enemies(dt)
	step_hazards(dt)
	step_drops(dt)
	for i in range(effects.size()-1,-1,-1):
		effects[i]["age"]=float(effects[i].get("age",0))+dt
		effects[i].ttl -= dt
		if effects[i].ttl<=0:
			effects.remove_at(i)

func shoot_primary():
	var row: Dictionary = data.combat.shot[clampi(int(profile.weapons.shot)-1,0,7)]
	var interval = float(row.interval)/float(stats.rate_mult)
	shot_clock = interval
	var count = int(row.count)-(1 if bool(row.get("beam",false)) else 0)
	var beam = bool(row.get("beam",false))
	var damage = float(row.dps)*float(row.interval)/float(count+(1 if beam else 0))*float(stats.damage_mult)
	var angles: Array = row.get("angles",[0])
	for n in range(count):
		var angle = float(angles[mini(n,angles.size()-1)])
		# Parallel level2 is spatially separated, not an extra hidden DPS multiplier.
		var offset = Vector2(20, (n-(count-1)/2.0)*4 if int(row.level)==2 else 0)
		friendly_bullet(player.pos+offset,Vector2.RIGHT.rotated(angle)*float(row.speed),damage,int(row.get("pierce",0))+(1 if equipment("box_corer") else 0))
	if beam:
		friendly_bullet(player.pos+Vector2(24,0),Vector2.RIGHT*float(row.speed),damage,int(row.get("pierce",0)),{"size":Vector2(24,8),"beam":true})

func friendly_bullet(pos: Vector2, velocity: Vector2, damage: float, pierce: int = 0, options: Dictionary = {}):
	var b = {"pos":pos,"velocity":velocity,"damage":damage,"pierce":pierce,"ttl":float(data.combat.friendly_projectile.ttl),"size":Vector2(data.combat.friendly_projectile.size[0],data.combat.friendly_projectile.size[1]),"hits":{},"missile":false}
	b.merge(options,true)
	bullets.append(b)

func enemy_bullet(pos: Vector2, velocity: Vector2, options: Dictionary = {}) -> bool:
	if enemy_bullets.size() >= int(data.combat.enemy.bullet_pool) or free_bullets.is_empty():
		return false
	var b: Dictionary = free_bullets.pop_back()
	b.clear()
	b.merge({"pos":pos,"velocity":velocity,"ttl":8.0,"age":0.0,"size":Vector2(6,6),"source":"Poliqueto","boss":false,"damage":floorf(float(data.combat.enemy.bullet_damage_base)+float(data.combat.enemy.bullet_damage_world_step)*(int(profile.world)-1)),"homing":false,"bounce":0,"slow":0.0})
	b.merge(options,true)
	enemy_bullets.append(b)
	max_bullets_seen = maxi(max_bullets_seen,enemy_bullets.size())
	return true

func recycle_bullet(index: int):
	free_bullets.append(enemy_bullets[index])
	enemy_bullets.remove_at(index)

func step_projectiles(dt: float):
	for i in range(bullets.size()-1,-1,-1):
		var b: Dictionary = bullets[i]
		b.ttl -= dt
		if b.get("homing",false) and not enemies.is_empty():
			var target = enemies[0]
			for e in enemies:
				if e.hp>0 and e.pos.distance_squared_to(b.pos)<target.pos.distance_squared_to(b.pos):
					target = e
			var wanted = (target.pos-b.pos).normalized()*b.velocity.length()
			b.velocity = b.velocity.lerp(wanted,minf(1.0,dt*float(data.combat.get("gear",{}).get("homing_turn",3))))
		if b.get("arc_gravity",0.0)!=0.0 and not b.get("homing",false):
			b.velocity.y += float(b.arc_gravity)*dt
		b.pos += b.velocity*dt
		if b.get("missile",false):
			b.pos.y = clampf(b.pos.y,8,328)
			if b.pos.y in [8.0,328.0]:
				b.velocity.y=0
		for e in enemies:
			if e.hp<=0 or b.hits.has(e.uid):
				continue
			var rect = Rect2(e.pos-e.size/2,e.size)
			if rect.grow(maxf(b.size.x,b.size.y)/2).has_point(b.pos):
				b.hits[e.uid] = true
				hit_enemy(e,float(b.damage),b.pos,b.get("beam",false))
				if float(b.get("area",0))>0:
					for other in enemies:
						if other!=e and other.pos.distance_to(e.pos)<=float(b.area):
							hit_enemy(other,float(b.damage)*0.5,other.pos)
				b.pierce -= 1
				if b.pierce<0:
					b.ttl=0
					break
		if b.ttl<=0 or b.pos.x>700 or b.pos.x< -60 or b.pos.y< -60 or b.pos.y>400:
			bullets.remove_at(i)
	for i in range(enemy_bullets.size()-1,-1,-1):
		var b: Dictionary = enemy_bullets[i]
		b.ttl -= dt
		b.age += dt
		if b.get("homing",false) and b.age<float(data.combat.get("gear",{}).get("enemy_homing_time",2)):
			b.velocity=b.velocity.lerp((player.pos-b.pos).normalized()*b.velocity.length(),minf(1,dt))
		if b.has("return_after") and b.age>=float(b.return_after) and not b.get("returned",false):
			b.velocity *= -1
			b.returned=true
		b.pos += b.velocity*dt
		if int(b.get("bounce",0))>0 and (b.pos.y<3 or b.pos.y>333):
			b.velocity.y *= -1
			b.pos.y=clampf(b.pos.y,3,333)
			b.bounce -= 1
		var delta: Vector2 = b.pos-player.pos
		if delta.x>0 and delta.x<32 and absf(delta.y)<16:
			if equipment("deflector"):
				friendly_bullet(b.pos,Vector2.RIGHT*350,5)
				b.ttl=0
			elif equipment("red_arrastre") and net_stock>0:
				net_stock -= 1
				b.ttl=0
		var hb = data.combat.player.hitbox
		if b.ttl>0 and absf(delta.x)<float(hb[0])/2+b.size.x/2 and absf(delta.y)<float(hb[1])/2+b.size.y/2:
			damage_player(float(b.damage),str(b.get("source","Poliqueto")),bool(b.get("boss",false)))
			if float(b.get("slow",0))>0:
				player.slow=float(b.slow)
				slow_factor=float(b.get("slow_factor",0.5))
			b.ttl=0
		if b.ttl<=0 or b.pos.x< -50 or b.pos.x>690 or b.pos.y< -50 or b.pos.y>386:
			recycle_bullet(i)

func damage_player(amount: float, source: String, boss: bool = false):
	if invulnerability>0 or state in ["dying","dead","rest","results","victory"]:
		return
	var mult = float(difficulty().get("damage",difficulty().get("damage_mult",1.0)))
	player.shield = maxf(0,player.shield-amount*mult)
	player.since_damage=0.0
	invulnerability = float(data.combat.player.damage_invulnerability)
	effects.append({"kind":"hit","pos":player.pos,"ttl":0.2})
	if player.shield<=0:
		if equipment("lander") and not lander_used:
			lander_used=true
			profile.lander_used_world=int(profile.world)
			player.shield=float(stats.max_shield)*0.5
			invulnerability=float(data.combat.player.respawn_invulnerability)
			set_notice("LANDER: RESURRECCIÓN")
			return
		killer=source
		killer_boss=boss
		var key=str(profile.world)
		profile.deaths[key]=int(profile.deaths.get(key,0))+1
		death_streak += 1
		death_timer=float(data.combat.timings.death_explosion)+float(data.combat.timings.death_fade)
		state="dying"
		effects.append({"kind":"explosion","pos":player.pos,"ttl":float(data.combat.timings.death_explosion)})

func hit_enemy(e: Dictionary, amount: float, hit_pos: Vector2, bomb: bool = false):
	if e.hp<=0 or float(e.get("lock",0))>0 or float(e.get("entry",0))>0:
		return
	if bool(e.get("boss",false)) or bool(e.get("mini",false)):
		if boss_system!=null:
			boss_system.damage(self,e,amount,hit_pos,bomb)
		return
	if e.get("id","")=="mech_polyn" and fmod(float(e.age),5)>1 and hit_pos.x<e.pos.x:
		return
	e.hp -= amount
	e.flash=0.04
	if e.hp<=0:
		kill_enemy(e)

func kill_enemy(e: Dictionary):
	if e.get("counted_dead",false):
		return
	e.counted_dead=true
	effects.append({"kind":"explosion","pos":e.pos,"ttl":0.5})
	if not e.get("boss",false) and not e.get("mini",false) and not e.get("escort",false) and not e.get("summoned",false):
		regular_kills += 1
		var key=str(e.get("wave",-1))
		if wave_state.has(key):
			wave_state[key].killed += 1
			if wave_state[key].killed==wave_state[key].count and wave_state[key].get("item","")!="":
				spawn_drop(wave_state[key].item,e.pos,"carrier:"+key)
		var base=float(world.get("base_monedas",0))
		var total=maxi(1,int(world.get("enemigos_total",90)))
		var units=floori(base*0.75/float(data.combat.items.small_coin))
		var ordinal=int(e.get("ordinal",0))
		var coin_units=floori(float((ordinal+1)*units)/total)-floori(float(ordinal*units)/total)
		if coin_units>0:
			spawn_drop("coin",e.pos,"enemy:%s" % e.uid,coin_units*float(data.combat.items.small_coin))

func spawn_drop(kind: String, pos: Vector2, uid: String, value: float = 0.0):
	var key="%d:%s:%s" % [int(profile.world),str(profile.get("lab_boss",0)),uid]
	if claimed_drops.has(key):
		return
	drops.append({"kind":kind,"pos":pos,"uid":key,"value":value})

func step_drops(dt: float):
	for i in range(drops.size()-1,-1,-1):
		var drop: Dictionary=drops[i]
		drop.pos.x -= float(data.combat.items.speed)*dt
		var dist:float=drop.pos.distance_to(player.pos)
		var magnet=float(stats.magnet)
		if equipment("draga"):
			magnet=maxf(magnet,96)
		if drop.kind=="coin" and dist<magnet:
			drop.pos=drop.pos.move_toward(player.pos,float(data.combat.get("gear",{}).get("magnet_speed",260))*dt)
		if dist<18:
			collect_drop(drop)
			drops.remove_at(i)
		elif drop.pos.x< -20:
			drops.remove_at(i)

func collect_drop(drop: Dictionary):
	if claimed_drops.has(drop.uid):
		return
	claimed_drops[drop.uid]=true
	profile.claimed_drops=claimed_drops.duplicate(true)
	if drop.kind=="coin":
		add_coins(float(drop.value))
	elif drop.kind in ["amarillo","shield"]:
		player.shield=minf(stats.max_shield,player.shield+stats.max_shield*float(data.combat.items.shield_fraction)*float(difficulty().get("shield_items",1.0)))
	else:
		var weapon_key={"rojo":"shot","verde":"missile","azul":"bomb"}.get(drop.kind,"shot")
		if int(profile.weapons[weapon_key])>=8:
			add_coins(float(data.combat.items.max_level_value))
		else:
			profile.weapons[weapon_key] += 1
			set_notice("NIVEL %d" % profile.weapons[weapon_key])
		if weapon_key=="bomb":
			profile.bombs=mini(int(stats.max_bombs),int(profile.bombs)+1)

func add_coins(amount: float):
	world_collected += amount
	profile["coins_total"]=float(profile.get("coins_total",0))+amount
	if profile.get("edition","normal")=="pruebas":
		profile.credits=999999999
	else:
		profile.credits=float(profile.credits)+amount

func make_checkpoint():
	checkpoint={"time":world_time,"cursor":cursor,"mini_defeated":mini_defeated,"regular_spawned":regular_spawned,"regular_kills":regular_kills,"world_collected":world_collected}
	net_stock=5
	death_streak=0
	set_notice("PUNTO DE CONTROL",float(data.combat.timings.checkpoint_notice))

func retry():
	var cp=checkpoint.duplicate(true)
	var claims=claimed_drops.duplicate(true)
	var old_collected=world_collected
	profile.weapons=profile.world_entry_weapons.duplicate(true)
	profile.weapons.missile=maxi(int(profile.weapons.missile),int(stats.min_missile))
	start(profile,cp)
	claimed_drops=claims
	profile.claimed_drops=claims
	world_collected=old_collected
	invulnerability=float(data.combat.player.respawn_invulnerability)

func pause():
	if state in ["playing","boss","alert"]:
		previous_state=state
		state="pause"

func unpause():
	if state=="pause":
		resume_clock=float(data.combat.timings.pause_resume)
		state="countdown"

func step_enemies(dt: float):
	if stage_system!=null:
		stage_system.move_enemies(self,dt)
	for i in range(enemies.size()-1,-1,-1):
		var e:Dictionary=enemies[i]
		e.flash=maxf(0,float(e.get("flash",0))-dt)
		if e.hp<=0:
			if not e.get("boss",false) and not e.get("mini",false):
				enemies.remove_at(i)
			continue
		if Rect2(e.pos-e.size/2,e.size).grow(3).has_point(player.pos) and not e.get("hidden",false) and float(e.get("entry",0))<=0:
			var contact=float(data.combat.enemy.boss_contact_base)+float(data.combat.enemy.boss_contact_world_step)*(int(profile.world)-1) if e.get("boss",false) else float(data.combat.enemy.contact_damage_base)+float(data.combat.enemy.contact_damage_world_step)*(int(profile.world)-1)
			damage_player(contact,str(e.get("name",e.get("id","Poliqueto"))),bool(e.get("boss",false)))
		if not e.get("boss",false) and not e.get("mini",false) and (e.pos.x< -150 or e.age>40):
			enemies.remove_at(i)

func step_hazards(dt: float):
	for i in range(hazards.size()-1,-1,-1):
		var h:Dictionary=hazards[i]
		h.delay=float(h.get("delay",0))-dt
		if h.delay>0:
			continue
		h.duration -= dt
		if h.get("scroll",false):
			h.rect.position.x-=float(world.get("scroll_px_s",60))*dt
		if h.rect.has_point(player.pos):
			match str(h.get("effect","damage")):
				"slow":
					player.slow=maxf(0.2,float(h.get("slow_duration",0.2)))
					slow_factor=float(h.get("slow",0.7))
				"push":
					player.pos+=h.get("direction",Vector2.ZERO)*dt
				"grapple":
					player.grapple=0.5
					player.pos=player.pos.move_toward(h.rect.get_center(),dt*20)
				"blind":
					pass
				_:
					damage_player(float(h.get("damage",data.combat.enemy.hazard_damage)),str(h.get("name","Peligro de escenario")),bool(h.get("boss",false)))
		if h.duration<=0:
			hazards.remove_at(i)

func clear_enemy_bullets(convert: bool, owner: String = "", phase: int = 0):
	for i in range(enemy_bullets.size()-1,-1,-1):
		if convert:
			spawn_drop("coin",enemy_bullets[i].pos,"phase:%s:%d:%d"%[owner,phase,i],float(data.combat.items.small_coin))
		recycle_bullet(i)
	serial+=1

func enemy_hit_rects(e: Dictionary) -> Array:
	var result_rects:Array=[]
	if e.get("boss",false) or e.get("mini",false):
		for part in e.config.segmentos:
			var r=part.hitbox
			result_rects.append(Rect2(e.pos-e.size/2+Vector2(r[0],r[1]),Vector2(r[2],r[3])))
	else:
		result_rects.append(Rect2(e.pos-e.size/2,e.size))
	return result_rects

func unlock_skin(id: String):
	if not profile.skins.has(id):
		profile.skins.append(id)

func finish_encounter():
	if state in ["results","rest","victory"]:
		return
	var base=float(world.get("base_monedas",0))
	var encounter=int(profile.get("lab_boss",0))
	if int(profile.world)==14:
		base=float(world.sectores_jefes[clampi(encounter,0,3)].base_monedas)
		# Later lab rooms contain boss phases/escorts, not another 250 regular enemies.
		if encounter>0:
			add_coins(base*0.6)
	var deaths=int(profile.deaths.get(str(profile.world),0))
	var reward=base*0.4
	var bonus=base*0.2 if deaths==0 and not replay else 0.0
	if replay:
		reward=base*0.5
		bonus=0.0
	var reward_key="%d:%d"%[int(profile.world),encounter]
	var rewarded:Dictionary=profile.get("rewarded",{})
	if not replay and rewarded.has(reward_key):
		reward=0.0
		bonus=0.0
	else:
		rewarded[reward_key]=true
	profile.rewarded=rewarded
	add_coins(reward+bonus)
	result={"mundo":int(profile.world),"nombre":world.nombre,"enemigos_derrotados":regular_kills,"enemigos_total":int(world.enemigos_total),"porcentaje":100.0*regular_kills/maxi(1,int(world.enemigos_total)),"monedas_recogidas":world_collected-reward-bonus,"recompensa":reward,"bono":bonus,"muertes":deaths,"tiempo":world_time+encounter_time,"objeto_unico":""}
	if not replay:
		var skin={3:"coral",6:"abisal",9:"bioluminiscente",12:"magma"}.get(int(profile.world),"")
		if skin!="":
			unlock_skin(skin)
			result.objeto_unico=skin
		if int(profile.world)==4:unlock_skin("batiscafo_amarillo")
		if deaths==0 and profile.difficulty=="hard":unlock_skin("fantasma")
		if int(profile.world)==14:
			profile.lab_boss=encounter+1
			if int(profile.lab_boss)>=4:
				unlock_skin("laboratorio")
				if not profile.cleared.has(14):profile.cleared.append(14)
		elif not profile.cleared.has(int(profile.world)):
			profile.cleared.append(int(profile.world))
	profile.resume="rest"
	state="results"
	phase_clock=0.0

func continue_campaign():
	if profile.get("completed",false) and not replay:
		state="victory"
		return
	profile.resume="playing"
	if replay:
		var money=float(profile.credits)
		var progress=replay_return.duplicate(true)
		progress.credits=money
		progress.time=profile.time
		progress.upgrades=profile.upgrades
		progress.equipment=profile.equipment
		profile=progress
		replay=false
		state="rest"
		profile.resume="rest"
		return
	if int(profile.world)==14 and int(profile.lab_boss)<4:
		start(profile)
		return
	profile.world=mini(15,int(profile.world)+1)
	profile.lab_boss=0
	profile.claimed_drops={}
	start(profile)

func begin_replay(id: int):
	if not profile.cleared.has(id) and profile.edition!="pruebas":
		return
	replay_return=profile.duplicate(true)
	var p=profile.duplicate(true)
	p.world=id
	p.lab_boss=0
	p.claimed_drops={}
	start(p)
	replay=true

func finish_escape():
	if state=="victory":return
	var deaths=0
	for n in profile.deaths.values():deaths+=int(n)
	if deaths==0:unlock_skin("dorado")
	profile.completed=true
	profile.escape_score=int(data.escape.recompensa)
	profile.resume="completed"
	state="victory"
	phase_clock=0.0
	result={"tiempo_total":profile.time,"muertes_totales":deaths,"monedas_totales":profile.get("coins_total",0),"puntuacion_escape":int(data.escape.recompensa),"mundos_superados":profile.cleared.size()}
