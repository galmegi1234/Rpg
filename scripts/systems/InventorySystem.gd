extends Node

signal inventory_changed
signal equipment_changed(slot: String, item: Dictionary)

const MAX_SLOTS := 30

# Each item: { id, name, type, icon, value, stackable, count, rarity, stats:{} }
# Equipment slots: head, chest, legs, weapon, offhand, accessory
var slots:      Array[Dictionary] = []
var equipped:   Dictionary = {
	"weapon":    {},
	"head":      {},
	"chest":     {},
	"legs":      {},
	"offhand":   {},
	"accessory": {},
}

func _ready() -> void:
	slots.resize(MAX_SLOTS)
	for i in MAX_SLOTS:
		slots[i] = {}

# ─── Core operations ───────────────────────────────────────────────────────────

func add_item(item: Dictionary) -> bool:
	if item.get("stackable", false):
		for i in MAX_SLOTS:
			if slots[i].get("id") == item["id"]:
				slots[i]["count"] = slots[i].get("count", 1) + item.get("count", 1)
				inventory_changed.emit()
				return true
	var empty := _find_empty_slot()
	if empty == -1:
		return false
	var copy      := item.duplicate(true)
	copy["count"] = item.get("count", 1)
	slots[empty]  = copy
	inventory_changed.emit()
	return true

func remove_item(slot_index: int, count: int = 1) -> Dictionary:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		return {}
	var item := slots[slot_index]
	if item.is_empty():
		return {}
	if item.get("stackable", false) and item.get("count", 1) > count:
		item["count"] -= count
		inventory_changed.emit()
		return item.duplicate()
	var removed := item.duplicate(true)
	slots[slot_index] = {}
	inventory_changed.emit()
	return removed

func equip_item(slot_index: int) -> void:
	var item := slots[slot_index]
	if item.is_empty() or item.get("type") not in ["weapon","head","chest","legs","offhand","accessory"]:
		return
	var eq_slot: String = item["type"]
	if not equipped[eq_slot].is_empty():
		add_item(equipped[eq_slot].duplicate(true))
	equipped[eq_slot] = item.duplicate(true)
	slots[slot_index] = {}
	inventory_changed.emit()
	equipment_changed.emit(eq_slot, equipped[eq_slot])

func unequip_slot(eq_slot: String) -> void:
	if equipped[eq_slot].is_empty():
		return
	if add_item(equipped[eq_slot].duplicate(true)):
		equipped[eq_slot] = {}
		inventory_changed.emit()
		equipment_changed.emit(eq_slot, {})

func get_item(slot_index: int) -> Dictionary:
	return slots[slot_index] if slot_index >= 0 and slot_index < MAX_SLOTS else {}

func get_equipped(eq_slot: String) -> Dictionary:
	return equipped.get(eq_slot, {})

func count_item(item_id: String) -> int:
	var total := 0
	for s in slots:
		if s.get("id") == item_id:
			total += s.get("count", 1)
	return total

func consume_item(item_id: String, count: int = 1) -> bool:
	var remaining := count
	for i in MAX_SLOTS:
		if slots[i].get("id") == item_id:
			var here: int = slots[i].get("count", 1)
			if here <= remaining:
				remaining   -= here
				slots[i]    = {}
			else:
				slots[i]["count"] = here - remaining
				remaining         = 0
			if remaining == 0:
				inventory_changed.emit()
				return true
	return false

# ─── Computed stats from gear ──────────────────────────────────────────────────

func get_equipment_bonus(stat: String) -> int:
	var total := 0
	for eq_slot in equipped:
		var item: Dictionary = equipped[eq_slot]
		if not item.is_empty() and item.has("stats"):
			total += item["stats"].get(stat, 0)
	return total

# ─── Serialization ─────────────────────────────────────────────────────────────

func clear() -> void:
	for i in MAX_SLOTS:
		slots[i] = {}
	for k in equipped:
		equipped[k] = {}
	inventory_changed.emit()

func serialize() -> Dictionary:
	var slot_data: Array = []
	for s in slots:
		slot_data.append(s.duplicate(true))
	var eq_data: Dictionary = {}
	for k in equipped:
		eq_data[k] = equipped[k].duplicate(true)
	return {"slots": slot_data, "equipped": eq_data}

func deserialize(data: Dictionary) -> void:
	if data.has("slots"):
		var sd: Array = data["slots"]
		for i in mini(sd.size(), MAX_SLOTS):
			var v: Variant = sd[i]
			slots[i] = v if v is Dictionary else {}
	if data.has("equipped"):
		var eq_raw: Variant = data["equipped"]
		if eq_raw is Dictionary:
			var eq_dict: Dictionary = eq_raw
			for k in equipped:
				var val: Variant = eq_dict.get(k, {})
				equipped[k] = val if val is Dictionary else {}
	inventory_changed.emit()

# ─── Helpers ───────────────────────────────────────────────────────────────────

func _find_empty_slot() -> int:
	for i in MAX_SLOTS:
		if slots[i].is_empty():
			return i
	return -1
