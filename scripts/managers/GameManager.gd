extends Node

signal player_died
signal level_changed(new_level: int)
signal zone_changed(zone_name: String)
signal game_over(final_score: int, final_rank: String)
signal score_changed(new_score: int)
signal gold_changed(new_gold: int)

enum GameState { MAIN_MENU, PLAYING, PAUSED, GAME_OVER, IN_SHOP, IN_INVENTORY }
enum ZoneType { TOWN, PLAINS, FOREST, DUNGEON }

const ZONE_SCENES := {
	ZoneType.TOWN:    "res://scenes/maps/Town.tscn",
	ZoneType.PLAINS:  "res://scenes/maps/Plains.tscn",
	ZoneType.FOREST:  "res://scenes/maps/Forest.tscn",
	ZoneType.DUNGEON: "res://scenes/maps/Dungeon.tscn",
}

var current_state: GameState = GameState.MAIN_MENU
var current_zone: ZoneType   = ZoneType.TOWN
var score:            int   = 0
var gold:             int   = 100
var play_time:        float = 0.0
var monsters_killed:  int   = 0
var player_ref:       Node  = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if current_state == GameState.PLAYING:
		play_time += delta

# ─── Game lifecycle ────────────────────────────────────────────────────────────

func start_new_game() -> void:
	score           = 0
	gold            = 100
	play_time       = 0.0
	monsters_killed = 0
	current_state   = GameState.PLAYING
	current_zone    = ZoneType.TOWN
	InventorySystem.clear()
	RankSystem.reset_session()
	get_tree().change_scene_to_file(ZONE_SCENES[ZoneType.TOWN])

func continue_game() -> void:
	if not SaveSystem.has_save():
		start_new_game()
		return
	SaveSystem.load_game()
	current_state = GameState.PLAYING
	get_tree().change_scene_to_file(ZONE_SCENES[current_zone])

func trigger_game_over() -> void:
	current_state    = GameState.GAME_OVER
	var final_rank   := RankSystem.get_rank_label()
	RankSystem.submit_score(score)
	SaveSystem.save_game()
	game_over.emit(score, final_rank)
	get_tree().change_scene_to_file("res://scenes/ui/GameOver.tscn")

func go_to_main_menu() -> void:
	current_state = GameState.MAIN_MENU
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

# ─── Zone travel ───────────────────────────────────────────────────────────────

func travel_to_zone(zone: ZoneType) -> void:
	current_zone = zone
	current_state = GameState.PLAYING
	get_tree().paused = false
	zone_changed.emit(ZoneType.keys()[zone])
	get_tree().change_scene_to_file(ZONE_SCENES[zone])

# ─── Economy ───────────────────────────────────────────────────────────────────

func add_score(amount: int) -> void:
	score += amount
	RankSystem.add_score(amount)
	score_changed.emit(score)

func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		gold_changed.emit(gold)
		return true
	return false

func add_monster_kill() -> void:
	monsters_killed += 1
	add_score(10 * RankSystem.get_score_multiplier())

# ─── Pause ─────────────────────────────────────────────────────────────────────

func pause_game() -> void:
	if current_state == GameState.PLAYING:
		current_state = GameState.PAUSED
		get_tree().paused = true

func resume_game() -> void:
	if current_state == GameState.PAUSED:
		current_state = GameState.PLAYING
		get_tree().paused = false

# ─── UI state helpers ──────────────────────────────────────────────────────────

func enter_shop() -> void:
	current_state = GameState.IN_SHOP

func exit_shop() -> void:
	current_state = GameState.PLAYING

func enter_inventory() -> void:
	current_state = GameState.IN_INVENTORY

func exit_inventory() -> void:
	current_state = GameState.PLAYING
