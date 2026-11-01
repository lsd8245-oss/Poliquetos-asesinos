extends Node2D
## Native bitmap UI. Every visible element is composed from the PNG asset pack.
const Sound=preload("res://src/audio/audio.gd")
const Assets = preload("res://src/core/assets.gd")
const Game = preload("res://src/core/game.gd")
const Shop = preload("res://src/shop/shop.gd")
const Save = preload("res://src/save/saves.gd")
const TIPS = [
	"Las bombas limpian balas.", "Los misiles se disparan automáticamente.",
	"Mueve la nave en pasos cortos entre proyectiles.", "Observa la señal antes de cada ataque del jefe.",
	"Las compras se conservan al reintentar.", "Las monedas recogidas se conservan al morir.",
	"El punto de control evita repetir todo el mundo.", "Visita la tienda entre mundos.",
	"El sonar viene instalado desde el principio.", "El astillero cambia el aspecto de tu nave.",
	"Las skins se desbloquean con logros.", "Puedes reasignar teclas y mando en Opciones.",
	"El disparo automático se activa en Opciones.", "Rejugar mundos conserva el progreso de campaña.",
	"Prueba otra ruta si te rodean los enemigos.", "Puedes reducir los destellos en Opciones.",
	"Vigila la barra de escudo en la parte inferior.", "Las marcas de progreso indican los encuentros.",
	"Estudia los huecos antes de avanzar.", "La pausa permite cambiar los controles."
]
const PALETTE = ["#75c9df", "#d7ffed", "#4a9cff", "#ffce58", "#ff7384", "#c28fff", "#ffffff", "#42637d"]
var audio
var assets
var game
var sandbox = false
var screen = "splash"
var buttons: Array = []
var selected = 0
var heading = ""
var lines: Array = []
var message = ""
var message_time = 0.0
var clock = 0.0
var options: Dictionary = {}
var return_screen = "title"
var slot_mode = "load"
var difficulty = "normal"
var active_slot = 1
var hitboxes = false
var confirm_action = ""
var confirm_return = "title"
var shop_visit: Dictionary = {}
var shop_page = 0
var shop_item = ""
var shop_rows: Array = []
var result_clock = 0.0
var ending_clock=0.0
var credits_clock=0.0
var finish_sequence=false
var last_state = ""
var pending_bomb = false
var remap_action = ""
var remap_kind = "key"
var sandbox_world = 1
var sandbox_lab = 0
var sandbox_weapons = {"shot": 1, "missile": 1, "bomb": 1}
var intro_clock = 0.0
var smoke_frames = 0
var import_dialog: FileDialog
var runtime_trace=false
var runtime_trace_index=0
var runtime_trace_start=0.0

func _ready():
	sandbox = OS.has_feature("pruebas") or OS.get_cmdline_user_args().has("--pruebas")
	runtime_trace=OS.get_cmdline_user_args().has("--runtime-trace")
	if runtime_trace:ProjectSettings.set_setting("application/run/flush_stdout_on_print",true)
	audio=Sound.new()
	add_child(audio)
	assets = Assets.new()
	assets.load_all()
	game = Game.new()
	if OS.get_cmdline_user_args().has("--verify-export"):
		set_process(false)
		var p=Shop.create_profile(sandbox)
		game.start(p)
		var ok=game.data.worlds.size()==14 and game.player.shield==100 and game.enemies.is_empty() and assets.has_sprite("w14_boss_boss_w14_eunice_titan_move")
		ok=ok and p.equipment.size()==1 and p.equipment.get("sonar",false)
		ok=ok and int(p.credits)==(999999999 if sandbox else 0)
		ok=ok and game.stage_system!=null and game.weapon_system!=null and game.boss_system!=null
		# A loaded scene alone cannot prove an exported campaign is running.
		for frame in range(1201):game.step(1.0/60.0,{})
		ok=ok and game.world_time>=20.0 and game.scroll>=1200.0 and game.regular_spawned>=4 and not game.enemies.is_empty()
		var probe=FileAccess.open("user://export-verification.tmp",FileAccess.WRITE)
		ok=ok and probe!=null
		if probe!=null:
			probe.store_string("ok")
			probe.close()
			DirAccess.remove_absolute("user://export-verification.tmp")
		print("EXPORT_VERIFY_", "PASS" if ok else "FAIL", " edition=", "pruebas" if sandbox else "normal", " worlds=", game.data.worlds.size(), " shield=", game.player.shield, " world_time=",game.world_time," scroll=",game.scroll," spawned=",game.regular_spawned," controllers=",game.stage_system!=null and game.weapon_system!=null and game.boss_system!=null)
		get_tree().quit(0 if ok else 1)
		return
	options = Save.default_options()
	var loaded = Save.load_options(sandbox)
	for key in loaded.options:
		options[key] = loaded.options[key]
	hitboxes = bool(options.get("show_hitbox", false))
	_apply_options()
	_show("splash")

func _apply_options():
	audio.configure(options)
	if DisplayServer.get_name() == "headless":
		return
	var mode = str(options.get("screen", "window2"))
	if mode == "fullscreen":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var factor = int(mode.trim_prefix("window"))
		DisplayServer.window_set_size(Vector2i(640, 360) * clampi(factor, 1, 3))

func _save_options():
	options.show_hitbox = hitboxes
	var result = Save.save_options(options, sandbox)
	if not result.ok:
		_toast("No se guardaron las opciones: " + _friendly_error(str(result.error)))
	_apply_options()

func _toast(text: String):
	message = text
	message_time = 5.0

func _button(label: String, action: String, rect = Rect2()):
	if rect.size == Vector2.ZERO:
		rect = Rect2(54, 82 + buttons.size() * 22, 290, 19)
	buttons.append({"label": label, "action": action, "rect": rect})

func _show(next: String):
	if screen == "shop" and next != "shop" and not shop_visit.is_empty():
		Shop.close_visit(shop_visit)
		shop_visit = {}
	screen = next
	selected = 0
	buttons.clear()
	lines.clear()
	heading = "POLIQUETOS ASESINOS"
	match screen:
		"splash":
			pass
		"title":
			_button("Nueva partida", "new")
			_button("Continuar", "load")
			_button("Opciones", "options")
			_button("Créditos", "credits")
			_button("Salir", "quit")
			if sandbox:
				_button("PRUEBAS: elegir mundo / armas", "sandbox")
			for button in buttons:
				button.rect.position+=Vector2(-26,30)
				button.rect.size.x=246
		"new":
			heading = "NUEVA PARTIDA / DIFICULTAD"
			_button("Fácil", "difficulty:easy")
			_button("Normal", "difficulty:normal")
			_button("Difícil", "difficulty:hard")
			_button("Volver", "title")
		"slots":
			heading = "NUEVA PARTIDA" if slot_mode == "new" else "CONTINUAR"
			for slot in range(1, 4):
				var saved = Save.load_slot(slot, sandbox)
				var summary = "vacía"
				if saved.ok:
					summary = "M%d / %s / %d monedas" % [saved.profile.world, _difficulty_name(saved.profile.difficulty), saved.profile.credits]
				elif saved.error != "slot_empty":
					summary = "archivo dañado: copia de respaldo si existe"
				_button("Ranura %d: %s" % [slot, summary], "slot:%d" % slot, Rect2(40, 82 + (slot - 1) * 32, 550, 26))
			_button("Volver", "title", Rect2(40, 202, 220, 22))
		"options":
			heading = "OPCIONES"
			for key in ["master", "music", "effects"]:
				var label = {"master":"Volumen general", "music":"Música", "effects":"Efectos"}[key]
				_button("%s: %d / 10" % [label, options[key]], "option:" + key)
			_button("Pantalla: " + ("Pantalla completa" if options.screen=="fullscreen" else "Ventana x"+str(options.screen).trim_prefix("window")), "option:screen")
			_button("Disparo automático: " + _yes(options.autofire), "option:autofire")
			_button("Temblor: " + _yes(options.shake), "option:shake")
			_button("Reducir destellos: " + _yes(options.reduce_flashes), "option:reduce_flashes")
			_button("Teclado y mando", "controls")
			if return_screen == "rest":
				_button("Dificultad: " + _difficulty_name(game.profile.difficulty), "change_difficulty")
			_button("Volver", "options_back")
			lines = ["Izquierda / derecha: ajustar; Enter / A: cambiar", "F3: mostrar hitboxes | Música pendiente"]
		"controls":
			heading = "REASIGNAR CONTROLES"
			for action in ["left", "right", "up", "down", "fire", "bomb", "pause"]:
				var names = {"left":"Izquierda", "right":"Derecha", "up":"Arriba", "down":"Abajo", "fire":"Disparo", "bomb":"Bomba", "pause":"Pausa"}
				var row = buttons.size()
				_button(names[action] + ": " + _binding_name(action, "key"), "bind:key:" + action, Rect2(35, 82 + row * 25, 275, 21))
				_button("Mando: " + _binding_name(action, "joy"), "bind:joy:" + action, Rect2(325, 82 + row * 25, 280, 21))
				# Two controls share the same visual row.
				buttons[-1].rect.position.y = 82 + (row / 2) * 25
				buttons[-2].rect.position.y = buttons[-1].rect.position.y
			_button("Restaurar controles", "reset_bindings", Rect2(35, 280, 275, 21))
			_button("Volver", "options", Rect2(325, 280, 280, 21))
			lines = ["Selecciona una acción y pulsa la nueva tecla o botón.", "Esc cancela. El stick izquierdo también mueve la nave."]
		"ending":
			heading="HAS ESCAPADO"
			ending_clock=0.0
			_button("Continuar a créditos","ending_skip",Rect2(200,292,260,22))
		"credits":
			credits_clock=0.0
			heading = "CRÉDITOS"
			lines = ["POLIQUETOS ASESINOS", "Campaña marina / edición nativa de Windows", "Motor Godot 4.6 · Gráficos PNG y fuente bitmap", "Arte provisional identificado; música pendiente.", "Diseño y proyecto: Poliquetos Asesinos"]
			_button("Volver", "credits_back", Rect2(54, 230, 290, 22))
		"pause":
			heading = "PAUSA"
			_button("Continuar", "resume")
			_button("Opciones", "options")
			_button("Reiniciar punto de control", "restart")
			_button("Salir al título", "leave")
		"confirm":
			heading = "CONFIRMAR"
			lines = ["¿" + confirm_action + "?"]
			_button("Cancelar", "cancel_confirm", Rect2(54, 132, 250, 24))
			_button("Confirmar", "accept_confirm", Rect2(330, 132, 250, 24))
		"rest":
			game.profile.resume = "rest"
			var saved = Save.save_slot(active_slot, game.profile)
			_toast("Guardado automático: ranura %d" % active_slot if saved.ok else "Error de guardado: " + _friendly_error(str(saved.error)))
			heading = "DESCANSO / ACTO %d / MUNDO %d" % [int(game.world.get("acto", 4)), int(game.profile.world)]
			lines = ["%d monedas | Tiempo %s | Muertes %d" % [game.profile.credits, _time(game.total_time), _deaths()]]
			for pair in [["Tienda", "shop"], ["Astillero", "shipyard"], ["Skins", "skins"], ["Guardar", "save"], ["Rejugar mundo", "replay"], ["Siguiente mundo", "next"], ["Opciones", "options"], ["Salir al título", "leave"]]:
				_button(pair[0], pair[1])
			if sandbox:
				_button("PRUEBAS: mundo / armas", "sandbox")
		"shop":
			heading = "TIENDA / %d MONEDAS" % int(game.profile.credits)
			if shop_visit.is_empty():
				shop_visit = Shop.visit()
			shop_rows.clear()
			for kind in ["mejoras", "equipo"]:
				for row in Shop.catalog()[kind]:
					shop_rows.append({"id": ("upgrade:" if kind == "mejoras" else "gear:") + row.id, "data": row})
			var first = shop_page * 7
			for index in range(first, mini(first + 7, shop_rows.size())):
				var row = shop_rows[index]
				_button(str(row.data.nombre), "inspect:" + row.id, Rect2(24, 82 + (index - first) * 23, 250, 20))
			_button("Página anterior", "shop_prev", Rect2(24, 252, 125, 20))
			_button("Siguiente", "shop_next", Rect2(154, 252, 120, 20))
			_button("Volver al descanso", "rest", Rect2(24, 286, 250, 22))
			if shop_item.is_empty() and not shop_rows.is_empty():
				shop_item = shop_rows[first].id
			_button("Comprar rango / equipo", "buy", Rect2(300, 232, 310, 24))
			_button("Reembolsar compra de esta visita", "refund", Rect2(300, 266, 310, 24))
		"shipyard":
			heading = "ASTILLERO / PERSONALIZACIÓN VISUAL"
			for zone in ["hull", "lights", "trail"]:
				_button({"hull":"Casco", "lights":"Luces", "trail":"Estela"}[zone] + ": " + str(game.profile.colors[zone]), "color:" + zone)
			_button("Volver", "rest")
			lines = ["Solo cambia la apariencia. Equipo instalado:", _equipment_names()]
		"skins":
			heading = "SKINS / LOGROS Y OBJETOS DE JEFE"
			for row in Shop.cosmetics():
				var unlocked = row.id in game.profile.skins
				_button(str(row.nombre) + (" *" if game.profile.skin == row.id else "") + ("" if unlocked else " [bloqueada]"), "skin:" + row.id)
			_button("Volver", "rest")
		"save":
			heading = "GUARDAR / IMPORTAR / EXPORTAR JSON"
			lines = ["Los archivos y su copia .bak están en la carpeta de usuario.", "Exportar crea export_slot_N.json; importar valida la edición."]
			for slot in range(1, 4):
				for col in range(3):
					var action = ["manual", "export", "import"][col]
					_button(["Guardar", "Exportar", "Importar"][col] + " %d" % slot, "%s:%d" % [action, slot], Rect2(30 + col * 195, 105 + (slot - 1) * 35, 180, 27))
			_button("Abrir carpeta de guardados", "folder", Rect2(30, 230, 375, 24))
			_button("Volver", "rest", Rect2(30, 266, 375, 24))
		"replay":
			heading = "REJUGAR / BUILD ACTUAL / SIN ALTERAR PROGRESO"
			for index in range(game.profile.cleared.size()):
				var world_id = int(game.profile.cleared[index])
				_button("M%d %s" % [world_id, game.world_config(world_id).nombre], "replay:%d" % world_id, Rect2(30 + (index / 8) * 300, 82 + (index % 8) * 25, 285, 22))
			_button("Volver", "rest", Rect2(30, 302, 285, 22))
		"sandbox":
			heading = "PRUEBAS / SELECCIÓN EXPLÍCITA"
			lines = ["Compras pendientes salvo sonar. Sin escudo extra ni invulnerabilidad.", "Izquierda / derecha ajustan mundo, sala y niveles de arma."]
			_button("Mundo: %d / %s" % [sandbox_world, game.world_config(sandbox_world).nombre], "dev_world")
			_button("Laboratorio: encuentro %d de 4" % (sandbox_lab + 1), "dev_lab")
			for weapon in ["shot", "missile", "bomb"]:
				_button("%s: nivel %d" % [{"shot":"Disparo","missile":"Misiles","bomb":"Bombas"}[weapon], sandbox_weapons[weapon]], "dev_weapon:" + weapon)
			_button("Iniciar selección", "dev_start")
			_button("Volver", "dev_back")
		"dead":
			heading = "EL JEFE TE HA DEVORADO" if game.killer_boss else "HAS SIDO DEVORADO"
			var entry = game.profile.get("world_entry_weapons", game.profile.weapons)
			lines = ["Derrotado por: " + str(game.killer), "M%d %s | Muertes: %d" % [game.profile.world, game.world.nombre, int(game.profile.deaths.get(str(game.profile.world), 0))], "Punto de control: " + _time(float(game.checkpoint.get("time", 0))), "Armas al volver: D%d M%d B%d" % [entry.shot, maxi(int(entry.missile), int(game.stats.min_missile)), entry.bomb], TIPS[posmod(int(game.death_streak) + _deaths(), TIPS.size())]]
			_button("Reintentar", "retry", Rect2(54, 175, 290, 24))
			_button("Opciones", "options", Rect2(54, 207, 290, 24))
			_button("Salir al título", "leave", Rect2(54, 239, 290, 24))
			if game.death_streak >= 5 and game.profile.difficulty != "easy":
				_button("¿Probar en dificultad Fácil?", "easy_retry", Rect2(54, 278, 360, 24))
		"results":
			heading = "RESULTADOS"
			_button("Continuar / saltar recuento", "results_skip", Rect2(54, 292, 400, 25))
		"victory":
			heading = "¡LABORATORIO ATRÁS! / CAMPAÑA COMPLETADA"
			var defeated=float(game.profile.get("kills_total",0))
			var encountered=maxf(1,float(game.profile.get("spawned_total",0)))
			lines = ["Tiempo total: " + _time(game.total_time),"Muertes: %d | Monedas totales: %d"%[_deaths(),int(game.profile.get("coins_total",0))],"Escape: %d puntos"%int(game.profile.get("escape_score",0)),"Enemigos derrotados: %d/%d (%.1f%%)"%[int(defeated),int(encountered),100*defeated/encountered],"Gracias por jugar a Poliquetos Asesinos."]
			_button("Rejugar mundo", "replay",Rect2(350,205,250,25))
			_button("Créditos", "credits", Rect2(54, 205, 290, 25))
			_button("Guardar", "save", Rect2(54, 240, 290, 25))
			_button("Volver al título", "title", Rect2(54, 275, 290, 25))
	queue_redraw()

func _difficulty_name(value:String)->String:
	return {"easy":"Fácil","normal":"Normal","hard":"Difícil"}.get(value,"Normal")

func _equipment_names()->String:
	var names=["Sonar"]
	for item in Shop.catalog().equipo:
		if game.profile.equipment.get(item.id,false):names.append(item.nombre)
	return ", ".join(names)

func _friendly_error(code:String)->String:
	var messages={"insufficient_credits":"No tienes monedas suficientes","max_rank":"Has alcanzado el rango máximo","already_owned":"El equipo ya está instalado","act_locked":"Disponible en un acto posterior","not_purchased_this_visit":"Solo se reembolsa lo comprado en esta visita","visit_closed_or_invalid":"La visita a la tienda ha terminado","rank_changed":"Reembolsa primero el último rango","edition_mismatch":"El archivo pertenece a la otra edición","slot_empty":"La ranura está vacía"}
	return messages.get(code,"Datos incompatibles o archivo no disponible")

func _yes(value) -> String:
	return "Sí" if value else "No"

func _time(seconds: float) -> String:
	return "%02d:%02d" % [int(seconds) / 60, int(seconds) % 60]

func _deaths() -> int:
	var total = 0
	for value in game.profile.get("deaths", {}).values():
		total += int(value)
	return total

func _confirm(action: String):
	confirm_return = screen
	confirm_action = action
	_show("confirm")

func _start(profile: Dictionary, loaded: bool = false):
	game.start(profile)
	runtime_trace_index=0
	runtime_trace_start=game.total_time
	active_slot = int(profile.get("slot", 1))
	last_state = ""
	if loaded and profile.get("completed",false):
		game.state="victory"
		_show("victory")
	elif loaded and profile.get("resume", "") == "rest":
		game.state = "rest"
		_show("rest")
	else:
		profile.resume = "playing"
		intro_clock = 2.0
		_show("game")
	_trace_runtime()

func _trace_runtime():
	if not runtime_trace or runtime_trace_index>=4:return
	var targets=[0.0,5.0,12.0,20.0]
	var elapsed=game.total_time-runtime_trace_start
	if elapsed<targets[runtime_trace_index]:return
	print("RUNTIME_STAGE_TRACE ",JSON.stringify({"target_elapsed":targets[runtime_trace_index],"elapsed":elapsed,"state":game.state,"world_time":game.world_time,"scroll":game.scroll,"enemies":game.enemies.size(),"regular_spawned":game.regular_spawned,"regular_kills":game.regular_kills,"enemy_bullets":game.enemy_bullets.size(),"stage_system":game.stage_system!=null,"weapon_system":game.weapon_system!=null,"boss_system":game.boss_system!=null,"edition":"pruebas" if sandbox else "normal","os":OS.get_name()}))
	runtime_trace_index+=1

func _enter_rest():
	game.state = "rest"
	game.profile.resume = "rest"
	_show("rest")

func _activate(action: String, direction: int = 1):
	if audio!=null:audio.play("select")
	if action.begins_with("difficulty:"):
		difficulty = action.get_slice(":", 1)
		slot_mode = "new"
		_show("slots")
	elif action.begins_with("slot:"):
		active_slot = int(action.get_slice(":", 1))
		var saved = Save.load_slot(active_slot, sandbox)
		if slot_mode == "new":
			if saved.ok:
				_confirm("Sobrescribir ranura %d" % active_slot)
			else:
				_new_profile()
		elif saved.ok:
			_start(saved.profile, true)
			if saved.recovered:
				_toast("Archivo dañado. Se recuperó la copia .bak: " + _friendly_error(str(saved.error)))
		else:
			_toast("No se pudo cargar: " + _friendly_error(str(saved.error)))
	elif action.begins_with("option:"):
		var key = action.get_slice(":", 1)
		if key in ["master", "music", "effects"]:
			options[key] = posmod(int(options[key]) + direction, 11)
		elif key == "screen":
			var modes = ["window1", "window2", "window3", "fullscreen"]
			options.screen = modes[posmod(modes.find(options.screen) + direction, 4)]
		else:
			options[key] = not options[key]
		var current = selected
		_save_options()
		_show("options")
		selected = current
	elif action.begins_with("bind:"):
		remap_kind = action.get_slice(":", 1)
		remap_action = action.get_slice(":", 2)
		_toast("Pulsa una tecla" if remap_kind == "key" else "Pulsa un botón de mando")
	elif action.begins_with("inspect:"):
		shop_item = action.trim_prefix("inspect:")
	elif action.begins_with("color:"):
		var zone = action.get_slice(":", 1)
		var index = PALETTE.find(game.profile.colors[zone])
		game.profile.colors[zone] = PALETTE[posmod(index + direction, PALETTE.size())]
		_show("shipyard")
	elif action.begins_with("skin:"):
		var id = action.get_slice(":", 1)
		if id in game.profile.skins:
			game.profile.skin = id
			_show("skins")
		else:
			for skin in Shop.cosmetics():
				if skin.id == id:
					_toast("Desbloqueo: " + str(skin.desbloqueo).replace("_", " "))
	elif action.begins_with("manual:"):
		var slot = int(action.get_slice(":", 1))
		var saved = Save.save_slot(slot, game.profile)
		if saved.ok:
			active_slot = slot
			game.profile.slot = slot
		_toast("Guardado en ranura %d" % slot if saved.ok else "Error: " + _friendly_error(str(saved.error)))
	elif action.begins_with("export:"):
		var slot = int(action.get_slice(":", 1))
		var json = Save.export_slot(slot, sandbox)
		if json.is_empty():
			_toast("La ranura no contiene un guardado válido.")
		else:
			var path = Save.file_path(slot, sandbox).get_base_dir().path_join("export_slot_%d.json" % slot)
			var file = FileAccess.open(path, FileAccess.WRITE)
			if file != null:
				file.store_string(json)
				file.close()
				_toast("Exportado: " + path)
			else:
				_toast("No se pudo escribir el archivo exportado.")
	elif action.begins_with("import:"):
		_open_import(int(action.get_slice(":", 1)))
	elif action.begins_with("replay:"):
		game.profile.resume = "playing"
		game.begin_replay(int(action.get_slice(":", 1)))
		intro_clock = 2.0
		_show("game")
	elif action.begins_with("dev_weapon:"):
		var weapon = action.get_slice(":", 1)
		sandbox_weapons[weapon] = posmod(int(sandbox_weapons[weapon]) - 1 + direction, 8) + 1
		var current = selected
		_show("sandbox")
		selected = current
	else:
		match action:
			"new", "title", "credits", "controls", "rest", "shipyard", "skins", "save", "replay", "shop":
				if action == "credits":
					return_screen = screen
				_show(action)
			"ending_skip":
				finish_sequence=true
				_show("credits")
			"credits_back":
				_show(return_screen)
			"load":
				slot_mode = "load"
				_show("slots")
			"options":
				if screen != "controls":
					return_screen = screen
				_show("options")
			"options_back":
				_save_options()
				_show(return_screen)
			"reset_bindings":
				options.bindings = {}
				_save_options()
				_show("controls")
			"change_difficulty":
				var modes = ["easy", "normal", "hard"]
				game.profile.difficulty = modes[posmod(modes.find(game.profile.difficulty) + direction, 3)]
				_show("options")
			"quit":
				_confirm("Salir del juego")
			"leave":
				_confirm("Salir al título")
			"restart":
				_confirm("Reiniciar punto de control")
			"cancel_confirm":
				_show(confirm_return)
			"accept_confirm":
				if confirm_action == "Salir del juego":
					_quit_game()
				elif confirm_action == "Salir al título":
					_show("title")
				elif confirm_action == "Reiniciar punto de control":
					game.retry()
					_show("game")
				elif confirm_action.begins_with("Sobrescribir"):
					_new_profile()
			"resume":
				game.unpause()
				_show("game")
			"easy_retry", "retry":
				if action == "easy_retry":
					game.profile.difficulty = "easy"
				game.retry()
				_show("game")
			"next":
				game.profile.resume = "playing"
				game.continue_campaign()
				intro_clock = 2.0
				_show("rest" if game.state=="rest" else ("victory" if game.state=="victory" else "game"))
			"results_skip":
				_enter_rest()
			"buy", "refund":
				var result = Shop.purchase(game.profile, shop_item, shop_visit) if action == "buy" else Shop.refund(game.profile, shop_item, shop_visit)
				game.refresh_stats()
				audio.play("buy" if result.ok else "reject")
				_toast("Compra realizada" if result.ok and action == "buy" else ("Reembolso realizado" if result.ok else "No disponible: " + _friendly_error(str(result.error))))
				var current = selected
				_show("shop")
				selected = current
			"shop_prev", "shop_next":
				shop_page = posmod(shop_page + (-1 if action == "shop_prev" else 1), ceili(shop_rows.size() / 7.0))
				_show("shop")
			"folder":
				OS.shell_open(ProjectSettings.globalize_path(Save.file_path(1, sandbox).get_base_dir()))
			"sandbox":
				if sandbox:
					return_screen = screen
					_show("sandbox")
			"dev_back":
				_show(return_screen)
			"dev_world":
				sandbox_world = posmod(sandbox_world - 1 + direction, 15) + 1
				_show("sandbox")
			"dev_lab":
				sandbox_lab = posmod(sandbox_lab + direction, 4)
				_show("sandbox")
				selected = 1
			"dev_start":
				if sandbox:
					var profile = game.profile if not game.profile.is_empty() else Shop.create_profile(true)
					profile.world = sandbox_world
					profile.lab_boss = sandbox_lab if sandbox_world == 14 else 0
					profile.weapons = sandbox_weapons.duplicate(true)
					profile.erase("world_entry_weapons")
					profile.resume = "playing"
					_start(profile)
	queue_redraw()

func _quit_game():
	# Let the audio server release the menu click before closing the engine.
	set_process_input(false)
	var references=[]
	if audio!=null:
		for stream in audio._streams.values():references.append(weakref(stream))
		for player in audio.get_children():
			if player is AudioStreamPlayer:
				player.stop()
				player.stream=null
		audio._streams.clear()
	for attempt in range(100):
		var alive=false
		for reference in references:
			if reference.get_ref()!=null:alive=true
		if not alive:break
		await get_tree().create_timer(0.01).timeout
	get_tree().quit()

func _new_profile():
	var profile = Shop.create_profile(sandbox, difficulty)
	profile.slot = active_slot
	profile.seed=randi()
	_start(profile)
	var saved = Save.save_slot(active_slot, profile)
	if not saved.ok:
		_toast("No se pudo guardar: " + _friendly_error(str(saved.error)))

func _open_import(slot: int):
	if import_dialog != null:
		import_dialog.queue_free()
	import_dialog = FileDialog.new()
	import_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	import_dialog.access = FileDialog.ACCESS_FILESYSTEM
	import_dialog.filters = PackedStringArray(["*.json ; Guardado JSON"])
	import_dialog.title = "Importar ranura %d" % slot
	add_child(import_dialog)
	import_dialog.file_selected.connect(func(path):
		var result = Save.import_slot(slot, FileAccess.get_file_as_string(path), sandbox)
		_toast("Importado en ranura %d" % slot if result.ok else "Importación rechazada: " + _friendly_error(str(result.error)))
	)
	import_dialog.popup_centered(Vector2i(580, 320))

func _binding_name(action: String, kind: String) -> String:
	var value = options.bindings.get(kind + ":" + action, -1)
	if int(value) < 0:
		return "predeterminado"
	return OS.get_keycode_string(int(value)) if kind == "key" else "botón %d" % int(value)

func _held(action: String) -> bool:
	var key = int(options.bindings.get("key:" + action, -1))
	var joy = int(options.bindings.get("joy:" + action, -1))
	var defaults = {"left":[KEY_LEFT, KEY_A], "right":[KEY_RIGHT, KEY_D], "up":[KEY_UP, KEY_W], "down":[KEY_DOWN, KEY_S], "fire":[KEY_Z, KEY_SPACE], "bomb":[KEY_X], "pause":[KEY_ESCAPE, KEY_P]}
	if key >= 0:
		if Input.is_physical_key_pressed(key):
			return true
	else:
		for code in defaults.get(action, []):
			if Input.is_physical_key_pressed(code):
				return true
	var joy_defaults = {"left":JOY_BUTTON_DPAD_LEFT, "right":JOY_BUTTON_DPAD_RIGHT, "up":JOY_BUTTON_DPAD_UP, "down":JOY_BUTTON_DPAD_DOWN, "fire":JOY_BUTTON_A, "bomb":JOY_BUTTON_B, "pause":JOY_BUTTON_START}
	for device in Input.get_connected_joypads():
		if Input.is_joy_button_pressed(device, joy if joy >= 0 else joy_defaults.get(action, JOY_BUTTON_INVALID)):
			return true
	return false

func _event_action(event, action: String) -> bool:
	if event is InputEventKey:
		var custom = int(options.bindings.get("key:" + action, -1))
		if custom >= 0:
			return event.physical_keycode == custom or event.keycode == custom
		return event.keycode in {"fire":[KEY_Z, KEY_SPACE], "bomb":[KEY_X], "pause":[KEY_ESCAPE, KEY_P]}.get(action, [])
	if event is InputEventJoypadButton:
		return event.button_index == int(options.bindings.get("joy:" + action, {"fire":JOY_BUTTON_A, "bomb":JOY_BUTTON_B, "pause":JOY_BUTTON_START}.get(action, -1)))
	return false

func _input(event):
	if import_dialog != null and import_dialog.visible:
		return
	if event is InputEventKey and event.echo:
		return
	if not remap_action.is_empty():
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			remap_action = ""
			_toast("Reasignación cancelada")
		elif (event is InputEventKey and event.pressed and remap_kind == "key") or (event is InputEventJoypadButton and event.pressed and remap_kind == "joy"):
			options.bindings[remap_kind + ":" + remap_action] = event.physical_keycode if remap_kind == "key" else event.button_index
			remap_action = ""
			_save_options()
			_show("controls")
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		hitboxes = not hitboxes
		_save_options()
		return
	if event is InputEventMouseMotion:
		for index in range(buttons.size()):
			if buttons[index].rect.has_point(event.position):
				selected = index
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for index in range(buttons.size()):
			if buttons[index].rect.has_point(event.position):
				selected = index
				_activate(buttons[index].action)
				return
	if not ((event is InputEventKey or event is InputEventJoypadButton) and event.pressed):
		return
	if screen == "splash":
		_show("title")
		return
	if screen == "game":
		if _event_action(event, "pause"):
			game.pause()
			if game.state == "pause":
				_show("pause")
		elif _event_action(event, "bomb"):
			pending_bomb = true
		return
	var key = event.keycode if event is InputEventKey else -1
	var joy = event.button_index if event is InputEventJoypadButton else -1
	if key in [KEY_ESCAPE, KEY_P] or joy == JOY_BUTTON_B:
		_back()
	elif key in [KEY_UP, KEY_W] or joy == JOY_BUTTON_DPAD_UP:
		selected = posmod(selected - 1, maxi(1, buttons.size()))
	elif key in [KEY_DOWN, KEY_S] or joy == JOY_BUTTON_DPAD_DOWN:
		selected = posmod(selected + 1, maxi(1, buttons.size()))
	elif key in [KEY_LEFT, KEY_RIGHT, KEY_A, KEY_D] or joy in [JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT]:
		var direction = -1 if key in [KEY_LEFT, KEY_A] or joy == JOY_BUTTON_DPAD_LEFT else 1
		if not buttons.is_empty():
			var action = str(buttons[selected].action)
			if action.begins_with("option:") or action.begins_with("dev_") or action.begins_with("color:") or action == "change_difficulty":
				_activate(action, direction)
			else:
				selected = posmod(selected + direction, buttons.size())
	elif key in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_Z] or joy in [JOY_BUTTON_A, JOY_BUTTON_START]:
		if not buttons.is_empty():
			_activate(buttons[selected].action)
	queue_redraw()

func _back():
	match screen:
		"pause": _activate("resume")
		"options": _activate("options_back")
		"controls": _show("options")
		"confirm": _show(confirm_return)
		"shop", "shipyard", "skins", "save", "replay": _show("rest")
		"sandbox": _show(return_screen)
		"rest", "dead": _activate("leave")
		"results": _enter_rest()
		"credits": _show(return_screen)
		_: _show("title")

func _process(dt):
	clock += dt
	if audio!=null:audio.consume(game.sound_events)
	message_time = maxf(0, message_time - dt)
	position=Vector2(sin(clock*37),cos(clock*43)) if screen=="game" and int(game.profile.get("world",0))==15 and options.get("shake",true) and not options.get("reduce_flashes",false) else Vector2.ZERO
	if screen == "game":
		if intro_clock > 0:
			intro_clock -= dt
		else:
			var movement = Vector2(float(_held("right")) - float(_held("left")), float(_held("down")) - float(_held("up")))
			for device in Input.get_connected_joypads():
				var stick = Vector2(Input.get_joy_axis(device, JOY_AXIS_LEFT_X), Input.get_joy_axis(device, JOY_AXIS_LEFT_Y))
				if stick.length() > 0.2:
					movement += stick
			game.step(minf(dt, 0.05), {"move": movement.limit_length(), "fire": _held("fire") or options.autofire, "bomb": pending_bomb})
			_trace_runtime()
			pending_bomb = false
		if game.state != last_state:
			last_state = game.state
			match game.state:
				"results":
					result_clock = 0
					_show("results")
				"dead": _show("dead")
				"rest": _enter_rest()
				"victory":
					game.profile.resume = "completed"
					Save.save_slot(active_slot, game.profile)
					finish_sequence=true
					_show("ending")
	elif screen == "ending":
		ending_clock+=dt
		if ending_clock>=float(game.data.combat.ui.ending_seconds):_show("credits")
	elif screen=="credits" and finish_sequence:
		credits_clock+=dt
		if credits_clock>=float(game.data.combat.ui.credits_seconds):
			finish_sequence=false
			_show("victory")
	elif screen == "results":
		result_clock += dt
		if result_clock >= 4.0:
			_enter_rest()
	queue_redraw()
	if OS.get_cmdline_user_args().has("--smoke-test"):
		smoke_frames += 1
		if smoke_frames >= 5:
			get_tree().quit()

func _pixel(rect: Rect2, color: Color):
	assets.sprite(self, "w01_ui_pixel_idle", rect, 0, color)

func _label(value: String, pos: Vector2, color: Color = Color.WHITE, scale: float = 1.0):
	assets.text(self, value, pos, color, scale)

func _draw():
	if assets == null:
		return
	var world_id = int(game.profile.get("world", 1)) if game != null else 1
	if screen=="ending":world_id=1
	var playing = screen in ["game", "pause", "dead", "results", "confirm"] and not game.profile.is_empty()
	if screen in ["splash", "title"] and assets.has_sprite("w01_ui_cover_idle"):
		assets.sprite(self, "w01_ui_cover_idle", Rect2(0,0,640,360))
	else:
		_draw_background(world_id, game.scroll if playing else clock * 10)
	if playing:
		_draw_game(world_id)
	if screen == "game":
		if intro_clock > 0:
			assets.panel(self, Rect2(100, 140, 440, 50))
			_label("MUNDO %d / %s" % [world_id, game.world.nombre], Vector2(115, 159))
		if game.state == "countdown":
			_label(str(ceili(game.resume_clock)), Vector2(308, 148), Color.WHITE, 3)
	elif screen=="ending":
		var fraction=clampf(ending_clock/float(game.data.combat.ui.ending_seconds),0,1)
		_draw_ship(Vector2(320,320-fraction*float(game.data.combat.ui.ending_rise)),Vector2(72,36))
		_label("HAS ESCAPADO",Vector2(244,55),Color.WHITE,2)
		_label("El laboratorio se hunde. El mar vuelve a abrirse.",Vector2(180,87))
	elif screen == "splash":
		assets.sprite(self,"w01_ui_cover_panel_idle",Rect2(12,20,332,178))
		_label("POLIQUETOS", Vector2(30, 45), Color.WHITE, 3)
		_label("ASESINOS", Vector2(30, 80), Color.WHITE, 3)
		if int(clock * 2) % 2 == 0:
			_label("PULSA START / ENTER", Vector2(30, 145))
		_label("EDICIÓN PRUEBAS" if sandbox else "EDICIÓN NORMAL", Vector2(30, 173), Color.CYAN)
	else:
		if screen=="title":
			assets.sprite(self,"w01_ui_cover_panel_idle",Rect2(12,12,278,260))
		else:
			assets.panel(self, Rect2(12,12,616,316))
		if screen=="title":
			_label("POLIQUETOS",Vector2(30,30),Color.WHITE,3)
			_label("ASESINOS",Vector2(30,64),Color(0.65,0.95,0.87),3)
		else:
			_label(heading, Vector2(30,26), Color(0.65,0.92,1))
		for index in range(lines.size()):
			_label(str(lines[index]), Vector2(30, 46 + index * 14))
		if screen == "results":
			_draw_results()
		elif screen == "shop":
			_draw_shop()
		elif screen in ["shipyard", "skins", "rest"]:
			_draw_ship(Vector2(475, 160), Vector2(96, 48))
			if screen == "shipyard":
				_label("Vista previa cosmética", Vector2(408, 204))
		for index in range(buttons.size()):
			var button = buttons[index]
			if screen=="title":
				assets.sprite(self,"w01_ui_cover_button_selected_idle" if index==selected else "w01_ui_cover_button_idle",button.rect)
			else:
				assets.panel(self,button.rect,index==selected)
			_label(button.label, button.rect.position + Vector2(6, (button.rect.size.y - 9) / 2), Color.WHITE if index == selected else Color(0.75, 0.86, 0.9))
		if screen == "title":
			_label("EDICIÓN PRUEBAS" if sandbox else "EDICIÓN NORMAL", Vector2(30, 288), Color.CYAN)
	if message_time > 0:
		assets.panel(self, Rect2(6, 328, 628, 28))
		_label(_wrap(message, 101), Vector2(14, 334), Color(1, 0.88, 0.5))
	if not remap_action.is_empty():
		assets.panel(self, Rect2(100, 135, 440, 70), true)
		_label("Esperando " + ("tecla" if remap_kind == "key" else "botón de mando") + " para: " + remap_action, Vector2(118, 156))
		_label("Esc cancela", Vector2(118, 180))

func _background_tiles(texture_size:Vector2, offset:float, factor:float)->Array:
	var width=maxf(1.0,texture_size.x)
	var first=-fposmod(offset*factor,width)
	var result=[]
	for index in range(int(ceil(640.0/width))+1):
		result.append(Rect2(first+index*width,0,width,336))
	return result

func _draw_background(world_id: int, offset: float):
	var fade=0.0
	if world_id==15 and not game.profile.is_empty():
		var transition=game.data.escape.fondo_transicion
		fade=1.0 if game.profile.get("completed",false) else clampf((game.world_time-float(transition.desde_seg))/float(transition.hasta_seg-transition.desde_seg),0,1)
	for layer in range(1, 5):
		var factors = game.data.combat.get("scroll",{}).get("parallax",[0.1,0.3,0.6,1.0])
		var key = "w%02d_bg_layer%d_idle" % [world_id, layer]
		var texture=assets.get_texture(key,clock)
		if texture!=null:
			for rect in _background_tiles(texture.get_size(),offset,float(factors[layer-1])):
				assets.background_sprite(self,key,rect,clock,Color(1,1,1,1-fade))
		if fade>0:
			var sea="w01_bg_layer%d_idle"%layer
			var sea_texture=assets.get_texture(sea,clock)
			if sea_texture!=null:
				for rect in _background_tiles(sea_texture.get_size(),offset,float(factors[layer-1])):
					assets.background_sprite(self,sea,rect,clock,Color(1,1,1,fade))

func _draw_ship(pos: Vector2, size: Vector2):
	var skin = str(game.profile.get("skin", "original"))
	var colors = game.profile.get("colors", {"hull":"#75c9df", "lights":"#d7ffed", "trail":"#4a9cff"})
	var hull=Color(colors.hull)
	if screen=="game" and game.invulnerability>0 and int(clock*20)%2==0:hull.a=0.35
	assets.sprite(self, "w01_ui_ship_%s_move" % skin, Rect2(pos - size / 2, size), clock, hull)
	_pixel(Rect2(pos + Vector2(size.x * 0.18, -size.y * 0.1), Vector2(size.x * 0.12, size.y * 0.16)), Color(colors.lights))
	assets.sprite(self, "w01_fx_trail_burst", Rect2(pos - Vector2(size.x * 0.65, 4), Vector2(size.x * 0.2, 8)), clock, Color(colors.trail))

func _draw_game(world_id: int):
	if world_id==15 and game.world_time<float(game.data.escape.fondo_transicion.desde_seg):
		_pixel(Rect2(0,0,640,336),Color(0.8,0,0,0.03 if options.reduce_flashes else 0.04+0.06*absf(sin(clock*3))))
	for hazard in game.hazards:
		var rect = hazard.get("rect", Rect2())
		assets.sprite(self, "w01_ui_hazard_idle", rect, clock, Color(1, 0.6, 0.3, 0.22 if hazard.get("delay", 0) > 0 else 0.55))
	for enemy in game.enemies:
		if enemy.get("hidden",false):
			if enemy.get("warning",false):
				assets.sprite(self,"w01_fx_spark_burst",Rect2(enemy.pos.x-12,312,24,24),clock,Color.YELLOW)
			continue
		if float(enemy.get("hp",0))<=0 or enemy.get("inactive",false):continue
		var size = enemy.get("size", Vector2(32, 24))
		var key = "w%02d_enemy_%s_move" % [world_id, enemy.id]
		if enemy.get("boss", false):
			key = "w%02d_boss_%s_move" % [world_id, enemy.id]
		elif enemy.get("mini", false):
			key = "w%02d_mini_%s_move" % [world_id, game.world.get("mini_tipo", enemy.id)]
		var flags = enemy.get("flags", {})
		var tint = Color.WHITE
		if enemy.get("flash",0)>0 and not options.reduce_flashes and assets.has_sprite(key.replace("_move","_hit")):
			key=key.replace("_move","_hit")
		if enemy.get("carrier","")!="":
			var glow={"rojo":Color(1,0.3,0.3),"verde":Color(0.3,1,0.4),"azul":Color(0.3,0.5,1)}.get(enemy.carrier,Color.WHITE)
			assets.sprite(self,"w01_fx_bubble_burst",Rect2(enemy.pos-size*0.6,size*1.2),clock,glow)
		if enemy.get("warning",false):
			assets.sprite(self,"w01_fx_spark_burst",Rect2(enemy.pos-size/2,size),clock,Color.YELLOW)
		if float(enemy.get("lock",0))>0:
			tint.a=0.35 if int(clock*12)%2==0 else 0.8
		tint.a *= float(flags.get("opacity", 0.15 if flags.get("invisible", false) else 1.0))
		if flags.get("screen_effect","")=="sandstorm":
			_pixel(Rect2(0,0,40,336),Color(0.15,0.1,0,0.6))
			_pixel(Rect2(600,0,40,336),Color(0.15,0.1,0,0.6))
		elif flags.get("screen_effect","")=="snow" and not options.reduce_flashes:
			for snow in range(16):
				assets.sprite(self,"w01_fx_spark_burst",Rect2(fmod(snow*41+clock*20,640),fmod(clock*55+snow*27,336),3,3),clock)
		for layer in _enemy_visual_layers(enemy,key):
			assets.sprite(self,layer.key,layer.rect,clock,tint)
		if game.profile.equipment.get("ctd", false) and flags.get("weak_exposed", true):
			for point in flags.get("weak_points", []):
				assets.sprite(self, "w01_fx_spark_burst", Rect2(point - Vector2(6, 6), Vector2(12, 12)), clock, Color.CYAN)
		if hitboxes:
			var rectangles = game.enemy_hit_rects(enemy) if game.has_method("enemy_hit_rects") else [Rect2(enemy.pos - size / 2, size)]
			for rect in rectangles:
				draw_rect(rect, Color.RED, false, 1)
	for bullet in game.bullets:
		var kind = "missile" if bullet.get("missile", false) else ("laser" if bullet.get("beam", false) else "shot")
		_draw_bullet(bullet, kind)
	for bullet in game.enemy_bullets:
		var kind = "homing" if bullet.get("homing", false) else ("bounce" if bullet.get("bounce", 0) > 0 else "enemy")
		_draw_bullet(bullet, kind)
	for drop in game.drops:
		var kind = str(drop.get("kind", "coin"))
		kind = {"rojo":"shot","verde":"missile","azul":"bomb","amarillo":"shield"}.get(kind,kind)
		if kind == "weapon":
			kind = str(drop.get("weapon", "shot"))
		assets.sprite(self, "w01_ui_item_%s_idle" % kind, Rect2(drop.pos - Vector2(8, 8), Vector2(16, 16)), clock)
	for effect in game.effects:
		var kind = str(effect.get("kind", "explosion"))
		assets.sprite(self, "w01_fx_%s_burst" % ("bubble" if kind=="pulse" else kind), Rect2(effect.pos - Vector2(24, 24), Vector2(48, 48)), float(effect.get("age",0)), Color(1, 1, 1, 0.3 if options.reduce_flashes else 1))
	if game.state not in ["dead", "dying"]:
		var pos = game.player.pos
		if options.shake and not options.reduce_flashes and game.invulnerability > 0 and game.player.since_damage < 0.2:
			pos += Vector2(sin(clock * 75), cos(clock * 80)) * 2
		_draw_ship(pos, Vector2(48, 24))
		if hitboxes:
			var hb = game.data.combat.player.hitbox
			var size = Vector2(hb[0], hb[1])
			draw_rect(Rect2(game.player.pos - size / 2, size), Color.CYAN, false, 1)
	if hitboxes:
		for hazard in game.hazards:
			draw_rect(hazard.rect, Color.YELLOW, false, 1)
	if game.state == "dying":
		var fade_duration = float(game.data.combat.timings.get("death_fade", 0.5))
		if game.death_timer < fade_duration:
			_pixel(Rect2(0, 0, 640, 336), Color(0, 0, 0, 1.0 - maxf(0, game.death_timer) / fade_duration))
	if game.screen_blind>0:
		_pixel(Rect2(0,0,640,336),Color(1,1,1,float(game.data.combat.ui.reduced_flash_alpha) if options.reduce_flashes else float(game.data.combat.ui.flash_alpha)))
	_draw_hud()
	var boss_index = 0
	for boss in game.enemies:
		if not boss.get("boss", false) or float(boss.get("hp", 0)) <= 0:
			continue
		var y = 14 + boss_index * 24
		var name_text = str(boss.get("name", boss.id)) + " / FASE %d" % int(boss.get("phase", 1))
		if game.profile.equipment.get("ctd", false):
			name_text += " %d/%d" % [ceili(boss.hp), int(boss.max_hp)]
		_label(name_text, Vector2(80, y - 10))
		_pixel(Rect2(80, y, 480, 6), Color(0.1, 0.1, 0.15))
		_pixel(Rect2(80, y, 480 * clampf(float(boss.hp) / maxf(1, boss.max_hp), 0, 1), 6), Color(0.8, 0.25, 0.6))
		for fraction in [0.33, 0.66]:
			_pixel(Rect2(80 + 480 * fraction, y, 1, 6), Color.WHITE)
		boss_index += 1
	if game.notice_time > 0:
		assets.panel(self, Rect2(140, 280, 360, 25))
		_label(str(game.notice), Vector2(155, 288), Color.YELLOW)
	if hitboxes:
		_label("F3 HITBOX | BALAS %d/%d | T %.1f" % [game.enemy_bullets.size(), int(game.data.combat.enemy.bullet_pool), game.world_time], Vector2(6, 320), Color.CYAN)

func _enemy_draw_parts(enemy:Dictionary)->Array:
	if float(enemy.get("hp",0))<=0 or enemy.get("inactive",false):return []
	return enemy.parts if not enemy.get("parts",[]).is_empty() else [{"pos":enemy.pos,"size":enemy.get("size",Vector2(32,24))}]

func _enemy_visual_layers(enemy:Dictionary,key:String)->Array:
	var parts=_enemy_draw_parts(enemy)
	if parts.is_empty():return []
	var root_key=key.trim_suffix("_move").trim_suffix("_hit")
	var action="hit" if key.ends_with("_hit") else "move"
	if enemy.get("id","")=="boss_w01_nereis" and assets.has_sprite(root_key+"_head_"+action):
		if parts.size()==2:
			return [{"key":root_key+"_front_"+action,"rect":Rect2(parts[0].pos-parts[0].size/2,parts[0].size)}, {"key":root_key+"_tail_"+action,"rect":Rect2(parts[1].pos-parts[1].size/2,parts[1].size)}]
		var rect=Rect2(enemy.pos-enemy.size/2,enemy.size)
		var quarter=Vector2(rect.size.x*0.25,rect.size.y)
		return [{"key":root_key+"_body_"+action,"rect":Rect2(rect.position+Vector2(quarter.x,0),Vector2(rect.size.x-quarter.x,rect.size.y))}, {"key":root_key+"_head_"+action,"rect":Rect2(rect.position,quarter)}, {"key":root_key+"_jaws_"+action,"rect":Rect2(rect.position,quarter)}]
	var layers=[]
	for part in parts:layers.append({"key":key,"rect":Rect2(part.pos-part.size/2,part.size)})
	return layers

func _draw_bullet(bullet: Dictionary, kind: String):
	var size = bullet.get("size", Vector2(8, 4))
	assets.sprite(self, "w01_bullet_%s_move" % kind, Rect2(bullet.pos - size / 2, size), clock)
	if hitboxes:
		draw_rect(Rect2(bullet.pos - size / 2, size), Color.YELLOW, false, 1)

func _draw_hud():
	assets.panel(self, Rect2(0, 336, 640, 24))
	_pixel(Rect2(8, 340, 120, 8), Color(0.15, 0.2, 0.26))
	var ratio = clampf(float(game.player.shield) / float(game.stats.max_shield), 0, 1)
	for index in range(12):
		if ratio * 12 > index:
			_pixel(Rect2(9 + index * 10, 341, 8, 6), Color(0.2, 0.85, 0.75))
	_label("%d/%d" % [ceili(game.player.shield), int(game.stats.max_shield)], Vector2(40, 350))
	var weapons = ["shot", "missile", "bomb"]
	for index in range(3):
		var x = 140 + index * 41
		assets.sprite(self, "w01_ui_item_%s_idle" % weapons[index], Rect2(x, 338, 12, 12))
		var effective=maxi(int(game.profile.weapons.missile),int(game.stats.min_missile)) if weapons[index]=="missile" else int(game.profile.weapons[weapons[index]])
		_label(str(effective), Vector2(x + 17, 340))
		for level in range(effective):
			_pixel(Rect2(x + level * 4, 352, 3, 3), Color.CYAN)
	for index in range(int(game.stats.max_bombs)):
		assets.sprite(self, "w01_ui_item_bomb_idle", Rect2(270 + index * 14, 342, 12, 12), 0, Color.WHITE if index < int(game.profile.bombs) else Color(0.2, 0.3, 0.4))
	assets.sprite(self, "w01_ui_item_coin_idle", Rect2(350, 342, 12, 12))
	_label("INFINITO" if sandbox else str(int(game.profile.credits)), Vector2(365, 345))
	_pixel(Rect2(450, 343, 180, 6), Color(0.12, 0.2, 0.28))
	var duration = maxf(1, float(game.world.get("duracion_hasta_jefe_seg", 300)))
	_pixel(Rect2(450, 343, 180 * (1.0 if game.state=="boss" else clampf(game.world_time / duration, 0, 1)), 6), Color(0.35, 0.65, 0.9))
	var mini = float(game.world.get("minijefe_inicio_seg", -1))
	if mini > 0:
		_pixel(Rect2(450 + 180 * mini / duration, 341, 2, 10), Color.YELLOW)
	_pixel(Rect2(628, 341, 2, 10), Color(1, 0.4, 0.5))
	_label("M%d %s" % [game.profile.world, _time(game.world_time)], Vector2(485, 351))

func _draw_shop():
	for entry in shop_rows:
		if entry.id != shop_item:
			continue
		var row = entry.data
		_label(str(row.nombre), Vector2(300, 80), Color.CYAN)
		var description = ""
		if shop_item.begins_with("upgrade:"):
			var rank = int(game.profile.upgrades.get(row.id, 0))
			_label("Rango %d / %d" % [rank, int(row.rangos)], Vector2(300, 102))
			_label("Coste: %d" % int(row.costos[rank]) if rank < int(row.rangos) else "RANGO MÁXIMO", Vector2(300, 120))
			description = _upgrade_description(row)
		else:
			_label("Coste: %d | Acto: %d" % [int(row.costo), int(row.acto)], Vector2(300, 102))
			_label("Instalado" if game.profile.equipment.get(row.id, false) else "Pendiente de compra", Vector2(300, 120))
			description = str(row.get("descripcion", row.get("efecto", ""))).replace("_", " ")
		_label(_wrap(description, 49), Vector2(300, 145))
		_label("Reembolso: solo compras de esta visita.", Vector2(300, 205), Color(0.7, 0.85, 0.85))

func _upgrade_description(row:Dictionary)->String:
	var rank=int(game.profile.upgrades.get(row.id,0))
	var next_profile=game.profile.duplicate(true)
	next_profile.upgrades[row.id]=mini(rank+1,int(row.rangos))
	var before=Shop.stats(game.profile)
	var after=Shop.stats(next_profile)
	var stat=String(row.efecto_por_rango.keys()[0])
	var names={"max_shield":"Escudo máximo","damage_mult":"Daño de armas","rate_mult":"Cadencia","min_missile":"Nivel mínimo de misiles","max_bombs":"Capacidad de bombas","regen":"Escudo regenerado por segundo","magnet":"Radio de atracción","speed":"Velocidad de la nave"}
	var percent=stat in ["damage_mult","rate_mult"]
	var factor=100.0 if percent else 1.0
	var suffix="%" if percent else (" px" if stat=="magnet" else (" px/s" if stat=="speed" else ""))
	return "%s\nAntes: %.1f%s\nDespués: %.1f%s"%[names.get(stat,row.nombre),float(before[stat])*factor,suffix,float(after[stat])*factor,suffix]

func _wrap(value: String, width: int) -> String:
	var output = ""
	var count = 0
	for word in value.split(" "):
		if count + word.length() > width:
			output += "\n"
			count = 0
		output += word + " "
		count += word.length() + 1
	return output.strip_edges()

func _draw_results():
	var labels = {"mundo":"Mundo","nombre":"Hábitat","enemigos_derrotados":"Enemigos derrotados","enemigos_total":"Enemigos de la etapa","porcentaje":"Porcentaje","monedas_recogidas":"Monedas recogidas","recompensa":"Recompensa","bono":"Bono sin morir","muertes":"Muertes","tiempo":"Tiempo activo","objeto_unico":"Objeto único","kills":"Enemigos derrotados", "percentage":"Porcentaje", "collected":"Monedas recogidas", "reward":"Recompensa de mundo", "bonus":"Bono sin morir", "deaths":"Muertes", "time":"Tiempo de mundo", "unique":"Objeto único", "regular_kills":"Enemigos derrotados", "world_collected":"Monedas recogidas", "base":"Recompensa", "item":"Objeto único"}
	var row = 0
	var fraction = clampf(result_clock / 4.0, 0, 1)
	for key in game.result:
		var value = game.result[key]
		var shown = str(value)
		if value is int or value is float:
			shown = str(int(float(value) * fraction))
		_label(str(labels.get(key, key)) + ": " + shown, Vector2(54 + (row / 12) * 300, 70 + (row % 12) * 17))
		row += 1
