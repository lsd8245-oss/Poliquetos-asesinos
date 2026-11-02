extends RefCounted
## Display policy only: simulation coordinates remain 640x336 plus the 24px HUD.

const LOGICAL_SIZE = Vector2i(640, 360)

static func modes() -> Array:
	return ["window1", "window2", "window3", "fullscreen_fill", "fullscreen_pixel"]

static func normalize(mode: String) -> String:
	if mode == "fullscreen":
		return "fullscreen_fill"
	return mode if mode in modes() else "window2"

static func label(mode: String) -> String:
	match normalize(mode):
		"fullscreen_fill": return "Rellenar pantalla"
		"fullscreen_pixel": return "Píxel perfecto"
	return "Ventana x" + normalize(mode).trim_prefix("window")

static func apply(window: Window, mode: String) -> void:
	mode = normalize(mode)
	window.content_scale_size = LOGICAL_SIZE
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	window.content_scale_factor = 1.0
	window.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL if mode == "fullscreen_fill" else Window.CONTENT_SCALE_STRETCH_INTEGER
	# The engine automatically recalculates this aspect/scale on resize and DPI change.
	# Headless has no physical screen; configuring the viewport is still meaningful.
	if DisplayServer.get_name() == "headless":
		return
	window.min_size = LOGICAL_SIZE
	if mode.begins_with("fullscreen_"):
		# A maximized decorated window is smaller than the monitor and can fall to x2.
		# Exclusive fullscreen removes both decorations and the Windows taskbar.
		window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
	else:
		var requested_size = LOGICAL_SIZE * int(mode.trim_prefix("window"))
		var was_fullscreen = window.mode != Window.MODE_WINDOWED
		window.mode = Window.MODE_WINDOWED
		window.borderless = false
		var usable = DisplayServer.screen_get_usable_rect(window.current_screen)
		var id = window.get_window_id()
		var decorated = DisplayServer.window_get_size_with_decorations(id)
		var client = DisplayServer.window_get_size(id)
		var decoration_size = Vector2i(maxi(0, decorated.x - client.x), maxi(0, decorated.y - client.y))
		var target_size = fit_window_size(requested_size, usable.size, decoration_size)
		var changed = was_fullscreen or window.size != target_size
		window.size = target_size
		if changed:
			window.position = usable.position + Vector2i(maxi(0, (usable.size.x - target_size.x - decoration_size.x) / 2), maxi(0, (usable.size.y - target_size.y - decoration_size.y) / 2))

static func fit_window_size(requested_size: Vector2i, usable_size: Vector2i, decoration_size: Vector2i = Vector2i.ZERO) -> Vector2i:
	var requested_factor = maxi(1, mini(requested_size.x / LOGICAL_SIZE.x, requested_size.y / LOGICAL_SIZE.y))
	var client_space = usable_size - decoration_size
	var available_factor = maxi(1, mini(client_space.x / LOGICAL_SIZE.x, client_space.y / LOGICAL_SIZE.y))
	return LOGICAL_SIZE * mini(requested_factor, available_factor)

static func content_metrics(window_size: Vector2i, mode: String) -> Dictionary:
	# Match Godot 4.6 Window::_update_viewport_size: floor the aspect fit, then
	# integer-scale if requested and round centering margins to physical pixels.
	var physical = Vector2i(maxi(1, window_size.x), maxi(1, window_size.y))
	var factor = minf(float(physical.x) / LOGICAL_SIZE.x, float(physical.y) / LOGICAL_SIZE.y)
	var integer = normalize(mode) != "fullscreen_fill"
	var content = Vector2i(Vector2(LOGICAL_SIZE) * factor)
	if integer:
		factor = maxf(1.0, floorf(factor))
		content = LOGICAL_SIZE * int(factor)
	var origin = Vector2i(roundi(maxi(0, physical.x - content.x) / 2.0), roundi(maxi(0, physical.y - content.y) / 2.0))
	return {
		"window_size": [physical.x, physical.y],
		"logical_size": [LOGICAL_SIZE.x, LOGICAL_SIZE.y],
		"content_position": [origin.x, origin.y],
		"content_size": [content.x, content.y],
		"factor": factor,
		"scale_xy": [float(content.x) / LOGICAL_SIZE.x, float(content.y) / LOGICAL_SIZE.y],
		"bars": [origin.x, origin.y, maxi(0, physical.x - origin.x - content.x), maxi(0, physical.y - origin.y - content.y)],
		"integer": integer,
		"clipped": content.x > physical.x or content.y > physical.y,
	}

static func metrics(window: Window, mode: String) -> Dictionary:
	var result = content_metrics(window.size, mode)
	result["requested_mode"] = normalize(mode)
	var window_mode = normalize(mode).begins_with("window")
	var requested_factor = int(normalize(mode).trim_prefix("window")) if window_mode else 0
	result["requested_window_scale"] = requested_factor
	result["effective_window_scale"] = mini(window.size.x / LOGICAL_SIZE.x, window.size.y / LOGICAL_SIZE.y) if window_mode else 0
	result["window_adjusted"] = window_mode and window.size != LOGICAL_SIZE * requested_factor
	result["display_backend"] = DisplayServer.get_name()
	result["window_mode"] = window.mode
	result["borderless"] = window.borderless
	result["content_scale_mode"] = window.content_scale_mode
	result["content_scale_aspect"] = window.content_scale_aspect
	result["content_scale_stretch"] = window.content_scale_stretch
	result["content_scale_factor"] = window.content_scale_factor
	result["viewport_size"] = [window.get_visible_rect().size.x, window.get_visible_rect().size.y]
	var transform = window.get_final_transform()
	result["observed_scale"] = [transform.x.x, transform.y.y]
	result["observed_origin"] = [transform.origin.x, transform.origin.y]
	if DisplayServer.get_name() == "headless":
		return result
	var screen = window.current_screen
	var screen_size = DisplayServer.screen_get_size(screen)
	var screen_position = DisplayServer.screen_get_position(screen)
	var usable = DisplayServer.screen_get_usable_rect(screen)
	var decorated = DisplayServer.window_get_size_with_decorations(window.get_window_id())
	result["window_mode"] = DisplayServer.window_get_mode(window.get_window_id())
	result["window_position"] = [window.position.x, window.position.y]
	result["window_with_decorations"] = [decorated.x, decorated.y]
	result["screen"] = screen
	result["screen_size"] = [screen_size.x, screen_size.y]
	result["screen_position"] = [screen_position.x, screen_position.y]
	result["usable_position"] = [usable.position.x, usable.position.y]
	result["usable_size"] = [usable.size.x, usable.size.y]
	result["dpi"] = DisplayServer.screen_get_dpi(screen)
	result["screen_scale"] = DisplayServer.screen_get_scale(screen)
	return result
