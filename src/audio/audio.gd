class_name PoliAudio
extends Node
## Original gameplay effects only. Music is a stored setting until songs are approved.
## consume() takes ownership of the supplied event queue and clears it after playback.

const Data = preload("res://src/core/data.gd")
const MAX_PLAYERS := 16

var _catalog: Dictionary = {}
var _streams: Dictionary = {}
var _loaded := false
var _master := 1.0
var _effects := 1.0
var music := 1.0
var _sequence := 0

func stop_all() -> void:
	## Drop all owned playback/resource references; AudioServer drains its handles
	## asynchronously on the mixing thread. Playback may restart after this call.
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	_streams.clear()

func _exit_tree() -> void:
	stop_all()

func configure(options: Dictionary) -> void:
	_master = _level(options.get("master", _master * 10.0), _master)
	_effects = _level(options.get("effects", _effects * 10.0), _effects)
	music = _level(options.get("music", music * 10.0), music)
	for child in get_children():
		if child is AudioStreamPlayer:
			if _master * _effects <= 0.0:
				child.stop()
			else:
				child.volume_db = linear_to_db(_master * _effects * float(child.get_meta("effect_volume", 1.0)))

func _level(value, fallback: float) -> float:
	if value is int or value is float:
		return clampf(float(value), 0.0, 10.0) / 10.0
	return fallback

func _load_catalog() -> void:
	if _loaded:
		return
	_loaded = true
	var entries = Data.read_json("data/audio.json", [])
	if not entries is Array:
		return
	for entry in entries:
		if entry is Dictionary and entry.get("tipo", "") == "sfx":
			_catalog[str(entry.get("id", ""))] = entry

func _stream_for(id: String) -> AudioStreamWAV:
	if _streams.has(id):
		return _streams[id]
	var path: String = Data.path_for(str(_catalog[id].ruta))
	var stream: AudioStreamWAV
	# Exported resources use the importer; WAVs beside the EXE use the file decoder.
	if path.begins_with("res://") and ResourceLoader.exists(path, "AudioStreamWAV"):
		stream = ResourceLoader.load(path, "AudioStreamWAV") as AudioStreamWAV
	elif FileAccess.file_exists(path):
		stream = AudioStreamWAV.load_from_file(path)
	if stream != null:
		stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
		_streams[id] = stream
	return stream

func play(id: String) -> bool:
	if _master * _effects <= 0.0:
		return false
	_load_catalog()
	if not _catalog.has(id):
		return false
	var stream := _stream_for(id)
	if stream == null:
		return false
	var entry: Dictionary = _catalog[id]
	var priority := int(entry.get("prioridad", 1))
	var player: AudioStreamPlayer
	var weakest: AudioStreamPlayer
	for child in get_children():
		if not child is AudioStreamPlayer:
			continue
		if not child.playing:
			player = child
			break
		if weakest == null or int(child.get_meta("priority")) < int(weakest.get_meta("priority")) or (int(child.get_meta("priority")) == int(weakest.get_meta("priority")) and int(child.get_meta("sequence")) < int(weakest.get_meta("sequence"))):
			weakest = child
	if player == null:
		if get_child_count() < MAX_PLAYERS:
			player = AudioStreamPlayer.new()
			add_child(player)
		elif weakest != null and priority > int(weakest.get_meta("priority")):
			player = weakest
			player.stop()
		else:
			return false
	_sequence += 1
	player.set_meta("effect_id", id)
	player.set_meta("priority", priority)
	player.set_meta("sequence", _sequence)
	player.set_meta("effect_volume", float(entry.get("volumen", 1.0)))
	player.stream = stream
	player.volume_db = linear_to_db(_master * _effects * float(entry.get("volumen", 1.0)))
	player.play()
	return true

func consume(events: Array) -> void:
	for event in events:
		if event is String:
			play(event)
	events.clear()
