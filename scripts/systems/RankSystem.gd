extends Node

# Rank order: 0 = Bronze … 3 = Platinum
enum Rank { BRONZE, SILVER, GOLD, PLATINUM }

const RANK_LABELS  := ["Bronze", "Silver", "Gold", "Platinum"]
const RANK_COLORS  := [Color("cd7f32"), Color("c0c0c0"), Color("ffd700"), Color("e5e4e2")]
const RANK_ICONS   := ["🥉", "🥈", "🥇", "💎"]

const RANK_THRESHOLDS := {
	Rank.BRONZE:   0,
	Rank.SILVER:   500,
	Rank.GOLD:     2000,
	Rank.PLATINUM: 6000,
}

var session_score:   int  = 0
var current_rank:    Rank = Rank.BRONZE
var leaderboard:     Array[Dictionary] = []
var keys_available:  int  = 0

const LEADERBOARD_PATH := "user://leaderboard.json"

func _ready() -> void:
	_load_leaderboard()

# ─── Session ───────────────────────────────────────────────────────────────────

func reset_session() -> void:
	session_score = 0
	current_rank  = Rank.BRONZE

func add_score(amount: int) -> void:
	session_score += amount
	_recalculate_rank()

func _recalculate_rank() -> void:
	var prev := current_rank
	for r in [Rank.PLATINUM, Rank.GOLD, Rank.SILVER, Rank.BRONZE]:
		if session_score >= RANK_THRESHOLDS[r]:
			current_rank = r
			break
	if current_rank != prev:
		_on_rank_up(current_rank)

func _on_rank_up(new_rank: Rank) -> void:
	keys_available += 1   # earn a chest key on rank-up

# ─── Queries ───────────────────────────────────────────────────────────────────

func get_rank_label() -> String:
	return RANK_LABELS[current_rank]

func get_rank_color() -> Color:
	return RANK_COLORS[current_rank]

func get_rank_icon() -> String:
	return RANK_ICONS[current_rank]

func get_score_multiplier() -> int:
	return current_rank + 1   # Bronze×1 … Platinum×4

func get_rank_progress() -> float:
	var next := current_rank + 1
	if next > Rank.PLATINUM:
		return 1.0
	var lo: int = RANK_THRESHOLDS[current_rank]
	var hi: int = RANK_THRESHOLDS[next]
	return clampf(float(session_score - lo) / float(hi - lo), 0.0, 1.0)

func spend_key() -> bool:
	if keys_available > 0:
		keys_available -= 1
		return true
	return false

# ─── Leaderboard ───────────────────────────────────────────────────────────────

func submit_score(score: int) -> void:
	leaderboard.append({"score": score, "rank": get_rank_label()})
	leaderboard.sort_custom(func(a, b): return a["score"] > b["score"])
	if leaderboard.size() > 20:
		leaderboard = leaderboard.slice(0, 20)
	_save_leaderboard()

func get_leaderboard() -> Array[Dictionary]:
	return leaderboard

# ─── Persistence ───────────────────────────────────────────────────────────────

func serialize() -> Dictionary:
	return {
		"session_score": session_score,
		"current_rank":  current_rank,
		"keys":          keys_available,
	}

func deserialize(data: Dictionary) -> void:
	session_score  = data.get("session_score", 0)
	current_rank   = data.get("current_rank",  Rank.BRONZE)
	keys_available = data.get("keys",          0)

func _save_leaderboard() -> void:
	var entries: Array = []
	for e in leaderboard:
		entries.append(e)
	var file := FileAccess.open(LEADERBOARD_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(entries, "\t"))
		file.close()

func _load_leaderboard() -> void:
	if not FileAccess.file_exists(LEADERBOARD_PATH):
		return
	var file := FileAccess.open(LEADERBOARD_PATH, FileAccess.READ)
	if not file:
		return
	var result: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if result is Array:
		leaderboard.clear()
		var arr: Array = result
		for i in arr.size():
			if arr[i] is Dictionary:
				var entry: Dictionary = arr[i]
				leaderboard.append(entry)
