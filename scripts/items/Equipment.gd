class_name Equipment
extends Resource

# Specialized resource for equipment with dynamic stat scaling based on enhance level.

@export var id:            String     = ""
@export var item_name:     String     = ""
@export var icon:          String     = ""
@export var slot:          String     = "weapon"   # weapon / head / chest / legs / offhand / accessory
@export var rarity:        String     = "common"
@export var base_value:    int        = 100
@export var base_stats:    Dictionary = {}
@export var description:   String     = ""
@export var enhance_level: int        = 0
@export var max_enhance:   int        = 10

const ENHANCE_BONUS_PCT := 0.15   # +15% per enhance level

func get_current_stats() -> Dictionary:
	var result: Dictionary = {}
	for stat in base_stats:
		var base_val: int  = base_stats[stat]
		var bonus:    float = base_val * ENHANCE_BONUS_PCT * enhance_level
		result[stat]       = base_val + int(bonus)
	return result

func get_sell_value() -> int:
	return int(base_value * 0.5 * (1.0 + enhance_level * 0.1))

func can_enhance() -> bool:
	return enhance_level < max_enhance

func enhance() -> bool:
	if not can_enhance():
		return false
	enhance_level += 1
	return true

func to_dict() -> Dictionary:
	return {
		"id":            id,
		"name":          item_name,
		"icon":          icon,
		"type":          slot,
		"rarity":        rarity,
		"value":         base_value,
		"stackable":     false,
		"stats":         get_current_stats(),
		"enhance_level": enhance_level,
		"description":   description,
	}
