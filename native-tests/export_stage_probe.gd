extends SceneTree
## Run from the source AND against an exported pack/Windows executable.
## No enemy injection, invulnerability, artificial damage or timer changes.
const Game=preload("res://src/core/game.gd")
const Shop=preload("res://src/shop/shop.gd")

func snapshot(g,elapsed:float)->Dictionary:
	return {"elapsed":elapsed,"state":g.state,"world_time":g.world_time,"scroll":g.scroll,"enemies":g.enemies.size(),"stage_system":g.stage_system!=null,"weapon_system":g.weapon_system!=null,"boss_system":g.boss_system!=null,"regular_spawned":g.regular_spawned,"regular_kills":g.regular_kills}

func _initialize():
	var sandbox=OS.has_feature("pruebas") or OS.get_cmdline_user_args().has("--pruebas")
	var resources={}
	for path in ["res://src/stages/stages.gd","res://src/weapons/weapons.gd","res://src/bosses/bosses.gd","res://src/shop/shop.gd"]:
		resources[path]={"file_access":FileAccess.file_exists(path),"resource_loader":ResourceLoader.exists(path),"loaded":ResourceLoader.load(path)!=null}
	var g=Game.new()
	g.start(Shop.create_profile(sandbox))
	var samples=[snapshot(g,0)]
	var first_spawn=-1.0
	var first_pos=Vector2.ZERO
	var first_uid=""
	var distance=0.0
	var max_enemy_bullets=0
	for frame in range(1,1202):
		var elapsed=float(frame)/60.0
		var move=Vector2.ZERO
		if elapsed>=13:
			for enemy in g.enemies:
				if enemy.hp>0 and enemy.pos.x>g.player.pos.x+24:
					var delta=enemy.pos.y-g.player.pos.y
					move.y=clampf(delta/(160.0/60.0),-1.0,1.0)
					break
		g.step(1.0/60.0,{"move":move,"fire":elapsed>=13})
		max_enemy_bullets=maxi(max_enemy_bullets,g.enemy_bullets.size())
		if first_spawn<0 and g.regular_spawned>0:
			first_spawn=g.world_time
			first_pos=g.enemies[0].pos
			first_uid=g.enemies[0].uid
		for enemy in g.enemies:
			if enemy.uid==first_uid:distance=maxf(distance,first_pos.distance_to(enemy.pos))
		if frame in [300,720,1200]:samples.append(snapshot(g,elapsed))
	var controllers=g.stage_system!=null and g.weapon_system!=null and g.boss_system!=null
	var pass_stage=controllers and g.world_time>=20 and g.scroll>=1200 and first_spawn>=10 and first_spawn<10.02 and distance>60 and max_enemy_bullets>0 and g.regular_kills>0
	var paid=Shop.create_profile(sandbox)
	paid.upgrades.escudo_max=1
	paid.upgrades.dano=1
	var purchased=Game.new()
	purchased.start(paid)
	var pass_shop=purchased.stats==Shop.stats(paid) and purchased.stats.max_shield==120
	var report={"os":OS.get_name(),"executable":OS.get_executable_path(),"edition":"pruebas" if sandbox else "normal","resources":resources,"samples":samples,"first_wave_time":first_spawn,"enemy_distance":distance,"peak_enemy_bullets":max_enemy_bullets,"kills":g.regular_kills,"shield":g.player.shield,"shop_stats_match":pass_shop,"passed":pass_stage and pass_shop}
	print("EXPORT_STAGE_REPORT ",JSON.stringify(report))
	print("EXPORT_STAGE_", "PASS" if report.passed else "FAIL")
	quit(0 if report.passed else 1)
