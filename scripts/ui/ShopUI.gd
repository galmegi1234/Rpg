extends Control

# ─── Tab bar ──────────────────────────────────────────────────────────────────
@onready var tab_items:    Button = $TabBar/ItemsTab
@onready var tab_summon:   Button = $TabBar/SummonTab
@onready var tab_enhance:  Button = $TabBar/EnhanceTab
@onready var close_btn:    Button = $CloseButton

# ─── Content panels ────────────────────────────────────────────────────────────
@onready var panel_items:   PanelContainer = $Content/ItemsPanel
@onready var panel_summon:  PanelContainer = $Content/SummonPanel
@onready var panel_enhance: PanelContainer = $Content/EnhancePanel

# ─── Items panel nodes ─────────────────────────────────────────────────────────
@onready var shop_item_list: VBoxContainer = $Content/ItemsPanel/ScrollContainer/ItemList
@onready var gold_label_shop: Label        = $GoldBar/GoldLabel

# ─── Summon panel nodes ────────────────────────────────────────────────────────
@onready var chest_box:        PanelContainer = $Content/SummonPanel/ChestBox
@onready var open_btn:         Button         = $Content/SummonPanel/OpenButton
@onready var keys_label:       Label          = $Content/SummonPanel/KeysLabel
@onready var summon_result_lbl: Label         = $Content/SummonPanel/ResultLabel
@onready var chest_anim:       AnimationPlayer = $Content/SummonPanel/ChestBox/AnimationPlayer

# ─── Enhance panel nodes ───────────────────────────────────────────────────────
@onready var inv_enhance_list: VBoxContainer  = $Content/EnhancePanel/InventoryList
@onready var enhance_btn:      Button         = $Content/EnhancePanel/EnhanceButton
@onready var enhance_info:     Label          = $Content/EnhancePanel/InfoLabel
@onready var enhance_result_lbl: Label        = $Content/EnhancePanel/ResultLabel

var selected_inv_slot: int = -1

func _ready() -> void:
	tab_items.pressed.connect(func(): _switch_tab(0))
	tab_summon.pressed.connect(func(): _switch_tab(1))
	tab_enhance.pressed.connect(func(): _switch_tab(2))
	close_btn.pressed.connect(_on_close)
	open_btn.pressed.connect(_on_open_chest)
	enhance_btn.pressed.connect(_on_enhance)

	ShopSystem.purchase_result.connect(_on_purchase_result)
	ShopSystem.summon_result.connect(_on_summon_result)
	ShopSystem.enhance_result.connect(_on_enhance_result)
	GameManager.gold_changed.connect(func(v): gold_label_shop.text = "💰 %d" % v)
	InventorySystem.inventory_changed.connect(_refresh_enhance_list)

	gold_label_shop.text = "💰 %d" % GameManager.gold
	summon_result_lbl.text = ""
	enhance_result_lbl.text = ""
	enhance_btn.disabled = true

	_switch_tab(0)
	_build_shop_list()
	_refresh_enhance_list()

# ─── Tab switching ─────────────────────────────────────────────────────────────

func _switch_tab(idx: int) -> void:
	panel_items.visible   = idx == 0
	panel_summon.visible  = idx == 1
	panel_enhance.visible = idx == 2
	tab_items.button_pressed   = idx == 0
	tab_summon.button_pressed  = idx == 1
	tab_enhance.button_pressed = idx == 2
	if idx == 1:
		keys_label.text = "🗝 Keys: %d" % RankSystem.keys_available

# ─── Items tab ─────────────────────────────────────────────────────────────────

func _build_shop_list() -> void:
	for c in shop_item_list.get_children():
		c.queue_free()
	for i in ShopSystem.SHOP_ITEMS.size():
		var item: Dictionary = ShopSystem.SHOP_ITEMS[i]
		var row := HBoxContainer.new()
		var icon_lbl  := Label.new()
		icon_lbl.text = item["icon"]
		icon_lbl.custom_minimum_size = Vector2(32, 0)
		var name_lbl  := Label.new()
		name_lbl.text = item["name"]
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cost_lbl  := Label.new()
		cost_lbl.text = "💰 %d" % item["value"]
		var buy_btn   := Button.new()
		buy_btn.text  = "Buy"
		buy_btn.custom_minimum_size = Vector2(70, 0)
		var idx_capture := i
		buy_btn.pressed.connect(func(): ShopSystem.buy_item(idx_capture))
		row.add_child(icon_lbl)
		row.add_child(name_lbl)
		row.add_child(cost_lbl)
		row.add_child(buy_btn)
		shop_item_list.add_child(row)

# ─── Summon tab ────────────────────────────────────────────────────────────────

func _on_open_chest() -> void:
	keys_label.text = "🗝 Keys: %d" % RankSystem.keys_available
	summon_result_lbl.text = "Opening…"
	if chest_anim:
		chest_anim.play("open")
	await get_tree().create_timer(0.6).timeout
	ShopSystem.open_chest()
	keys_label.text = "🗝 Keys: %d" % RankSystem.keys_available

func _on_summon_result(item: Dictionary) -> void:
	var rarity_color: Dictionary = {
		"common": Color.WHITE, "uncommon": Color.CYAN,
		"rare": Color.DODGER_BLUE, "epic": Color(0.6, 0.0, 1.0),
		"legendary": Color.ORANGE
	}
	var col  := rarity_color.get(item.get("rarity", "common"), Color.WHITE)
	summon_result_lbl.text = "%s %s [%s]!" % [item["icon"], item["name"], item["rarity"].capitalize()]
	summon_result_lbl.add_theme_color_override("font_color", col)

# ─── Enhance tab ───────────────────────────────────────────────────────────────

func _refresh_enhance_list() -> void:
	for c in inv_enhance_list.get_children():
		c.queue_free()
	selected_inv_slot = -1
	enhance_btn.disabled = true
	for i in InventorySystem.MAX_SLOTS:
		var item := InventorySystem.get_item(i)
		if item.is_empty() or item.get("type") == "consumable":
			continue
		var btn  := Button.new()
		var lvl  := item.get("enhance_level", 0)
		btn.text = "%s %s +%d" % [item["icon"], item["name"], lvl]
		btn.toggle_mode = true
		var idx_capture  := i
		btn.pressed.connect(func(): _select_enhance_slot(idx_capture, btn))
		inv_enhance_list.add_child(btn)

func _select_enhance_slot(slot: int, btn: Button) -> void:
	selected_inv_slot    = slot
	enhance_btn.disabled = false
	var item := InventorySystem.get_item(slot)
	var lvl  := item.get("enhance_level", 0)
	var cost := ShopSystem.ENHANCE_COST_BASE * (lvl + 1)
	var pct  := ShopSystem.ENHANCE_SUCCESS_PCT[min(lvl, ShopSystem.ENHANCE_SUCCESS_PCT.size()-1)]
	enhance_info.text = "Level %d → %d\nCost: 💰%d\nSuccess: %d%%" % [lvl, lvl+1, cost, pct]

func _on_enhance() -> void:
	if selected_inv_slot < 0:
		return
	ShopSystem.enhance_item(selected_inv_slot)

func _on_enhance_result(success: bool, new_level: int, item: Dictionary) -> void:
	if success:
		enhance_result_lbl.text = "✅ Success! +%d" % new_level
		enhance_result_lbl.add_theme_color_override("font_color", Color.GREEN)
	else:
		enhance_result_lbl.text = "❌ Failed!"
		enhance_result_lbl.add_theme_color_override("font_color", Color.RED)
	_refresh_enhance_list()
	var tween := create_tween()
	tween.tween_interval(2.5)
	tween.tween_callback(func(): enhance_result_lbl.text = "")

# ─── Misc ──────────────────────────────────────────────────────────────────────

func _on_purchase_result(success: bool, msg: String) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_popup"):
		hud.show_popup(msg, Color.GREEN if success else Color.RED)

func _on_close() -> void:
	GameManager.exit_shop()
	queue_free()
