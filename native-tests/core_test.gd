extends SceneTree
const Game = preload("res://src/core/game.gd")
func _initialize():
	var g = Game.new()
	g.start({"world":1,"difficulty":"normal","weapons":{"shot":1,"missile":1,"bomb":1},"credits":0,"upgrades":{},"equipment":{"sonar":true},"bombs":2,"deaths":{},"time":0,"cleared":[],"seed":123,"lab_boss":0,"edition":"normal"})
	assert(g.player.shield == 100)
	var start = g.player.pos
	g.step(1.0,{"move":Vector2.RIGHT})
	assert(is_equal_approx(g.player.pos.x-start.x,160.0))
	g.player.pos=Vector2(2,2)
	g.step(1.0,{"move":Vector2(-1,-1)})
	assert(g.player.pos.x>=5 and g.player.pos.y>=3)
	g.damage_player(10,"test")
	assert(g.player.shield == 90)
	g.damage_player(10,"test")
	assert(g.player.shield == 90,"damage invulnerability")
	for n in range(220):
		g.enemy_bullet(Vector2(400,100),Vector2.LEFT*90)
	assert(g.enemy_bullets.size()<=200)
	print("CORE TESTS PASS")
	quit()
