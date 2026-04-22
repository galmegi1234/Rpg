class_name PlayerStats
extends Node

signal hp_changed(current: int, maximum: int)
signal xp_changed(current: int, needed: int)
signal leveled_up(new_level: int)
signal died

# ─── Base stats ────────────────────────────────────────────────────────────────
var level:   int = 1
var xp:      int = 0
var max_hp:  int = 100
var hp:      int = 100
var attack:  int = 15
var defense: int = 5
var speed:   int = 180   # pixels/sec

var is_dead: bool = false

# ─── XP table (XP needed to reach next level) ──────────────────────────────────
const XP_TABLE: Array[int] = [
	0, 100, 250, 450, 700, 1000, 1350, 1750, 2200, 2700,
	3250, 3850, 4500, 5200, 5950, 6750, 7600, 8500, 9450, 10450
]

func xp_to_next_level() -> int:
	if level >= XP_TABLE.size():
		return 999999
	return XP_TABLE[level]

# ─── HP ────────────────────────────────────────────────────────────────────────

func take_damage(amount: int) -> void:
	if is_dead:
		return
	hp = max(0, hp - amount)
	hp_changed.emit(hp, _effective_max_hp())
	if hp == 0:
		is_dead = true
		died.emit()

func heal(amount: int) -> void:
	if is_dead:
		return
	hp = min(_effective_max_hp(), hp + amount)
	hp_changed.emit(hp, _effective_max_hp())

func full_heal() -> void:
	hp = _effective_max_hp()
	hp_changed.emit(hp, _effective_max_hp())

# ─── XP / Level ────────────────────────────────────────────────────────────────

func gain_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_to_next_level() and level < 20:
		xp   -= xp_to_next_level()
		level += 1
		_apply_level_up()
		leveled_up.emit(level)
		GameManager.level_changed.emit(level)
	xp_changed.emit(xp, xp_to_next_level())

func _apply_level_up() -> void:
	max_hp  += 20
	attack  += 3
	defense += 2
	hp       = _effective_max_hp()   # restore HP on level-up

# ─── Effective stats (base + gear) ────────────────────────────────────────────

func effective_attack() -> int:
	return attack + InventorySystem.get_equipment_bonus("attack")

func effective_defense() -> int:
	return defense + InventorySystem.get_equipment_bonus("defense")

func effective_speed() -> int:
	return speed + InventorySystem.get_equipment_bonus("speed")

func _effective_max_hp() -> int:
	return max_hp + InventorySystem.get_equipment_bonus("max_hp")

# ─── Serialization ─────────────────────────────────────────────────────────────

func serialize() -> Dictionary:
	return {
		"level":   level,
		"xp":      xp,
		"max_hp":  max_hp,
		"hp":      hp,
		"attack":  attack,
		"defense": defense,
		"speed":   speed,
	}

func deserialize(data: Dictionary) -> void:
	level   = data.get("level",   1)
	xp      = data.get("xp",      0)
	max_hp  = data.get("max_hp",  100)
	hp      = data.get("hp",      100)
	attack  = data.get("attack",  15)
	defense = data.get("defense", 5)
	speed   = data.get("speed",   180)
	is_dead = false
