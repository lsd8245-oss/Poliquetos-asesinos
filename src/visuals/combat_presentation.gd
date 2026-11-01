class_name PoliCombatPresentation
extends RefCounted
## Visual state only: never writes simulation, profiles or collision dictionaries.
var bank=0.0
var muzzle=0.0
var last_pos=Vector2.ZERO
var last_shot=0.0
var last_credits=-1
var initialized=false
var hits:Array=[]
var health:Dictionary={}
var collection=0.0

static func bullet_visual(b:Dictionary,kind:String)->Dictionary:
	var core:Vector2=b.get("size",Vector2(8,4))
	var halo=Vector2(4,2) if kind in ["shot","laser","missile"] else Vector2(2,2)
	var angle=b.get("velocity",Vector2.RIGHT).angle()
	# Collision boxes remain axis-aligned. Limit the visual bank of elongated
	# torpedoes; full rotation would create an invisible horizontal hit region.
	var facing=PI if absf(angle)>PI/2 else 0.0
	var bank=wrapf(angle-facing,-PI,PI)
	var render_angle=facing+clampf(bank,-0.12,0.12) if core.x!=core.y else angle
	return {"size":core+halo,"angle":angle,"render_angle":render_angle,"key":"w01_bullet_%s_move"%kind}

static func effect_time(remaining:float,duration:float,frames:int=8,fps:float=16.0)->float:
	return clampf(1.0-remaining/maxf(duration,0.001),0,1)*float(frames)/fps

func reset():
	initialized=false
	health.clear()
	hits.clear()
	muzzle=0.0
	collection=0.0
	bank=0.0

func step(g,dt:float):
	muzzle=maxf(0,muzzle-dt)
	collection=maxf(0,collection-dt)
	for i in range(hits.size()-1,-1,-1):
		hits[i].ttl-=dt
		if hits[i].ttl<=0:hits.remove_at(i)
	if initialized:
		var dy=g.player.pos.y-last_pos.y
		bank=lerpf(bank,clampf(dy*0.025,-0.13,0.13),minf(1,dt*18))
		if g.shot_clock>last_shot+0.01:muzzle=0.08
		if int(g.profile.credits)>last_credits:collection=0.3
	var next={}
	for enemy in g.enemies:
		var id=str(enemy.get("uid",enemy.get("id","")))
		if health.has(id) and enemy.hp>0 and enemy.hp<float(health[id]):
			hits.append({"pos":enemy.pos,"ttl":0.18})
		next[id]=enemy.hp
	health=next
	last_shot=g.shot_clock
	last_pos=g.player.pos
	last_credits=int(g.profile.credits)
	initialized=true
