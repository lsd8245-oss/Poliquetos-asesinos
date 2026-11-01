extends SceneTree
const EnvironmentArt = preload("res://src/visuals/w01_environment.gd")
const Assets = preload("res://src/core/assets.gd")
class Canvas extends Node2D:
	var art
	var pngs
	var elapsed := 0.0
	func _draw():
		art.draw(self, pngs, elapsed * 60.0, elapsed)
func _initialize():
	call_deferred("run")
func run():
	root.size = Vector2i(640, 360)
	root.content_scale_size = Vector2i(640, 360)
	var pngs = Assets.new()
	pngs.load_all()
	var fragment = JSON.parse_string(FileAccess.get_file_as_string("res://docs/arte/pulido-w01/environment-fragment.json"))
	for asset in fragment.assets:
		var frames: Array[Texture2D] = []
		for index in range(1, int(asset.cuadros) + 1):
			var path = str(asset.ruta).replace("_01.png", "_%02d.png" % index)
			frames.append(ImageTexture.create_from_image(Image.load_from_file("res://" + path)))
		pngs._animations[asset.nombre] = {"frames": frames, "fps": float(asset.fps), "loop": true}
	var canvas = Canvas.new()
	canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	canvas.art = EnvironmentArt
	canvas.pngs = pngs
	root.add_child(canvas)
	for elapsed in [0.0, 14.9, 15.0, 29.9, 30.0, 44.9, 45.0, 59.9, 120.0, 159.9, 160.0]:
		canvas.elapsed = elapsed
		canvas.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var image = root.get_texture().get_image()
		image.save_png("res://docs/verificacion/pulido-w01/environment/environment-fixture-%05.1f.png" % elapsed)
	print("ENVIRONMENT FIXTURE PASS: original PNG composition at 11 sector/modulo boundaries")
	quit()
