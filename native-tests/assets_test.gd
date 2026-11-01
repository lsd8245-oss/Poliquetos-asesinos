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
	var source = Image.load_from_file("res://assets/ui/w01_ui_ship_original_move_01.png")
	assert(assets.get_texture("w01_ui_ship_original_move").get_image().get_data() == source.get_data())
	print("Native assets: PNG loading, animation, unknown keys and Spanish bitmap metrics passed")
	quit(0)
