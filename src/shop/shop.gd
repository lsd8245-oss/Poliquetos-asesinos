class_name PoliShop
extends RefCounted

const Data = preload("../core/data.gd")
const SANDBOX_CREDITS := 999999999
static var _next_token := 0
static var _visits: Dictionary = {}

static func catalog() -> Dictionary:
	var value = Data.read_json("data/shop.json", {})
	return value if value is Dictionary else {}

static func cosmetics() -> Array:
	var value = Data.read_json("data/cosmetics.json", [])
	return value if value is Array else []

static func create_profile(sandbox: bool = false, difficulty: String = "normal") -> Dictionary:
	var upgrades := {}
	for upgrade in catalog().get("mejoras", []):
		upgrades[upgrade.id] = 0
	var skins: Array = ["original"]
	if sandbox:
		skins.clear()
		for cosmetic in cosmetics():
			skins.append(cosmetic.id)
	return {
		"version": 2, "edition": "pruebas" if sandbox else "normal", "slot": 1,
		"difficulty": difficulty if difficulty in ["easy", "normal", "hard"] else "normal",
		"world": 1, "lab_boss": 0, "credits": SANDBOX_CREDITS if sandbox else 0,
		"upgrades": upgrades, "equipment": {"sonar": true},
		"weapons": {"shot": 1, "missile": 1, "bomb": 1},
		"weapons_available": ["shot", "missile", "bomb"], "bombs": 2,
		"skins": skins, "skin": "original",
		"colors": {"hull": "#75c9df", "lights": "#d7ffed", "trail": "#4a9cff"},
		"deaths": {}, "time": 0.0, "cleared": [], "seed": 147001, "completed": false
	}

static func stats(profile: Dictionary) -> Dictionary:
	var data := catalog()
	var result: Dictionary = data.base_stats.duplicate(true)
	var upgrades: Dictionary = profile.get("upgrades", {})
	for upgrade in data.mejoras:
		var rank := clampi(int(upgrades.get(upgrade.id, 0)), 0, int(upgrade.rangos))
		for key in upgrade.efecto_por_rango:
			result[key] += float(upgrade.efecto_por_rango[key]) * rank
	if profile.get("equipment", {}).get("draga", false):
		result.magnet = maxf(result.magnet, 96.0)
	return result

static func available_act(profile: Dictionary) -> int:
	if profile.get("edition", "normal") == "pruebas":
		return 4
	var world := int(profile.get("world", 1))
	if world >= 14 and int(profile.get("lab_boss", 0)) >= 1:
		return 4
	if world >= 9:
		return 3
	if world >= 5:
		return 2
	return 1

static func visit() -> Dictionary:
	_next_token += 1
	_visits[_next_token] = {"transactions": [], "profile": null}
	return {"token": _next_token, "closed": false}

static func close_visit(shop_visit: Dictionary) -> void:
	_visits.erase(shop_visit.get("token", -1))
	shop_visit.closed = true

static func _visit_state(profile: Dictionary, shop_visit: Dictionary) -> Dictionary:
	if shop_visit.get("closed", true):
		return {}
	var state: Dictionary = _visits.get(shop_visit.get("token", -1), {})
	if state.is_empty():
		return {}
	if state.profile != null and not is_same(state.profile, profile):
		return {}
	return state

static func _item(id: String) -> Dictionary:
	var parts := id.split(":")
	if parts.size() != 2 or parts[0] not in ["upgrade", "gear"]:
		return {}
	var data := catalog()
	for item in data.mejoras if parts[0] == "upgrade" else data.equipo:
		if item.id == parts[1]:
			var result: Dictionary = item.duplicate(true)
			result.kind = parts[0]
			return result
	return {}

static func _result(ok: bool, error: String, profile: Dictionary, cost: int = 0) -> Dictionary:
	return {"ok": ok, "error": error, "profile": profile, "cost": cost}

static func purchase(profile: Dictionary, id: String, shop_visit: Dictionary) -> Dictionary:
	var state := _visit_state(profile, shop_visit)
	if state.is_empty():
		return _result(false, "visit_closed_or_invalid", profile)
	var item := _item(id)
	if item.is_empty():
		return _result(false, "unknown_item", profile)
	var rank := 0
	var cost := 0
	if item.kind == "upgrade":
		rank = int(profile.upgrades.get(item.id, 0))
		if rank >= int(item.rangos):
			return _result(false, "max_rank", profile)
		cost = int(item.costos[rank])
	else:
		if profile.equipment.get(item.id, false):
			return _result(false, "already_owned", profile)
		if int(item.acto) > available_act(profile):
			return _result(false, "act_locked", profile)
		cost = int(item.costo)
	var sandbox: bool = profile.get("edition", "normal") == "pruebas"
	if not sandbox and int(profile.get("credits", 0)) < cost:
		return _result(false, "insufficient_credits", profile)
	profile.credits = SANDBOX_CREDITS if sandbox else int(profile.credits) - cost
	if item.kind == "upgrade":
		profile.upgrades[item.id] = rank + 1
	else:
		profile.equipment[item.id] = true
	state.profile = profile
	state.transactions.append({"id": id, "cost": cost, "rank": rank + 1})
	return _result(true, "", profile, cost)

static func refund(profile: Dictionary, id: String, shop_visit: Dictionary) -> Dictionary:
	var state := _visit_state(profile, shop_visit)
	if state.is_empty():
		return _result(false, "visit_closed_or_invalid", profile)
	var item := _item(id)
	if item.is_empty():
		return _result(false, "unknown_item", profile)
	for index in range(state.transactions.size() - 1, -1, -1):
		var transaction: Dictionary = state.transactions[index]
		if transaction.id != id:
			continue
		if item.kind == "upgrade":
			if int(profile.upgrades.get(item.id, 0)) != int(transaction.rank):
				return _result(false, "rank_changed", profile)
			profile.upgrades[item.id] = int(transaction.rank) - 1
		else:
			if not profile.equipment.get(item.id, false):
				return _result(false, "not_owned", profile)
			profile.equipment.erase(item.id)
		profile.credits = SANDBOX_CREDITS if profile.get("edition", "normal") == "pruebas" else int(profile.credits) + int(transaction.cost)
		state.transactions.remove_at(index)
		return _result(true, "", profile, int(transaction.cost))
	return _result(false, "not_purchased_this_visit", profile)
