class_name PoliStages
extends RefCounted
var events: Array=[]
var enemy_index:Dictionary={}
var burst_queue:Array=[]
var escape_checkpoint=0

func begin(g):
	events=(g.data.escape.eventos if int(g.profile.world)==15 else g.data.waves[int(g.profile.world)].eventos).duplicate(true)
	enemy_index.clear()
	burst_queue.clear()
	escape_checkpoint=int(g.world_time/90)
	for e in g.data.enemies:
		enemy_index[e.id]=e
	if int(g.profile.world)==14:
		# Profile seed fixes both family selection and their wave mapping on every retry.
		var available:Array=g.world.recurrentes.duplicate()
		var selected:Array=[]
		var random=RandomNumberGenerator.new()
		random.seed=int(g.profile.seed)
		while not available.is_empty() and selected.size()<22:
			selected.append(available.pop_at(random.randi_range(0,available.size()-1)))
		var mapping={}
		for event in events:
			if event.tipo=="oleada" and not g.world.unicos.has(event.enemigo):
				if not mapping.has(event.enemigo):
					mapping[event.enemigo]=selected[mapping.size()%selected.size()]
				event.enemigo=mapping[event.enemigo]

func step(g,dt:float):
	if g.state=="playing":
		g.world_time+=dt
		g.scroll+=float(g.world.get("scroll_px_s",60))*dt
		while g.cursor<events.size() and float(events[g.cursor].t)<=g.world_time:
			var event:Dictionary=events[g.cursor]
			var wave_id=g.cursor
			g.cursor+=1
			match str(event.tipo):
				"oleada":
					spawn_wave(g,event,wave_id)
				"minijefe":
					g.mini_spawned=true
					if g.boss_system!=null:
						g.boss_system.spawn(g,str(event.id),true)
					var pool:Array=g.world.unicos
					for n in range(2):
						spawn_enemy(g,str(pool[n%pool.size()]),Vector2(660+n*40,70+n*180),-1,{"escort":true,"uid":"escort_%d"%n})
				"escudo":
					g.spawn_drop("amarillo",Vector2(600,float(event.get("y",140))),"shield:%d"%wave_id)
				"peligro":
					spawn_hazard(g,event)
		if int(g.profile.world)==15:
			var cp=int(g.world_time/float(g.data.escape.checkpoint_cada_seg))
			if cp>escape_checkpoint:
				escape_checkpoint=cp
				g.make_checkpoint()
			if g.world_time>=float(g.data.escape.duracion_seg):
				g.finish_escape()
		elif g.world_time>=float(g.world.alerta_jefe_seg) and g.mini_defeated:
			if bool(g.difficulty().get("alert_checkpoint",false)):
				g.make_checkpoint()
			g.state="alert"
			g.phase_clock=0.0
			g.set_notice("ALERTA",float(g.data.combat.timings.alert))
	for i in range(burst_queue.size()-1,-1,-1):
		burst_queue[i].wait-=dt
		if burst_queue[i].wait<=0:
			var b:Dictionary=burst_queue[i]
			g.enemy_bullet(b.pos,b.velocity,b.options)
			burst_queue.remove_at(i)

func spawn_wave(g,event:Dictionary,wave_id:int):
	var key=str(wave_id)
	g.wave_state[key]={"count":int(event.cantidad),"killed":0,"item":str(event.get("item","")) if event.get("portadora",false) else ""}
	for n in range(int(event.cantidad)):
		var pos=formation(str(event.formacion),n,int(event.cantidad),float(event.get("y",168)),float(event.get("separacion_px",32)))
		spawn_enemy(g,str(event.enemigo),pos,wave_id,{"uid":"wave_%d_%d"%[wave_id,n],"ordinal":g.regular_spawned,"carrier":str(event.get("item","")) if event.get("portadora",false) else ""})
		g.regular_spawned+=1

func formation(kind:String,n:int,count:int,y:float,gap:float)->Vector2:
	var center=(count-1)/2.0
	match kind:
		"linea_vertical":
			return Vector2(660,clampf(30+float(n)*276/maxi(1,count-1),20,316))
		"v":
			return Vector2(660+absf(n-center)*gap,clampf(y+(n-center)*gap*0.7,20,316))
		"v_invertida":
			return Vector2(660+(center-absf(n-center))*gap,clampf(y+(n-center)*gap*0.7,20,316))
		"zigzag":
			return Vector2(660+n*gap,clampf(y+sin(n*PI/2)*60,20,316))
		"circulo":
			return Vector2(730,168)+Vector2.from_angle(float(n)/count*TAU)*64
		"doble_columna":
			return Vector2(660+(n%2)*gap,clampf(35+(n/2)*gap,20,316))
		"ambos_lados":
			return Vector2(660+(n/2)*gap,30 if n%2==0 else 306)
		"diagonal":
			return Vector2(660+n*gap,clampf(35+n*20,20,316))
		_:
			return Vector2(660+n*gap,clampf(y,20,316))

func spawn_enemy(g,id:String,pos:Vector2,wave:int=-1,extra:Dictionary={}):
	if not enemy_index.has(id):
		push_error("Enemy not found: "+id)
		return {}
	var cfg:Dictionary=enemy_index[id]
	var n=int(g.profile.world)
	var ref=float(g.data.combat.enemy.dps_ref_base)+float(g.data.combat.enemy.dps_ref_world_step)*(mini(n,14)-1)
	var hp=ceilf(ref/float(g.data.combat.enemy.small_hp_divisor))
	if cfg.categoria=="enjambre":
		hp=ceilf(ref/float(g.data.combat.enemy.swarm_hp_divisor))
	elif cfg.categoria=="mediano":
		hp*=float(g.data.combat.enemy.medium_hp_multiplier)
	if cfg.get("blindado",false):
		hp*=float(g.data.combat.enemy.armored_hp_multiplier)
	if extra.get("escort",false):
		hp=ceilf(ref/float(g.data.combat.enemy.small_hp_divisor))*float(g.data.combat.enemy.escort_hp_multiplier)
	g.serial+=1
	var e={"uid":extra.get("uid","summon_%d"%g.serial),"id":id,"name":cfg.familia,"config":cfg,"hp":hp,"max_hp":hp,"pos":pos,"origin":pos,"size":Vector2(cfg.tamano[0],cfg.tamano[1]),"age":0.0,"fire_clock":1.0,"phase":1,"wave":wave,"boss":false,"mini":false,"flash":0.0,"slow_left":0.0,"slow_factor":1.0,"hidden":false}
	e.merge(extra,true)
	g.enemies.append(e)
	return e

func move_enemies(g,dt:float):
	for e in g.enemies:
		if e.get("boss",false) or e.get("mini",false) or e.hp<=0:
			continue
		e.age+=dt
		e.slow_left=maxf(0,float(e.get("slow_left",0))-dt)
		var local_dt=dt*(float(e.slow_factor) if e.slow_left>0 else 1.0)
		var movement=str(e.config.movimiento)
		var m:Dictionary=g.data.combat.movement[movement]
		match movement:
			"M1":
				e.pos.x-=float(m.speed)*local_dt
			"M2":
				e.pos.x-=float(m.speed)*local_dt
				e.pos.y=e.origin.y+sin(float(e.age)*float(m.frequency))*float(m.amplitude)
			"M3":
				e.pos.x-=float(m.speed)*local_dt
				e.pos.y=move_toward(e.pos.y,g.player.pos.y,float(m.pursuit_speed)*local_dt)
			"M4":
				e.pos.x-=float(m.speed)*local_dt
				if e.age<float(m.turn_after):
					e.pos.y+=float(m.entry_vertical_speed)*local_dt*(1 if e.origin.y<168 else -1)
			"M5":
				e.pos.x-=float(g.world.scroll_px_s)*local_dt
				e.pos.y=304 if fmod(float(e.origin.y),2)>0 else 32
			"M6":
				e.pos.x-=float(g.world.scroll_px_s)*local_dt
				var cycle=fmod(float(e.age),float(m.telegraph)+float(m.stay)+1.0)
				e.hidden=cycle<float(m.telegraph)
				e.pos.y=330 if e.hidden else 284
			"M7":
				if e.age<float(m.stop_after):
					e.pos.x-=float(m.speed)*local_dt
				elif e.age<float(m.stop_after)+float(m.telegraph):
					e["warning"]=true
				else:
					e["warning"]=false
					e.pos.x-=float(m.charge_speed)*local_dt
			"M8":
				e.origin.x-=float(m.speed)*local_dt
				e.pos=e.origin+Vector2.from_angle(e.age*float(m.angular_speed))*float(m.radius)
		e.fire_clock-=local_dt
		if e.fire_clock<=0 and e.pos.x<640 and not e.hidden:
			fire_enemy(g,e)

func fire_enemy(g,e:Dictionary):
	var code=str(e.config.disparo)
	var row:Dictionary=g.data.combat.fire_patterns[code]
	if code=="F0":
		e.fire_clock=1000.0
		return
	e.fire_clock=float(row.interval)
	var speed=bullet_speed(g)
	var aim=(g.player.pos-e.pos).angle()
	var origin=e.pos-Vector2(e.size.x/2,0)
	var options={"source":str(e.name)}
	for n in range(int(row.count)):
		var angle=PI if code=="F1" else aim
		if code=="F3":
			angle+= (float(n)/(maxi(1,int(row.count)-1))-0.5)*float(row.spread)
		elif code=="F4":
			angle=float(n)/int(row.count)*TAU
		var velocity=Vector2.from_angle(angle)*speed
		if code=="F5" and n>0:
			burst_queue.append({"wait":n*float(row.burst_interval),"pos":origin,"velocity":velocity,"options":options.duplicate(true)})
		else:
			g.enemy_bullet(origin,velocity,options)

func bullet_speed(g)->float:
	return float(g.data.combat.enemy.bullet_speed_base)*(1+float(g.data.combat.enemy.bullet_speed_world_scale)*(int(g.profile.world)-1))*float(g.difficulty().get("bullet_speed",1))

func spawn_hazard(g,event:Dictionary):
	var id=str(event.id)
	var cfg:Dictionary=g.data.combat.get("hazards",{}).get(id,{})
	var y=float(event.get("y",280))
	var h={"name":id.capitalize(),"rect":Rect2(650,y,40,48),"delay":0.5,"duration":float(event.get("duracion_seg",12)),"damage":float(g.data.combat.enemy.hazard_damage),"effect":"damage","scroll":true,"id":id}
	match id:
		"corriente_marea":
			h.merge({"rect":Rect2(0,0,640,336),"effect":"push","direction":Vector2(0,30 if int(g.world_time/10)%2==0 else -30),"scroll":false,"duration":10},true)
		"corriente_hojas", "corrientes", "cintas":
			h.merge({"rect":Rect2(0,0,640,336),"effect":"push","direction":Vector2(-20,0),"scroll":false},true)
		"kelp","petroleo":
			h.effect="slow"
			h["slow"]=0.7 if id=="kelp" else 0.75
		"granizo":
			h.rect=Rect2(g.rng.randf_range(0,600),0,10,336)
			h.damage=10
			h.scroll=false
			h.duration=0.5
		"geiseres","laseres","lava":
			h.rect=Rect2(g.rng.randf_range(60,600),230,28,106) if id!="lava" else Rect2(0,324,640,12)
			h.delay=1.0
			h.scroll=false
			h.duration=2.0
		"compuertas":
			h.rect=Rect2(g.rng.randf_range(200,580),0,28,240)
			h.scroll=false
			h.delay=1.0
			h.duration=3.0
		"escombros":
			h.rect=Rect2(g.rng.randf_range(0,600),0,24,336)
			h.scroll=false
			h.delay=0.5
			h.duration=0.4
		"corales","raices","costillas","icebergs":
			h.rect=Rect2(650,0 if id=="raices" else 260,48,76)
	if not cfg.is_empty():
		for key in ["delay","duration","damage","slow"]:
			if cfg.has(key):h[key]=cfg[key]
	g.hazards.append(h)
