extends SceneTree
## Explicit rendered policy fixture. Run with DISPLAY, not in the headless suite.
const Policy = preload("res://src/visuals/display_policy.gd")

func _initialize():
	call_deferred("run")

func run():
	if DisplayServer.get_name() == "headless":
		push_error("Display probe requires a real/dummy graphical display")
		quit(1)
		return
	var panel = TextureRect.new()
	panel.texture = load("res://assets/ui/w01_ui_cover_panel_idle_01.png")
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel.size = Vector2(640, 360)
	root.add_child(panel)
	for mode in ["window1", "window2", "window3", "fullscreen_fill", "fullscreen_pixel", "window2"]:
		Policy.apply(root, mode)
		await create_timer(0.25).timeout
		await RenderingServer.frame_post_draw
		var record = Policy.metrics(root, mode)
		var expected_mode = Window.MODE_EXCLUSIVE_FULLSCREEN if mode.begins_with("fullscreen_") else Window.MODE_WINDOWED
		assert(root.mode == expected_mode, "actual window mode must match selected mode")
		if mode.begins_with("fullscreen_"):
			assert(root.size==DisplayServer.screen_get_size(root.current_screen),"fullscreen must occupy monitor, not only report mode4")
		assert(root.get_visible_rect().size == Vector2(640, 360), "all modes preserve full logical HUD/arena")
		if mode.begins_with("window"):
			assert(not root.borderless, "restore decorated window")
			var decorations = Vector2i(record.window_with_decorations[0], record.window_with_decorations[1]) - root.size
			var expected_size = Policy.fit_window_size(Policy.LOGICAL_SIZE * int(mode.trim_prefix("window")), Vector2i(record.usable_size[0], record.usable_size[1]), decorations)
			assert(root.size == expected_size, "restore selected integer size capped to monitor usable surface")
		print("DISPLAY PROBE ", JSON.stringify(record))
	# Native resize exercises the engine's automatic scale update without reapplying
	# policy, covering maximized client dimensions and a non-16:9 monitor shape.
	for mode in ["fullscreen_fill", "fullscreen_pixel"]:
		Policy.apply(root, mode)
		await create_timer(0.1).timeout
		root.mode = Window.MODE_WINDOWED
		for size in [Vector2i(1918, 1078), Vector2i(1366, 768), Vector2i(1600, 900), Vector2i(1920, 1200)]:
			root.size = size
			await create_timer(0.1).timeout
			var record = Policy.metrics(root, mode)
			assert(root.get_visible_rect().size == Vector2(640, 360), "dynamic resize never changes combat coordinates")
			for axis in [0, 1]:
				assert(is_equal_approx(record.observed_scale[axis], record.scale_xy[axis]), "calculated fit matches actual Godot transform")
				assert(is_equal_approx(record.observed_origin[axis], record.content_position[axis]), "calculated bars match actual Godot transform")
			print("DISPLAY RESIZE ", JSON.stringify(record))
	print("DISPLAY PROBE PASS: window1/2/3 -> exclusive fill -> exclusive pixel -> decorated window2")
	quit()
