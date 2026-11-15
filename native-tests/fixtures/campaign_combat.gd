extends RefCounted
## Synthetic test utility, NEVER a human playthrough or no-cheat video.
## Aim/survival are isolated. Boss HP is only reduced by production projectiles,
## with actual entry, phase locks and defeat delay. No forced boss victory.
static func enter_final(g):
	g.world_time=float(g.world.alerta_jefe_seg)
	g.state="alert";g.phase_clock=float(g.data.combat.timings.alert)
	g.boss_system.step(g,0)
	assert(g.state=="boss" and g.boss_spawn_count>0,"configured final encounter actually spawned")
static func defeat(g,max_seconds:float=2400.0)->bool:
	var seconds=0.0
	while g.state=="boss" and seconds<max_seconds:
		var target={}
		for e in g.enemies:
			if e.get("boss",false) and e.hp>0 and not e.get("inactive",false):target=e;break
		if not target.is_empty():
			var rectangles=g.enemy_hit_rects(target)
			if not rectangles.is_empty():g.player.pos=rectangles[0].get_center()-Vector2(40,0)
		g.invulnerability=1.0
		g.step(1.0/30.0,{"fire":true})
		# Survival/audio are outside this fixture's contract, not simulated proof.
		g.clear_enemy_bullets(false);g.sound_events.clear()
		seconds+=1.0/30.0
	return g.state=="results"
