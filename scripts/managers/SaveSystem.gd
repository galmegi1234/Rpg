extends Node

const SAVE_PATH := "user://save_data.json"

# ─── Public API ────────────────────────────────────────────────────────────────

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> void:
	var data := {
		"version":         1,
		"score":           GameManager.score,
		"gold":            GameManager.gold,
		"play_time":       GameManager.play_time,
		"monsters_killed": GameManager.monsters_killed,
		"current_zone":    GameManager.current_zone,
		"rank_data":       RankSystem.serialize(),
		"inventory":       InventorySystem.serialize(),
		"player_stats":    _serialize_player_stats(),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func load_game() -> void:
	if not has_save():
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var raw  := file.get_as_text()
	file.close()
	var result: Variant = JSON.parse_string(raw)
	if result == null or not result is Dictionary:
		return
	var data: Dictionary = result
	GameManager.score           = data.get("score", 0)
	GameManager.gold            = data.get("gold", 100)
	GameManager.play_time       = data.get("play_time", 0.0)
	GameManager.monsters_killed = data.get("monsters_killed", 0)
	GameManager.current_zone    = data.get("current_zone", GameManager.ZoneType.TOWN)
	if data.has("rank_data"):
		RankSystem.deserialize(data["rank_data"])
	if data.has("inventory"):
		InventorySystem.deserialize(data["inventory"])

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)

# ─── Helpers ───────────────────────────────────────────────────────────────────

func _serialize_player_stats() -> Dictionary:
	if not GameManager.player_ref:
		return {}
	var stats: PlayerStats = GameManager.player_ref.stats
	if not stats:
		return {}
	return {
		"level":    stats.level,
		"xp":       stats.xp,
		"max_hp":   stats.max_hp,
		"hp":       stats.hp,
		"attack":   stats.attack,
		"defense":  stats.defense,
		"speed":    stats.speed,
	}
