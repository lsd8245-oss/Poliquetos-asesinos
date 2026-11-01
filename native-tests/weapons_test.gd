extends SceneTree
const Game=preload("res://src/core/game.gd")
const Shop=preload("res://src/shop/shop.gd")
func _initialize():
	var g=Game.new()
	var p=Shop.create_profile()
	g.start(p)
	for level in range(1,9):
		p.weapons.shot=level
		g.bullets.clear()
		g.shoot_primary()
		var row=g.data.combat.shot[level-1]
		var sum=0.0
		for b in g.bullets:sum+=b.damage
		assert(is_equal_approx(sum/float(row.interval),float(row.dps)),"Shot DPS level%d"%level)
		p.weapons.missile=level
		g.bullets.clear()
		g.weapon_system.fire_missiles(g)
		sum=0
		for b in g.bullets:sum+=b.damage
		assert(is_equal_approx(sum,float(g.data.combat.missile[level-1].dps)))
	p.bombs=2
	for n in range(20):g.enemy_bullet(g.player.pos,Vector2.ZERO)
	assert(g.weapon_system.bomb(g))
	assert(g.enemy_bullets.is_empty())
	assert(not g.weapon_system.bomb(g))
	assert(p.bombs==1)
	p.weapons.shot=8
	g.collect_drop({"uid":"max-test","kind":"rojo","value":0})
	assert(p.credits==100)
	g.collect_drop({"uid":"max-test","kind":"rojo","value":0})
	assert(p.credits==100,"No duplicated checkpoint drop")
	g.profile.world_entry_weapons={"shot":2,"missile":1,"bomb":3}
	g.profile.entry_world=1
	g.profile.weapons={"shot":8,"missile":8,"bomb":8}
	g.retry()
	assert(g.profile.weapons.shot==2)
	assert(g.profile.weapons.bomb==3)
	g.profile.upgrades.misiles=3
	g.profile.weapons.missile=1
	g.refresh_stats()
	g.collect_drop({"uid":"floor-test","kind":"verde","value":0})
	assert(g.profile.weapons.missile==5,"Green bubble upgrades effective purchased floor4 to5")
	print("WEAPONS TESTS PASS: 16 DPS tables, bombs, max items, dedup, checkpoint weapon reset")
	quit()
