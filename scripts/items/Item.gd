class_name Item
extends Resource

@export var id:          String = ""
@export var item_name:   String = ""
@export var icon:        String = ""
@export var type:        String = "consumable"   # consumable / weapon / head / chest / legs / offhand / accessory
@export var rarity:      String = "common"       # common / uncommon / rare / epic / legendary
@export var value:       int    = 0
@export var stackable:   bool   = false
@export var description: String = ""
@export var stats:       Dictionary = {}          # { "attack": int, "defense": int, etc. }
@export var heal:        int    = 0               # for consumables
@export var count:       int    = 1
@export var enhance_level: int = 0

func to_dict() -> Dictionary:
	return {
		"id":            id,
		"name":          item_name,
		"icon":          icon,
		"type":          type,
		"rarity":        rarity,
		"value":         value,
		"stackable":     stackable,
		"description":   description,
		"stats":         stats.duplicate(),
		"heal":          heal,
		"count":         count,
		"enhance_level": enhance_level,
	}

static func from_dict(data: Dictionary) -> Dictionary:
	return {
		"id":            data.get("id", ""),
		"name":          data.get("name", ""),
		"icon":          data.get("icon", ""),
		"type":          data.get("type", "consumable"),
		"rarity":        data.get("rarity", "common"),
		"value":         data.get("value", 0),
		"stackable":     data.get("stackable", false),
		"description":   data.get("description", ""),
		"stats":         data.get("stats", {}),
		"heal":          data.get("heal", 0),
		"count":         data.get("count", 1),
		"enhance_level": data.get("enhance_level", 0),
	}
