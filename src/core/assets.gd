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
var _visible_regions: Dictionary = {}

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

func animation_frames(key:String)->int:
	return _animations.get(key,{"frames":[]}).frames.size()

func animation_fps(key:String)->float:
	return maxf(1.0,float(_animations.get(key,{"fps":1}).fps))

func animation_duration(key:String)->float:
	return float(animation_frames(key))/animation_fps(key)

func sprite(canvas: CanvasItem, key: String, rect: Rect2, time: float = 0.0, modulate: Color = Color.WHITE) -> void:
	var texture: Texture2D = get_texture(key, time)
	if texture != null:
		canvas.draw_texture_rect(texture, rect, false, modulate)

func organic_sprite(canvas:CanvasItem,key:String,rect:Rect2,time:float,modulate:Color)->void:
	var texture=get_texture(key,time)
	if texture==null:return
	# Four PNG strips articulate existing anatomy; one logical pixel of sway,
	# different phase per body section, without touching simulation geometry.
	var width=float(texture.get_width())
	for index in range(4):
		var left=floorf(index*width/4.0)
		var right=floorf((index+1)*width/4.0)
		var sway=roundf(sin(time*6.0-index*1.2))
		var source=Rect2(left,0,right-left,texture.get_height())
		var dest=Rect2(rect.position+Vector2(left/width*rect.size.x,sway),Vector2((right-left)/width*rect.size.x,rect.size.y))
		canvas.draw_texture_rect_region(texture,dest,source,modulate)

func visible_regions(key:String,time:float=0.0)->Array:
	var texture=get_texture(key,time)
	if texture==null:return []
	var id=texture.get_instance_id()
	if _visible_regions.has(id):return _visible_regions[id]
	var image=texture.get_image()
	var regions=[]
	if image.detect_alpha()==Image.ALPHA_NONE:
		regions.append(Rect2i(Vector2i.ZERO,image.get_size()))
	else:
		# Scenery is mostly transparent water; cache tight rectangles once.
		for y in range(0,image.get_height(),64):
			for x in range(0,image.get_width(),256):
				var cell=Rect2i(x,y,mini(256,image.get_width()-x),mini(64,image.get_height()-y))
				var used=image.get_region(cell).get_used_rect()
				if used.has_area():regions.append(Rect2i(cell.position+used.position,used.size))
	_visible_regions[id]=regions
	return regions

func background_sprite(canvas:CanvasItem,key:String,rect:Rect2,time:float=0.0,modulate:Color=Color.WHITE)->void:
	var texture=get_texture(key,time)
	if texture==null or modulate.a<=0:return
	var scale=rect.size/Vector2(texture.get_size())
	var viewport=Rect2(0,0,640,336)
	for region in visible_regions(key,time):
		var destination=Rect2(rect.position+Vector2(region.position)*scale,Vector2(region.size)*scale)
		if viewport.intersects(destination):
			canvas.draw_texture_rect_region(texture,destination,Rect2(region),modulate)

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
	var path := "res://" + relative
	if not external.is_empty() and FileAccess.file_exists(external):
		# Artist PNGs beside the executable always override the imported resource.
		path = external
	elif ResourceLoader.exists(path):
		return ResourceLoader.load(path) as Texture2D
	if not FileAccess.file_exists(path):
		return null
	# Raw PNGs also work in development fixtures or an unimported external pack.
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
