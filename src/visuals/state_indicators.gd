class_name PoliStateIndicators
extends RefCounted
## Read-only presentation of existing actor state. The caller supplies a clock
## that stops with simulation (game.total_time); this module owns no timers.
## All artwork, including captions, is composed by PoliAssets from existing PNGs.

const LOOT := {
	"rojo": {"key": "w01_ui_item_shot_idle", "text": "TIRO", "tint": Color(1, 0.5, 0.5)},
	"verde": {"key": "w01_ui_item_missile_idle", "text": "MISIL", "tint": Color(0.6, 1, 0.65)},
	"azul": {"key": "w01_ui_item_bomb_idle", "text": "BOMBA", "tint": Color(0.6, 0.8, 1)}
}
const WARNING_KEY := "w01_fx_spark_burst"
const WEAK_KEY := "w01_ui_equipment_ctd_idle"

static func _warning(enemy: Dictionary) -> bool:
	if float(enemy.get("lock", 0.0)) > 0.0 or float(enemy.get("entry", 0.0)) > 0.0:
		return false
	return bool(enemy.get("warning", false)) or float(enemy.get("_charge", {}).get("wait", 0.0)) > 0.0

static func describe(enemy: Dictionary, ctd: bool, time: float, reduce_flashes: bool = false) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if float(enemy.get("hp", 0.0)) <= 0.0 or bool(enemy.get("inactive", false)):
		return result
	var pos: Vector2 = enemy.get("pos", Vector2.ZERO)
	var size: Vector2 = enemy.get("size", Vector2(32, 24))
	var hidden := bool(enemy.get("hidden", false))
	if _warning(enemy):
		# M6 warns at the seabed while its body is hidden. Boss charges expose
		# their actual wait timer, without introducing another attack timer.
		var rect := Rect2(pos - Vector2(size.x * 0.5 + 8, 10), Vector2(20, 20))
		if hidden:
			rect = Rect2(pos.x - 12, 312, 24, 24)
		result.append({"kind": "warning", "key": WARNING_KEY, "rect": rect,
			"time": 2.0 / 12.0 if reduce_flashes else fposmod(time, 0.5),
			"tint": Color(1, 0.85, 0.3, 0.35 if reduce_flashes else 0.85)})
	if hidden:
		return result
	var loot: Dictionary = LOOT.get(str(enemy.get("carrier", "")), {})
	if not loot.is_empty():
		# Static, small corner badge: never a ring around the creature. Keep
		# icon + bitmap caption inside the logical combat viewport.
		var width := 12 + str(loot.text).length() * 6
		var corner := (pos + Vector2(size.x * 0.5 - 4, -size.y * 0.5 - 9)).round()
		corner.x = clampf(corner.x, 0, 640 - width)
		corner.y = clampf(corner.y, 0, 326)
		result.append({"kind": "loot", "key": loot.key, "rect": Rect2(corner, Vector2(10, 10)),
			"time": 0.0, "tint": Color.WHITE, "text": loot.text,
			"text_pos": corner + Vector2(12, 1), "text_tint": loot.tint})
	var flags: Dictionary = enemy.get("flags", {})
	# Never imply that a locked, entering or concealed target can take damage.
	var targetable := float(enemy.get("lock", 0.0)) <= 0.0 and float(enemy.get("entry", 0.0)) <= 0.0 and not bool(flags.get("invisible", false))
	if ctd and targetable and bool(flags.get("weak_exposed", false)):
		for point in flags.get("weak_points", []):
			result.append({"kind": "weak", "key": WEAK_KEY,
				"rect": Rect2((point - Vector2(5, 5)).round(), Vector2(10, 10)),
				"time": 0.0, "tint": Color(0.6, 1, 1, 0.65 if reduce_flashes else 0.8)})
	return result

static func actor_tint(enemy: Dictionary, time: float, reduce_flashes: bool = false) -> Color:
	var flags: Dictionary = enemy.get("flags", {})
	var opacity := float(flags.get("opacity", 0.15 if flags.get("invisible", false) else 1.0))
	if float(enemy.get("lock", 0.0)) > 0.0:
		opacity *= 0.72 if reduce_flashes else 0.68 + 0.08 * sin(time * 3.0)
	return Color(1, 1, 1, clampf(opacity, 0, 1))

static func draw(canvas: CanvasItem, assets, descriptors: Array[Dictionary]) -> void:
	for indicator in descriptors:
		assets.sprite(canvas, indicator.key, indicator.rect, indicator.time, indicator.tint)
		if indicator.has("text"):
			assets.text(canvas, indicator.text, indicator.text_pos, indicator.text_tint)
