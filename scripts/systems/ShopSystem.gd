extends Node

signal purchase_result(success: bool, message: String)
signal enhance_result(success: bool, new_level: int, item: Dictionary)
signal summon_result(item: Dictionary)

# ─── Item catalogue ────────────────────────────────────────────────────────────

const SHOP_ITEMS: Array[Dictionary] = [
	{
		"id": "potion_small", "name": "Small Potion", "type": "consumable",
		"icon": "🧪", "value": 30, "stackable": true, "rarity": "common",
		"stats": {}, "heal": 50
	},
	{
		"id": "potion_large", "name": "Large Potion", "type": "consumable",
		"icon": "🍶", "value": 80, "stackable": true, "rarity": "uncommon",
		"stats": {}, "heal": 150
	},
	{
		"id": "elixir", "name": "Elixir", "type": "consumable",
		"icon": "✨", "value": 200, "stackable": true, "rarity": "rare",
		"stats": {}, "heal": 9999
	},
	{
		"id": "sword_iron", "name": "Iron Sword", "type": "weapon",
		"icon": "⚔️", "value": 150, "stackable": false, "rarity": "common",
		"stats": {"attack": 10}, "enhance_level": 0
	},
	{
		"id": "sword_steel", "name": "Steel Sword", "type": "weapon",
		"icon": "🗡️", "value": 400, "stackable": false, "rarity": "uncommon",
		"stats": {"attack": 25}, "enhance_level": 0
	},
	{
		"id": "armor_leather", "name": "Leather Armor", "type": "chest",
		"icon": "🥋", "value": 120, "stackable": false, "rarity": "common",
		"stats": {"defense": 8}, "enhance_level": 0
	},
	{
		"id": "armor_chain", "name": "Chainmail", "type": "chest",
		"icon": "🛡️", "value": 350, "stackable": false, "rarity": "uncommon",
		"stats": {"defense": 20}, "enhance_level": 0
	},
	{
		"id": "helmet_iron", "name": "Iron Helmet", "type": "head",
		"icon": "⛑️", "value": 100, "stackable": false, "rarity": "common",
		"stats": {"defense": 5}, "enhance_level": 0
	},
	{
		"id": "boots_swift", "name": "Swift Boots", "type": "legs",
		"icon": "👢", "value": 180, "stackable": false, "rarity": "uncommon",
		"stats": {"speed": 20}, "enhance_level": 0
	},
]

# ─── Summon pool ───────────────────────────────────────────────────────────────

const SUMMON_POOL: Array[Dictionary] = [
	{
		"id": "sword_mythril", "name": "Mythril Sword", "type": "weapon",
		"icon": "⚡", "value": 0, "stackable": false, "rarity": "rare",
		"stats": {"attack": 50}, "enhance_level": 0, "weight": 20
	},
	{
		"id": "sword_dragon", "name": "Dragon Slayer", "type": "weapon",
		"icon": "🐉", "value": 0, "stackable": false, "rarity": "legendary",
		"stats": {"attack": 120}, "enhance_level": 0, "weight": 3
	},
	{
		"id": "armor_dragon", "name": "Dragonscale Armor", "type": "chest",
		"icon": "🦎", "value": 0, "stackable": false, "rarity": "legendary",
		"stats": {"defense": 80}, "enhance_level": 0, "weight": 3
	},
	{
		"id": "ring_power", "name": "Ring of Power", "type": "accessory",
		"icon": "💍", "value": 0, "stackable": false, "rarity": "epic",
		"stats": {"attack": 30, "defense": 15}, "enhance_level": 0, "weight": 10
	},
	{
		"id": "amulet_life", "name": "Amulet of Life", "type": "accessory",
		"icon": "📿", "value": 0, "stackable": false, "rarity": "epic",
		"stats": {"max_hp": 100}, "enhance_level": 0, "weight": 10
	},
	{
		"id": "potion_large", "name": "Large Potion", "type": "consumable",
		"icon": "🍶", "value": 0, "stackable": true, "rarity": "uncommon",
		"stats": {}, "heal": 150, "count": 3, "weight": 40
	},
	{
		"id": "elixir", "name": "Elixir", "type": "consumable",
		"icon": "✨", "value": 0, "stackable": true, "rarity": "rare",
		"stats": {}, "heal": 9999, "count": 1, "weight": 14
	},
]

# ─── Enhance config ────────────────────────────────────────────────────────────

const MAX_ENHANCE_LEVEL   := 10
const ENHANCE_COST_BASE   := 100
const ENHANCE_SUCCESS_PCT := [90, 80, 70, 60, 50, 40, 30, 20, 15, 10]

# ─── Shop purchase ─────────────────────────────────────────────────────────────

func buy_item(shop_index: int) -> void:
	if shop_index < 0 or shop_index >= SHOP_ITEMS.size():
		purchase_result.emit(false, "Invalid item.")
		return
	var item: Dictionary = SHOP_ITEMS[shop_index].duplicate(true)
	if not GameManager.spend_gold(item["value"]):
		purchase_result.emit(false, "Not enough gold!")
		return
	if not InventorySystem.add_item(item):
		GameManager.add_gold(item["value"])   # refund
		purchase_result.emit(false, "Inventory full!")
		return
	purchase_result.emit(true, "Purchased %s!" % item["name"])

func sell_item(inv_slot: int) -> void:
	var item := InventorySystem.get_item(inv_slot)
	if item.is_empty():
		purchase_result.emit(false, "No item in that slot.")
		return
	var sell_value: int = int(item.get("value", 0) * 0.5)
	InventorySystem.remove_item(inv_slot)
	GameManager.add_gold(sell_value)
	purchase_result.emit(true, "Sold for %d gold." % sell_value)

# ─── Summon (chest open) ───────────────────────────────────────────────────────

func open_chest() -> void:
	if not RankSystem.spend_key():
		purchase_result.emit(false, "No keys available!")
		return
	var item := _weighted_random(SUMMON_POOL)
	if InventorySystem.add_item(item.duplicate(true)):
		summon_result.emit(item)
	else:
		purchase_result.emit(false, "Inventory full – key refunded.")
		RankSystem.keys_available += 1

func _weighted_random(pool: Array[Dictionary]) -> Dictionary:
	var total: int = 0
	for entry: Dictionary in pool:
		total += int(entry.get("weight", 10))
	var roll: int = randi() % total
	var acc: int  = 0
	for entry: Dictionary in pool:
		acc += int(entry.get("weight", 10))
		if roll < acc:
			return entry
	return pool[pool.size() - 1]

# ─── Enhancement ───────────────────────────────────────────────────────────────

func enhance_item(inv_slot: int) -> void:
	var item := InventorySystem.get_item(inv_slot)
	if item.is_empty() or item.get("type") in ["consumable"]:
		enhance_result.emit(false, 0, {})
		return
	var current_lvl: int = item.get("enhance_level", 0)
	if current_lvl >= MAX_ENHANCE_LEVEL:
		purchase_result.emit(false, "Item is already at max enhancement (+%d)!" % MAX_ENHANCE_LEVEL)
		return
	var cost: int = ENHANCE_COST_BASE * (current_lvl + 1)
	if not GameManager.spend_gold(cost):
		purchase_result.emit(false, "Need %d gold to enhance!" % cost)
		return
	var success_chance: int = ENHANCE_SUCCESS_PCT[current_lvl]
	if randi() % 100 < success_chance:
		item["enhance_level"] = current_lvl + 1
		for stat in item["stats"]:
			item["stats"][stat] = int(item["stats"][stat] * 1.15)
		InventorySystem.slots[inv_slot] = item
		InventorySystem.inventory_changed.emit()
		enhance_result.emit(true, item["enhance_level"], item)
	else:
		enhance_result.emit(false, current_lvl, item)
