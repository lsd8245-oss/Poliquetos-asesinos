extends SceneTree

var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _init() -> void:
	call_deferred("run")

func run() -> void:
	check(FileAccess.file_exists("res://src/audio/audio.gd"), "Native audio subsystem exists")
	if failures:
		quit(1)
		return
	var script = load("res://src/audio/audio.gd")
	check(script != null and script.can_instantiate(), "Native audio script compiles")
	if failures:
		quit(1)
		return
	var audio = script.new()
	root.add_child(audio)
	check(audio.has_method("stop_all"), "Explicit audio teardown API exists")
	if failures:
		audio.free()
		quit(1)
		return
	if "--external-probe" in OS.get_cmdline_user_args():
		var path: String = OS.get_executable_path().get_base_dir().path_join("assets/audio/sfx/coin.wav")
		check(FileAccess.file_exists(path), "Override WAV beside executable exists")
		check(audio.play("coin"), "External override plays")
		check(audio.get_child(0).stream.mix_rate == 22050, "External WAV wins over imported 44100 Hz resource")
		var override_stream: WeakRef = weakref(audio.get_child(0).stream)
		audio.free()
		await wait_for_release(override_stream)
		check(override_stream.get_ref() == null, "External WAV playback is released on tree exit")
		if failures == 0:
			print("Native audio: actual external WAV override passed")
		quit(1 if failures else 0)
		return
	var catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/audio.json"))
	check(catalog is Array and catalog.size() == 39, "39 original gameplay effects are catalogued")
	for entry in catalog:
		var bytes = FileAccess.get_file_as_bytes("res://" + entry.ruta)
		check(bytes.size() > 44, "WAV source exists: " + entry.id)
		check(bytes.slice(0, 4).get_string_from_ascii() == "RIFF", "RIFF source: " + entry.id)
		check(bytes.decode_u16(20) == 1 and bytes.decode_u16(22) == 1, "Mono PCM source: " + entry.id)
		check(bytes.decode_u32(24) == 44100 and bytes.decode_u16(34) == 16, "44.1 kHz / 16-bit source: " + entry.id)
		check(audio.play(entry.id), "Actual WAV plays: " + entry.id)
		var player = audio.get_child(0)
		check(player.stream is AudioStreamWAV and player.stream.mix_rate == 44100 and not player.stream.stereo, "WAV decoded: " + entry.id)
		check(player.stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, "Gameplay effects never loop: " + entry.id)
		if FileAccess.file_exists("res://" + entry.ruta + ".import"):
			check(player.stream.resource_path == "res://" + entry.ruta, "Imported resource is used: " + entry.id)
		for child in audio.get_children():
			child.stop()
	audio.configure({"master": 5, "music": 0, "effects": 4})
	check(audio.play("coin"), "Configured effect plays")
	var coin_volume: float = 0.0
	for entry in catalog:
		if entry.id == "coin":
			coin_volume = float(entry.volumen)
	check(is_equal_approx(audio.get_child(0).volume_db, linear_to_db(0.5 * 0.4 * coin_volume)), "Master and effects gain multiply")
	audio.configure({"master": 0, "music": 10, "effects": 10})
	check(not audio.get_child(0).playing and not audio.play("coin"), "Master mute stops active effects")
	audio.configure({"master": 10, "music": 10, "effects": 10})
	for index in range(16):
		check(audio.play("explosion_large"), "Critical effect fills pool")
	check(audio.get_child_count() == 16, "Pool capped at 16 actual players")
	check(not audio.play("shot_1_1"), "Shot dropped when higher priority effects fill pool")
	for child in audio.get_children():
		child.stop()
	for index in range(16):
		check(audio.play("shot_1_1"), "Shot fills pool")
	check(audio.play("alert"), "Critical alert steals a shot slot")
	var alerts := 0
	for child in audio.get_children():
		if child.get_meta("effect_id", "") == "alert":
			alerts += 1
	check(alerts == 1 and audio.get_child_count() == 16, "Alert uses a real stolen player within cap")
	for child in audio.get_children():
		child.stop()
	var events: Array = ["buy", "reject", "select"]
	audio.consume(events)
	check(events.is_empty(), "Consumed event queue is cleared")
	var playing := 0
	for child in audio.get_children():
		if child.playing:
			playing += 1
	check(playing == 3, "Event queue drives actual players")
	check(not audio.play("song") and not audio.play("unknown"), "Uncatalogued effects and music do not play")
	var last_stream: WeakRef = weakref(audio.get_child(2).stream)
	audio.stop_all()
	for child in audio.get_children():
		check(not child.playing and child.stream == null, "Explicit stop releases every player's stream")
	await wait_for_release(last_stream)
	check(last_stream.get_ref() == null, "AudioServer and effect cache release stopped WAV")
	check(audio.play("select"), "Playback can restart after explicit stop")
	var exit_stream: WeakRef = weakref(audio.get_child(0).stream)
	root.remove_child(audio)
	for child in audio.get_children():
		check(not child.playing and child.stream == null, "Tree exit automatically tears down actual players")
	audio.free()
	await wait_for_release(exit_stream)
	check(exit_stream.get_ref() == null, "Tree exit releases AudioServer playback and cached WAV")
	if failures == 0:
		print("Native audio: 39 WAV sources, real playback, gain, mute, queue and priority pool passed")
	quit(1 if failures else 0)

func wait_for_release(reference: WeakRef) -> void:
	# The mixing thread drains stopped playback asynchronously, independently of frame count.
	var deadline := Time.get_ticks_msec() + 1000
	while reference.get_ref() != null and Time.get_ticks_msec() < deadline:
		await create_timer(0.01).timeout
