extends SceneTree

const Stages = preload("res://src/stages/stages.gd")

class HazardContext:
	extends RefCounted
	var data:Dictionary
	var hazards:Array=[]
	var rng=RandomNumberGenerator.new()
	var world_time:float=0

func _initialize():
	var context=HazardContext.new()
	context.data={"combat":JSON.parse_string(FileAccess.get_file_as_string("res://data/combat.json"))}
	context.rng.seed=123
	var stages=Stages.new()
	var configs:Dictionary=context.data.combat.hazards
	assert(configs.laseres.cycle==3 and configs.compuertas.cycle==4,"Documented cycles")
	for id in ["boyas","cascos","conchas","rocas","corriente_marea","kelp","corales","corriente_hojas","raices","barriles","petroleo","medusas","icebergs","granizo","costillas","geiseres","lava","laseres","compuertas","cintas","torretas","escombros","corrientes"]:
		assert(configs.has(id),"Explicit hazard config missing: "+id)
		stages.spawn_hazard(context,{"id":id,"y":100,"duracion_seg":17})
		var hazard:Dictionary=context.hazards.back()
		assert(hazard.rect.size==Vector2(configs[id].width,configs[id].height),"Data geometry: "+id)
		assert(hazard.duration==17,"Event lifetime must survive pulse settings: "+id)
		assert(hazard.damage==configs[id].damage,"Data damage: "+id)
		assert(hazard.age==0,"Initial cycle age: "+id)
		if configs[id].anchor_y=="bottom":
			assert(hazard.rect.end.y==float(context.data.combat.screen.play_height))
		elif configs[id].anchor_y=="top":
			assert(hazard.rect.position.y==0)
	# Nondefault live edits prove that mechanics read data, rather than mirror doc constants.
	configs.laseres.merge({"width":41,"height":92,"damage":7,"telegraph":0.23,"cycle":6.2,"active_duration":0.8,"duration":19},true)
	stages.spawn_hazard(context,{"id":"laseres"})
	var laser:Dictionary=context.hazards.back()
	assert(laser.rect.size==Vector2(41,92))
	assert(laser.damage==7 and laser.delay==0.23 and laser.telegraph==0.23)
	assert(laser.cycle==6.2 and laser.active_duration==0.8 and laser.duration==19)
	configs.kelp.slow=0.42
	stages.spawn_hazard(context,{"id":"kelp"})
	assert(is_equal_approx(context.hazards.back().slow,0.58),"Slow config is reduction")
	stages.spawn_hazard(context,{"id":"petroleo"})
	assert(is_equal_approx(context.hazards.back().slow,1.0-float(configs.petroleo.slow)))
	configs.corriente_hojas.push_x=-47
	configs.corriente_hojas.push_y=9
	stages.spawn_hazard(context,{"id":"corriente_hojas"})
	assert(context.hazards.back().direction==Vector2(-47,9))
	configs.barriles.blast_radius=109
	configs.barriles.enemy_damage=71
	stages.spawn_hazard(context,{"id":"barriles"})
	var barrel:Dictionary=context.hazards.back()
	assert(barrel.explosive and barrel.blast_radius==109 and barrel.enemy_damage==71)
	assert(context.data.combat.items.pickup_radius==18)
	assert(context.data.combat.ui.ending_seconds==4 and context.data.combat.ui.credits_seconds==8)
	var enemies:Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/enemies.json"))
	for enemy in enemies:
		if enemy.get("robot_codigo","")=="R6":
			assert(enemy.parametros.carcasa_periodo_seg==5)
	print("HAZARD DATA TESTS PASS")
	quit()
