extends SceneTree

const AssetsScript = preload("res://src/core/assets.gd")

func _init() -> void:
	var assets = AssetsScript.new()
	assets.load_all()
	assert(assets.has_sprite("w01_ui_ship_original_move"))
	assert(assets.get_texture("w01_ui_ship_original_move").get_size() == Vector2(48,24))
	assert(assets.get_texture("w01_ui_ship_original_move", 0.11) != assets.get_texture("w01_ui_ship_original_move", 0.0))
	assert(assets.get_texture("missing") == null)
	assert(assets.text_size("áéíóúüñÁÉÍÓÚÜÑ¿¡") == Vector2(96,9))
	assert(assets.text_size("A\nAB", 2) == Vector2(24,36))
	assert(assets.has_sprite("w15_bg_layer4_idle"))
	# The actual texture pixels come from individually replaceable PNGs.
	var source := Image.new()
	assert(source.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/ui/w01_ui_ship_original_move_01.png")) == OK)
	var loaded=assets.get_texture("w01_ui_ship_original_move").get_image()
	assert(loaded.get_size()==source.get_size())
	for y in range(source.get_height()):
		for x in range(source.get_width()):
			var expected=source.get_pixel(x,y)
			var actual=loaded.get_pixel(x,y)
			assert(actual.a==expected.a)
			# Godot's imported fix_alpha_border may change invisible RGB only.
			if expected.a>0:assert(actual==expected)
	assert(assets.has_method("visible_regions"),"Transparent scenery must expose cached nonempty regions")
	var bg=assets.get_texture("w01_bg_layer2_idle").get_image()
	var regions=assets.visible_regions("w01_bg_layer2_idle")
	var rebuilt=Image.create(bg.get_width(),bg.get_height(),false,Image.FORMAT_RGBA8)
	for region in regions:rebuilt.blit_rect(bg,region,region.position)
	for y in range(0,bg.get_height(),4):
		for x in range(0,bg.get_width(),4):
			var expected=bg.get_pixel(x,y)
			assert(rebuilt.get_pixel(x,y).a==expected.a)
			if expected.a>0:assert(rebuilt.get_pixel(x,y)==expected)
	print("Native assets: PNG loading, animation, unknown keys and Spanish bitmap metrics passed")
	quit(0)
