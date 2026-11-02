extends SceneTree
func check(value:bool,label:String):
	if not value:
		printerr("SONAR FAIL: ",label)
		quit(1)
		return false
	return true
func _initialize():
	var script=load("res://src/equipment/sonar.gd")
	if script==null:
		print("SONAR FAIL: missing implementation")
		quit(1);return
	var Game=load("res://src/core/game.gd")
	var Shop=load("res://src/shop/shop.gd")
	var g=Game.new();g.start(Shop.create_profile())
	var sonar=script.new(g.data.combat.sonar)
	var profile_before=g.profile.duplicate(true)
	if not check(sonar.activate(g.profile,g.player.pos),"initial Q sonar installed"):return
	if not check(g.profile==profile_before,"activation never writes profile"):return
	if not check(is_equal_approx(sonar.cooldown,12.0) and sonar.remaining==4.0,"approved timers"):return
	if not check(not sonar.activate(g.profile,g.player.pos),"cannot spam"):return
	if not check(sonar.reveals(g.player.pos+Vector2(30,0)),"nearby detection"):return
	if not check(not sonar.reveals(g.player.pos+Vector2(1000,0)),"range limited"):return
	sonar.advance(0)
	if not check(sonar.cooldown==12,"pause freezes"):return
	sonar.advance(4)
	if not check(sonar.remaining==0 and is_equal_approx(sonar.cooldown,8),"reveal4 / cooldown8"):return
	if not check(not sonar.reveals(g.player.pos),"reveal expires"):return
	sonar.advance(8)
	if not check(sonar.activate(g.profile,g.player.pos),"reusable after12"):return
	var p=Shop.create_profile(true);p.equipment.erase("sonar")
	sonar.reset()
	if not check(not sonar.activate(p,Vector2.ZERO),"not installed"):return
	var control=Game.new();control.start(Shop.create_profile());g.rng.seed=42;control.rng.seed=42
	for frame in range(1200):
		g.step(1.0/60.0,{});control.step(1.0/60.0,{})
		sonar.advance(1.0/60.0)
		if frame%60==0:sonar.activate(g.profile,g.player.pos)
	if not check(g.player.shield==control.player.shield and g.regular_kills==control.regular_kills and g.regular_spawned==control.regular_spawned and g.scroll==control.scroll and g.enemy_bullets.size()==control.enemy_bullets.size(),"no damage, collision, spawn or CTD mutation"):return
	print("SONAR PASS: ownership, Q proposal12/4, cooldown, pause, range, repeat, unchanged real20s combat")
	quit()
