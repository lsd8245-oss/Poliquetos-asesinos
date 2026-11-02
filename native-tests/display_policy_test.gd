extends SceneTree

var checks = 0
var failures = 0

func check(value: bool, description: String):
	checks += 1
	if not value:
		failures += 1
		push_error("DISPLAY POLICY FAILED: " + description)

func _initialize():
	if not FileAccess.file_exists("res://src/visuals/display_policy.gd"):
		check(false, "display policy exists")
		quit(1)
		return
	var policy = load("res://src/visuals/display_policy.gd")
	check(policy.modes() == ["window1", "window2", "window3", "fullscreen_fill", "fullscreen_pixel"], "menu exposes both fullscreens and three windows")
	check(policy.normalize("fullscreen") == "fullscreen_fill", "old fullscreen selects preferred fill")
	check(policy.normalize("unknown") == "window2", "invalid option safely uses existing window default")
	check(policy.label("fullscreen_fill") == "Rellenar pantalla", "fill label explains choice")
	check(policy.label("fullscreen_pixel") == "Píxel perfecto", "pixel label explains choice")
	for n in [1, 2, 3]:
		check(policy.label("window" + str(n)) == "Ventana x" + str(n), "window label " + str(n))
	for size in [Vector2i(1920, 1080), Vector2i(1366, 768), Vector2i(2560, 1440), Vector2i(1600, 900), Vector2i(1920, 1200)]:
		for mode in ["fullscreen_fill", "fullscreen_pixel"]:
			var result = policy.content_metrics(size, mode)
			var content = result.content_size
			var bars = result.bars
			check(content[0] <= size.x and content[1] <= size.y, "HUD and threats fit " + str(size) + mode)
			check(bars[0] + content[0] + bars[2] == size.x and bars[1] + content[1] + bars[3] == size.y, "bars account for every physical pixel")
			check(absf(float(content[0]) / content[1] - 640.0 / 360.0) < 0.002, "aspect retained within one physical pixel")
			if mode == "fullscreen_pixel":
				check(content[0] % 640 == 0 and content[1] % 360 == 0, "pixel blocks are integer")
	check(policy.content_metrics(Vector2i(1920, 1080), "fullscreen_fill").bars == [0, 0, 0, 0], "1080p fill has no bars")
	check(policy.content_metrics(Vector2i(1366, 768), "fullscreen_fill").content_size == [1365, 768], "1366 nearest aspect rounds one spare pixel")
	check(policy.content_metrics(Vector2i(1600, 900), "fullscreen_fill").factor == 2.5, "fractional fill uses available 900p")
	check(policy.content_metrics(Vector2i(1600, 900), "fullscreen_pixel").content_size == [1280, 720], "900p integer sacrifices surface for square pixels")
	check(policy.content_metrics(Vector2i(1920, 1200), "fullscreen_fill").bars == [0, 60, 0, 60], "16:10 retains whole combat with horizontal bars")
	var maximized = policy.content_metrics(Vector2i(1918, 1078), "fullscreen_pixel")
	check(maximized.factor == 2 and maximized.bars == [319, 179, 319, 179], "decorated maximized window reproduces large integer bars")
	check(policy.fit_window_size(Vector2i(1920, 1080), Vector2i(1366, 768)) == Vector2i(1280, 720), "requested x3 fits whole HUD on 1366 monitor")
	check(policy.fit_window_size(Vector2i(1920, 1080), Vector2i(1920, 1040)) == Vector2i(1280, 720), "taskbar usable height caps requested x3 to x2")
	check(policy.fit_window_size(Vector2i(1920, 1080), Vector2i(1920, 1080), Vector2i(2, 32)) == Vector2i(1280, 720), "decorations count against available surface")
	check(policy.fit_window_size(Vector2i(1920, 1080), Vector2i(2560, 1400), Vector2i(2, 32)) == Vector2i(1920, 1080), "large monitor retains requested x3")
	check(policy.fit_window_size(Vector2i(640, 360), Vector2i(2560, 1400)) == Vector2i(640, 360), "fitting never enlarges selected x1")
	for mode in policy.modes():
		policy.apply(root, mode)
		check(root.content_scale_size == Vector2i(640, 360), "logical combat unchanged for " + mode)
		check(root.content_scale_mode == Window.CONTENT_SCALE_MODE_VIEWPORT, "render remains fixed-resolution viewport")
		check(root.content_scale_aspect == Window.CONTENT_SCALE_ASPECT_KEEP, "no crop, expansion or arbitrary stretch")
		check(root.content_scale_stretch == (Window.CONTENT_SCALE_STRETCH_FRACTIONAL if mode == "fullscreen_fill" else Window.CONTENT_SCALE_STRETCH_INTEGER), "selected stretch applies")
		check(root.content_scale_factor == 1.0, "internal rendering stays native 640x360")
	var metrics = policy.metrics(root, "fullscreen_fill")
	check(metrics.logical_size == [640, 360] and metrics.has("display_backend"), "headless metrics are safe and JSON serializable")
	check(metrics.has("observed_scale") and metrics.has("observed_origin"), "evidence includes measured viewport transform beside modeled fit")
	root.size = Vector2i(1280, 720)
	var adjusted = policy.metrics(root, "window3")
	check(adjusted.requested_window_scale == 3 and adjusted.effective_window_scale == 2 and adjusted.window_adjusted, "metrics explain reduced window scale")
	check(JSON.stringify(metrics).length() > 0, "metrics serialize for evidence")
	if failures == 0:
		print("DISPLAY POLICY PASS: ", checks, " checks; mode labels, aspect, bars, fixed viewport and safe headless metrics")
	quit(0 if failures == 0 else 1)
