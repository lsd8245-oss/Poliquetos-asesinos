extends RefCounted
## Pure PNG composition: no simulation state, collision changes or random calls.
## offset is the existing stage scroll (60 px/s); time is the animation clock.
## Three coastal sectors crossfade over 3 s, at 15 s intervals, independently of
## the nominal stage timeline. Four parallax depths remain 0.1 / 0.3 / 0.6 / 1.0.

const SECTOR_LENGTH := 900.0
const TRANSITION := 180.0
const DEPTHS := [0.1, 0.3, 0.6, 1.0]
const STRUCTURES := ["w01_bg_coast_pillars_idle", "w01_bg_ruin_arch_idle", "w01_bg_wreck_truss_idle"]

static func draw(canvas: CanvasItem, assets, offset: float, time: float) -> void:
	# Water is a continuous existing PNG; integer placement prevents subpixel seams.
	var water := "w01_bg_layer1_idle"
	var texture: Texture2D = assets.get_texture(water, time)
	if texture != null:
		var width := float(texture.get_width())
		var start := -int(fposmod(offset * DEPTHS[0], width))
		for tile in range(3):
			assets.background_sprite(canvas, water, Rect2(start + tile * width, 0, width, 336), time, Color(0.67, 0.80, 0.90, 1))
	var sector := int(floor(offset / SECTOR_LENGTH))
	var mix_next := smoothstep(SECTOR_LENGTH - TRANSITION, SECTOR_LENGTH, fposmod(offset, SECTOR_LENGTH))
	_draw_structures(canvas, assets, offset, time, posmod(sector, 3), 1.0 - mix_next)
	if mix_next > 0.0:
		_draw_structures(canvas, assets, offset, time, posmod(sector + 1, 3), mix_next)
	_draw_life(canvas, assets, offset, time)

static func _draw_structures(canvas: CanvasItem, assets, offset: float, time: float, sector: int, weight: float) -> void:
	if weight <= 0.0:
		return
	# A 2880 px arrangement repeats only after 160 s at this depth. Each sector
	# has a different silhouette and spacing; the central movement corridor stays open.
	var widths := [190.0, 248.0, 310.0]
	var heights := [124.0, 138.0, 110.0]
	for index in range(8):
		var slot := posmod(index, 8)
		var x := fposmod(float(index) * 360.0 - offset * DEPTHS[1], 2880.0) - 420.0
		x += float((slot * 73 + sector * 31) % 105)
		var width: float = widths[sector] * (0.8 if slot % 3 == 0 else 1.0)
		var height: float = heights[sector] * (0.8 if slot % 3 == 0 else 1.0)
		var y := 340.0 - height + float((slot * 13) % 15)
		_png(canvas, assets, STRUCTURES[sector], Rect2(x, y, width, height), time, Color(0.55, 0.73, 0.84, 0.72 * weight))
		if sector == 2 and slot % 2 == 0:
			_png(canvas, assets, STRUCTURES[0], Rect2(x + width - 24, 240, 108, 96), time, Color(0.46, 0.65, 0.78, 0.56 * weight))

static func _draw_life(canvas: CanvasItem, assets, offset: float, time: float) -> void:
	# Independent phase and speed per object, baked PNG animation loops. No global
	# synchronous swaying; no decorative posts across the flight corridor.
	for index in range(13):
		var slot := posmod(index, 13)
		var x := fposmod(float(index) * 154.0 - offset * DEPTHS[2], 2002.0) - 128.0
		var phase := float(slot) * 0.71
		var scale := 0.72 + float(slot % 4) * 0.14
		var height := 64.0 * scale
		var sway := sin(time * (0.63 + float(slot % 3) * 0.13) + phase) * 2.0
		_png(canvas, assets, "w01_bg_algae_sway", Rect2(x + sway, 338 - height, 70 * scale, height), time * (0.76 + float(slot % 3) * 0.17) + phase, Color(0.65, 0.80, 0.86, 0.80))
		if slot % 4 == 2:
			var chain_x := x + 65 + sin(time * 0.42 + phase) * 2
			_png(canvas, assets, "w01_bg_chain_sway", Rect2(chain_x, -22, 48, 93), time * 0.62 + phase, Color(0.56, 0.73, 0.82, 0.55))
	# Foreground is a low broken reef with a long deterministic spacing sequence.
	for index in range(11):
		var slot := posmod(index, 11)
		var x := fposmod(float(index) * 218.0 - offset * DEPTHS[3], 2398.0) - 256.0
		x += float((slot * 41) % 80)
		_png(canvas, assets, "w01_bg_coast_rocks_idle", Rect2(x, 309 + slot % 5, 135 + slot % 3 * 19, 36), time, Color(0.56, 0.72, 0.80, 0.76))
	# Fauna and suspended particles are sparse, dim and behind combat sprites.
	for index in range(3):
		var phase := float(index) * 2.17
		var fish_x := fposmod(785.0 - offset * DEPTHS[2] - time * 11.0 + index * 337.0, 1010.0) - 160.0
		var fish_y := 90.0 + float((index * 67) % 142) + sin(time * 0.44 + phase) * 5
		_png(canvas, assets, "w01_bg_fish_swim", Rect2(fish_x, fish_y, 79, 35), time * 0.8 + phase, Color(0.55, 0.73, 0.85, 0.43))
	for index in range(9):
		var phase := float(index) * 1.37
		var x := fposmod(float(index * 113) - offset * DEPTHS[3] + sin(time * 0.4 + phase) * 4, 760.0) - 40
		var y := 335.0 - fposmod(time * (9.0 + index % 3 * 2) + index * 47.0, 330.0)
		_png(canvas, assets, "w01_bg_bubble_rise", Rect2(x, y, 15, 25), time * 0.73 + phase, Color(0.65, 0.82, 0.9, 0.30))
	for index in range(5):
		var x := fposmod(float(index * 173) - offset * DEPTHS[2], 820.0) - 90
		var y := 96.0 + float(index * 43 % 200)
		_png(canvas, assets, "w01_bg_plankton_drift", Rect2(x, y, 83, 53), time * 0.39 + index * 0.61, Color(0.70, 0.84, 0.9, 0.24))
	# Localized caustic PNGs vary gently in opacity; no full-screen flash.
	for index in range(3):
		var x := fposmod(index * 281.0 - offset * DEPTHS[1], 1070.0) - 256
		var alpha := 0.055 + 0.025 * sin(time * 0.53 + index * 1.9)
		_png(canvas, assets, "w01_bg_caustic_drift", Rect2(x, 52 + index * 47, 220, 72), time * 0.31 + index * 0.83, Color(0.65, 0.90, 1, alpha))

static func _png(canvas: CanvasItem, assets, key: String, rect: Rect2, time: float, tint: Color) -> void:
	# Culling here avoids both atlas work and accidental offscreen art draws.
	if rect.intersects(Rect2(0, 0, 640, 336)):
		rect.position = rect.position.round()
		rect.size = rect.size.round()
		assets.background_sprite(canvas, key, rect, time, tint)
