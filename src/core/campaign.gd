class_name PoliCampaign
extends RefCounted

const Data = preload("res://src/core/data.gd")
static var _config: Dictionary = {}
static var _aliases: Dictionary = {}

static func config() -> Dictionary:
	if _config.is_empty():
		_config = Data.read_json("data/campaign.json", {})
	return _config

static func world_count() -> int:
	return int(config().world_count)

static func escape_id() -> int:
	return int(config().escape_id)

static func laboratory_id() -> int:
	return int(config().laboratory_id)

static func lab_encounter_count() -> int:
	return int(config().lab_encounters)

static func legacy_world(id: int) -> int:
	return int(config().asset_sources.get(str(id), id))

static func asset_key(world: int, kind: String, id: String, action: String = "move") -> String:
	if _aliases.is_empty():
		_aliases = Data.read_json("assets/campaign_aliases.json", {}).get("aliases", {})
	var key = "w%02d_%s_%s_%s" % [world, kind, id, action]
	return str(_aliases.get(key, ""))
