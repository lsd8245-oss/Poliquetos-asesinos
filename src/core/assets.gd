class_name PoliAssets
extends RefCounted
## PNG-only renderer. Individual files override the generated atlas without import.
## In a Windows export place assets/ beside the executable to replace PNGs directly.

const FONT_ADVANCE := 6
const FONT_LINE_HEIGHT := 9
var _animations: Dictionary = {}
var _font: Texture2D
var _glyphs: Dictionary = {}
var _loaded := false
var _atlas_textures: Dictionary = {}

func load_all() -> void:
	if _loaded:
		return
	var manifest: Dictionary = _read_json("assets/assets_manifest.json")
	var atlas_frames: Dictionary = {}
	for world in range(1, 16):
		var atlas: Dictionary = _read_json("assets/atlas/w%02d.json" % world)
		var texture: Texture2D = null
		for key in atlas.get("animaciones", {}):
			var animation: Dictionary = atlas["animaciones"][key]
			atlas_frames[key] = {"animation": animation, "frames": atlas.get("frames", {}), "path": "assets/atlas/" + str(atlas.get("imagen", "")), "texture": texture}
	for asset in manifest.get("assets", []):
		var key: String = asset["nombre"]
		var frames: Array[Texture2D] = []
		var fallback: Dictionary = atlas_frames.get(key, {})
		for frame in range(1, int(asset["cuadros"]) + 1):
			var path: String = str(asset["ruta"]).replace("_01.png", "_%02d.png" % frame)
			var texture: Texture2D = _load_png(path)
			if texture == null and not fallback.is_empty():
				if fallback["texture"] == null:
					if not _atlas_textures.has(fallback["path"]):
						_atlas_textures[fallback["path"]] = _load_png(fallback["path"])
					fallback["texture"] = _atlas_textures[fallback["path"]]
				var frame_key: String = key + "_%02d" % frame
				if fallback["texture"] != null and fallback["frames"].has(frame_key):
					var area: Dictionary = fallback["frames"][frame_key]
					var atlas_texture := AtlasTexture.new()
					atlas_texture.atlas = fallback["texture"]
					atlas_texture.region = Rect2(area["x"], area["y"], area["w"], area["h"])
					texture = atlas_texture
			if texture != null:
				frames.append(texture)
		if not frames.is_empty():
			_animations[key] = {"frames": frames, "fps": float(asset["fps"]), "loop": asset["tipo"] != "fx"}
	var font_data: Dictionary = _read_json("assets/ui/bitmap_font.json")
	_glyphs = font_data.get("glyphs", {})
	_font = _load_png("assets/ui/" + str(font_data.get("imagen", "bitmap_font.png")))
	_loaded = true

func has_sprite(key: String) -> bool:
	return _animations.has(key)

func get_texture(key: String, time: float = 0.0) -> Texture2D:
	if not _animations.has(key):
		return null
	var animation: Dictionary = _animations[key]
	var frames: Array = animation["frames"]
	var index := maxi(0, int(floor(time * float(animation["fps"]))))
	index = index % frames.size() if animation["loop"] else mini(index, frames.size() - 1)
	return frames[index]

func sprite(canvas: CanvasItem, key: String, rect: Rect2, time: float = 0.0, modulate: Color = Color.WHITE) -> void:
	var texture: Texture2D = get_texture(key, time)
	if texture != null:
		canvas.draw_texture_rect(texture, rect, false, modulate)

func text(canvas: CanvasItem, value: String, pos: Vector2, color: Color = Color.WHITE, scale: float = 1.0) -> void:
	if _font == null:
		return
	var cursor := pos.round()
	for character in value:
		if character == "\n":
			cursor.x = pos.x
			cursor.y += FONT_LINE_HEIGHT * scale
			continue
		if character == "\t":
			cursor.x += FONT_ADVANCE * scale * 4
			continue
		var area: Array = _glyphs.get(character, _glyphs.get("?", [0, 0, 6, 9]))
		canvas.draw_texture_rect_region(_font, Rect2(cursor, Vector2(area[2], area[3]) * scale), Rect2(area[0], area[1], area[2], area[3]), color)
		cursor.x += FONT_ADVANCE * scale

func text_size(value: String, scale: float = 1.0) -> Vector2:
	var width := 0
	var current := 0
	var lines := 1
	for character in value:
		if character == "\n":
			width = maxi(width, current)
			current = 0
			lines += 1
		else:
			current += 4 if character == "\t" else 1
	return Vector2(maxi(width, current) * FONT_ADVANCE, lines * FONT_LINE_HEIGHT) * scale

func panel(canvas: CanvasItem, rect: Rect2, selected: bool = false) -> void:
	sprite(canvas, "w01_ui_panel_selected_idle" if selected else "w01_ui_panel_idle", rect)

func _external_path(relative: String) -> String:
	if OS.has_feature("editor"):
		return ""
	return OS.get_executable_path().get_base_dir().path_join(relative)

func _load_png(relative: String) -> Texture2D:
	var external := _external_path(relative)
	var path := external if not external.is_empty() and FileAccess.file_exists(external) else "res://" + relative
	if not FileAccess.file_exists(path):
		# Godot exports may remap source PNGs to imported texture resources.
		return load(path) as Texture2D if ResourceLoader.exists(path) else null
	var png := Image.load_from_file(path)
	if png == null or png.is_empty():
		push_warning("Unable to read PNG: " + path)
		return null
	return ImageTexture.create_from_image(png)

func _read_json(relative: String) -> Dictionary:
	var external := _external_path(relative)
	var path := external if not external.is_empty() and FileAccess.file_exists(external) else "res://" + relative
	if not FileAccess.file_exists(path):
		return {}
	var value = JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}
