class_name PoliBosses
extends RefCounted
const Patterns=preload("res://src/bosses/patterns.gd")
var defeat_clock=-1.0
var group_ids:Array=[]

func spawn(g,id:String,mini:bool=false,index:int=0,count:int=1):
	var cfg:Dictionary={}
	for row in g.data.bosses:
		if row.id==id:
			cfg=row
			break
	if cfg.is_empty():
		push_error("Boss not found: "+id)
		return
	var size=Vector2(cfg.tamano[0],cfg.tamano[1])
	var hp=float(cfg.vida)*float(g.difficulty().get("boss_hp",1))
	var lane=336.0*(index+1)/(count+1)
	var pos=Vector2(640-size.x/2-8,lane)
	g.serial+=1
	var e={"uid":"boss:"+id,"id":id,"name":cfg.nombre,"config":cfg,"pos":pos,"origin":pos,"size":size,"hp":hp,"max_hp":hp,"phase":1,"age":0.0,"attack_clock":0.0,"lock":0.0,"entry":float(g.data.combat.timings.boss_entry),"boss":not mini,"mini":mini,"flags":{},"flash":0.0,"alive_time":0.0,"wave":-1,"slow_left":0.0,"slow_factor":1.0,"fury_multiplier":1.0,"armor_open":0.0}
	g.enemies.append(e)
	g.set_notice(str(cfg.nombre).to_upper(),float(g.data.combat.timings.boss_entry))

func step(g,dt:float):
	if g.state=="alert" and g.phase_clock>=float(g.data.combat.timings.alert):
		g.state="boss"
		g.phase_clock=0.0
		g.encounter_time=0.0
		g.boss_spawned=true
		defeat_clock=-1.0
		group_ids=g.world.jefes.duplicate()
		if int(g.profile.world)==14:
			group_ids=g.world.sectores_jefes[clampi(int(g.profile.lab_boss),0,3)].jefes.duplicate()
		for n in range(group_ids.size()):
			spawn(g,str(group_ids[n]),false,n,group_ids.size())
	if g.state=="boss":
		g.encounter_time+=dt
	var active_boss_count=0
	for e in g.enemies:
		if e.get("boss",false) and e.hp>0:
			active_boss_count+=1
	for e in g.enemies:
		if not e.get("boss",false) and not e.get("mini",false):
			continue
		if e.hp<=0:
			continue
		e.armor_open=maxf(0,float(e.get("armor_open",0))-dt)
		e.slow_left=maxf(0,float(e.get("slow_left",0))-dt)
		if e.entry>0:
			e.entry=maxf(0,e.entry-dt)
			continue
		e.alive_time+=dt
		if e.lock>0:
			e.lock=maxf(0,e.lock-dt)
			continue
		var fury=1.0
		if int(g.profile.world)==8:
			fury=pow(1.25,3-active_boss_count)
		elif int(g.profile.world)==13 and e.config.arquetipo=="hadalsovereign":
			var riftia_alive=false
			for other in g.enemies:
				if other.get("boss",false) and other.config.arquetipo=="riftia" and other.hp>0:
					riftia_alive=true
			if not riftia_alive:
				fury=1.3
		e.fury_multiplier=fury
		var local_dt=dt*(float(e.slow_factor) if e.slow_left>0 else 1.0)
		var context={"player":g.player.pos,"time":g.total_time,"width":640.0,"height":336.0,"bullet_speed":g.stage_system.bullet_speed(g) if g.stage_system!=null else 90.0,"survivors":active_boss_count,"partner_dead":fury>1.0}
		var actions=Patterns.step(e,context,local_dt)
		for action in actions:
			match str(action.kind):
				"bullet":
					var options:Dictionary=action.duplicate(true)
					options.erase("kind")
					options.erase("pos")
					options.erase("velocity")
					options["source"]=str(e.name)
					options["boss"]=true
					options["homing"]=float(action.get("homing",0))>0
					var slow=float(action.get("slow",1.0))
					options["slow"]=float(action.get("slow_duration",1.0)) if slow<1.0 else 0.0
					options["slow_factor"]=slow
					g.enemy_bullet(action.pos,action.velocity,options)
				"hazard":
					action["boss"]=true
					action["owner"]=e.uid
					action["name"]=str(e.name)
					g.hazards.append(action)
				"spawn":
					if g.stage_system!=null:
						g.stage_system.spawn_enemy(g,str(action.enemy),action.pos,-1,{"summoned":true})
				"notice":
					g.set_notice(str(action.text),1.0)
	if g.state=="boss" and active_boss_count==0 and g.boss_spawned:
		if defeat_clock<0:
			defeat_clock=float(g.data.combat.timings.boss_defeat)
			g.clear_enemy_bullets(false)
			g.hazards.clear()
			g.effects.append({"kind":"explosion","pos":Vector2(480,168),"ttl":defeat_clock})
		defeat_clock-=dt
		if defeat_clock<=0:
			g.finish_encounter()
			defeat_clock=-1.0

func damage(g,e:Dictionary,amount:float,hit_pos:Vector2,bomb:bool=false):
	var multiplier=float(g.data.combat.boss.bomb_multiplier) if bomb else float(g.data.combat.boss.body_multiplier)
	var relative=hit_pos-(e.pos-e.size/2)
	var weak=false
	for segment in e.config.segmentos:
		var box=segment.hitbox
		if Rect2(box[0],box[1],box[2],box[3]).has_point(relative):
			if not bomb:
				multiplier=float(segment.mult_dano)
			weak=bool(segment.debil)
			break
	if e.flags.has("weak_points"):
		for point in e.flags.weak_points:
			if point.distance_to(hit_pos)<16:
				weak=true
				if not bomb:multiplier=float(g.data.combat.boss.weak_multiplier)
	if e.flags.get("armor",false) and e.armor_open<=0 and not bomb:
		multiplier=minf(multiplier,float(g.data.combat.boss.body_multiplier))
	if e.flags.has("weak_exposed") and not e.flags.weak_exposed and e.armor_open<=0 and not bomb:
		multiplier=minf(multiplier,float(g.data.combat.boss.body_multiplier))
	if weak:
		g.player.grapple=0
		for h in g.hazards:
			if h.get("owner","")==e.uid and h.get("release_on_weak_hit",false):
				h.duration=0
	var new_hp=maxf(0,e.hp-amount*multiplier)
	var phases:Array=e.config.fases
	var phase_index=int(e.phase)-1
	if phase_index<phases.size()-1:
		var threshold=float(phases[phase_index].hasta_pct)/100.0*float(e.max_hp)
		if new_hp<=threshold:
			e.hp=threshold
			e.phase+=1
			e.lock=float(g.data.combat.timings.phase_invulnerability)
			e.attack_clock=0.0
			g.clear_enemy_bullets(true,e.uid,int(e.phase))
			g.set_notice("FASE %d"%e.phase,1.0)
			return
	e.hp=new_hp
	e.flash=0.04
	if e.hp<=0:
		g.kill_enemy(e)
		g.clear_enemy_bullets(false)
		if e.mini:
			g.mini_defeated=true
			g.make_checkpoint()
			var weapon="rojo"
			if g.profile.weapons.missile<g.profile.weapons.shot:weapon="verde"
			if g.profile.weapons.bomb<mini(int(g.profile.weapons.shot),int(g.profile.weapons.missile)):weapon="azul"
			g.spawn_drop(weapon,e.pos,"miniboss")
