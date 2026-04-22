extends Control

@onready var rank_icon_lbl:  Label       = $CenterContainer/Panel/VBox/RankIcon
@onready var rank_name_lbl:  Label       = $CenterContainer/Panel/VBox/RankName
@onready var rank_bar:       ProgressBar = $CenterContainer/Panel/VBox/RankBar
@onready var score_lbl:      Label       = $CenterContainer/Panel/VBox/ScoreLabel
@onready var kills_lbl:      Label       = $CenterContainer/Panel/VBox/KillsLabel
@onready var time_lbl:       Label       = $CenterContainer/Panel/VBox/TimeLabel
@onready var level_lbl:      Label       = $CenterContainer/Panel/VBox/LevelLabel
@onready var retry_btn:      Button      = $CenterContainer/Panel/VBox/Buttons/RetryButton
@onready var menu_btn:       Button      = $CenterContainer/Panel/VBox/Buttons/MenuButton
@onready var leaderboard_vbox: VBoxContainer = $CenterContainer/Panel/VBox/Leaderboard

func _ready() -> void:
	retry_btn.pressed.connect(_on_retry)
	menu_btn.pressed.connect(_on_menu)

	_populate_stats()
	_populate_leaderboard()
	_animate_rank()

func _populate_stats() -> void:
	rank_icon_lbl.text  = RankSystem.get_rank_icon()
	rank_name_lbl.text  = RankSystem.get_rank_label()
	rank_bar.value      = RankSystem.get_rank_progress() * 100.0
	rank_bar.modulate   = RankSystem.get_rank_color()
	score_lbl.text      = "Score:  %d" % GameManager.score
	kills_lbl.text      = "Monsters Killed:  %d" % GameManager.monsters_killed
	time_lbl.text       = "Time:  %s" % _fmt_time(GameManager.play_time)
	var player := GameManager.player_ref
	if player and player.has_node("PlayerStats"):
		level_lbl.text  = "Final Level:  %d" % player.get_node("PlayerStats").level
	else:
		level_lbl.text  = "Final Level:  —"

func _populate_leaderboard() -> void:
	for c in leaderboard_vbox.get_children():
		c.queue_free()
	var board := RankSystem.get_leaderboard()
	for i in min(board.size(), 5):
		var entry: Dictionary = board[i]
		var lbl := Label.new()
		lbl.text = "#%d  %d pts  [%s]" % [i + 1, entry["score"], entry["rank"]]
		lbl.add_theme_font_size_override("font_size", 15)
		leaderboard_vbox.add_child(lbl)

func _animate_rank() -> void:
	rank_icon_lbl.scale  = Vector2.ZERO
	rank_name_lbl.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_interval(0.3)
	tween.tween_property(rank_icon_lbl, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC)
	tween.parallel().tween_property(rank_name_lbl, "modulate:a", 1.0, 0.4)

func _fmt_time(seconds: float) -> String:
	var m := int(seconds) / 60
	var s := int(seconds) % 60
	return "%d:%02d" % [m, s]

func _on_retry() -> void:
	GameManager.start_new_game()

func _on_menu() -> void:
	GameManager.go_to_main_menu()
