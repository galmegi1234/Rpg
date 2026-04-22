extends CanvasLayer

# ─── HP bar ────────────────────────────────────────────────────────────────────
@onready var hp_bar:        ProgressBar = $TopLeft/HPContainer/HPBar
@onready var hp_label:      Label       = $TopLeft/HPContainer/HPLabel
@onready var hp_icon:       Label       = $TopLeft/HPContainer/HPIcon

# ─── XP bar ────────────────────────────────────────────────────────────────────
@onready var xp_bar:        ProgressBar = $Bottom/XPBar
@onready var level_label:   Label       = $Bottom/LevelLabel

# ─── Gold / Score ──────────────────────────────────────────────────────────────
@onready var gold_label:    Label  = $TopLeft/GoldLabel
@onready var score_label:   Label  = $TopLeft/ScoreLabel
@onready var zone_label:    Label  = $TopRight/ZoneLabel

# ─── Rank bar ──────────────────────────────────────────────────────────────────
@onready var rank_bar:      ProgressBar = $TopRight/RankBar
@onready var rank_label:    Label       = $TopRight/RankLabel
@onready var rank_icon_lbl: Label       = $TopRight/RankIcon

# ─── Skill slots ───────────────────────────────────────────────────────────────
@onready var skill_potion:  Button = $Bottom/Skills/PotionBtn
@onready var skill_dodge:   Button = $Bottom/Skills/DodgeBtn

# ─── Minimap ───────────────────────────────────────────────────────────────────
@onready var minimap:       SubViewportContainer = $TopRight/MinimapContainer

# ─── Level-up banner ───────────────────────────────────────────────────────────
@onready var level_up_banner: PanelContainer = $LevelUpBanner
@onready var level_up_label:  Label          = $LevelUpBanner/Label

# ─── Popup message (top-center) ────────────────────────────────────────────────
@onready var popup_label: Label = $PopupLabel

var player: PlayerController = null

func _ready() -> void:
	level_up_banner.hide()
	popup_label.hide()

	GameManager.gold_changed.connect(_on_gold_changed)
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.zone_changed.connect(_on_zone_changed)
	GameManager.level_changed.connect(_on_level_changed)

	skill_potion.pressed.connect(_on_potion_pressed)
	skill_dodge.pressed.connect(_on_dodge_pressed)

	_on_gold_changed(GameManager.gold)
	_on_score_changed(GameManager.score)
	_on_zone_changed(GameManager.ZoneType.keys()[GameManager.current_zone])
	_refresh_rank()

func _process(_delta: float) -> void:
	if not player:
		player = get_tree().get_first_node_in_group("player") as PlayerController
		return

	# HP bar
	var eff_max := player.stats.max_hp + InventorySystem.get_equipment_bonus("max_hp")
	hp_bar.max_value = eff_max
	hp_bar.value     = player.stats.hp
	hp_label.text    = "%d / %d" % [player.stats.hp, eff_max]

	# XP bar
	xp_bar.max_value = player.stats.xp_to_next_level()
	xp_bar.value     = player.stats.xp
	level_label.text = "Lv.%d" % player.stats.level

	# Rank
	rank_bar.value  = RankSystem.get_rank_progress() * 100.0
	rank_label.text = RankSystem.get_rank_label()
	rank_icon_lbl.text = RankSystem.get_rank_icon()
	rank_bar.modulate = RankSystem.get_rank_color()

	# Keys
	skill_potion.tooltip_text = "Potion (H)\n[%d in bag]" % InventorySystem.count_item("potion_small")

func _on_gold_changed(val: int) -> void:
	gold_label.text = "💰 %d" % val

func _on_score_changed(val: int) -> void:
	score_label.text = "⭐ %d" % val

func _on_zone_changed(name: String) -> void:
	zone_label.text = "📍 " + name

func _on_level_changed(new_level: int) -> void:
	_show_level_up(new_level)

func _show_level_up(lv: int) -> void:
	level_up_label.text = "✨ Level Up!  Lv.%d ✨" % lv
	level_up_banner.show()
	var tween := create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(level_up_banner, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func():
		level_up_banner.hide()
		level_up_banner.modulate.a = 1.0
	)

func show_popup(msg: String, color: Color = Color.WHITE) -> void:
	popup_label.text = msg
	popup_label.add_theme_color_override("font_color", color)
	popup_label.show()
	var tween := create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(popup_label, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func():
		popup_label.hide()
		popup_label.modulate.a = 1.0
	)

func _refresh_rank() -> void:
	rank_label.text    = RankSystem.get_rank_label()
	rank_icon_lbl.text = RankSystem.get_rank_icon()

func _on_potion_pressed() -> void:
	if player:
		player._use_potion()

func _on_dodge_pressed() -> void:
	if player:
		player._start_dodge()
