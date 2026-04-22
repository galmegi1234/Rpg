extends Control

@onready var start_btn:    Button = $VBoxContainer/StartButton
@onready var continue_btn: Button = $VBoxContainer/ContinueButton
@onready var settings_btn: Button = $VBoxContainer/SettingsButton
@onready var quit_btn:     Button = $VBoxContainer/QuitButton
@onready var bg_particles: GPUParticles2D = $BackgroundParticles
@onready var title_label:  Label          = $TitleLabel
@onready var version_lbl:  Label          = $VersionLabel
@onready var parallax_bg:  ParallaxBackground = $ParallaxBackground
@onready var settings_panel: PanelContainer  = $SettingsPanel
@onready var leaderboard_panel: PanelContainer = $LeaderboardPanel
@onready var lb_list: VBoxContainer = $LeaderboardPanel/ScrollContainer/VBoxContainer

func _ready() -> void:
	start_btn.pressed.connect(_on_start_pressed)
	continue_btn.pressed.connect(_on_continue_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)

	continue_btn.disabled = not SaveSystem.has_save()
	version_lbl.text = "v1.0.0  —  Chronicles of Aetheria"

	_animate_title()
	_populate_leaderboard()

func _process(delta: float) -> void:
	if parallax_bg:
		parallax_bg.scroll_offset += Vector2(10, 5) * delta

func _animate_title() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(title_label, "modulate", Color(1.2, 1.0, 0.3), 1.2)
	tween.tween_property(title_label, "modulate", Color.WHITE,            1.2)

func _populate_leaderboard() -> void:
	for child in lb_list.get_children():
		child.queue_free()
	var board := RankSystem.get_leaderboard()
	for i in min(board.size(), 10):
		var entry: Dictionary = board[i]
		var lbl := Label.new()
		lbl.text = "%d. %s pts  [%s]" % [i + 1, entry["score"], entry["rank"]]
		lbl.add_theme_font_size_override("font_size", 16)
		lb_list.add_child(lbl)

func _on_start_pressed() -> void:
	GameManager.start_new_game()

func _on_continue_pressed() -> void:
	GameManager.continue_game()

func _on_settings_pressed() -> void:
	settings_panel.visible = not settings_panel.visible

func _on_quit_pressed() -> void:
	get_tree().quit()
