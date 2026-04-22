extends Control

const SLOT_SIZE  := Vector2(64, 64)
const SLOT_COLS  := 6

@onready var slot_grid:     GridContainer  = $InventoryPanel/ScrollContainer/SlotGrid
@onready var equip_panel:   PanelContainer = $EquipPanel
@onready var info_panel:    PanelContainer = $InfoPanel
@onready var info_icon:     Label          = $InfoPanel/Icon
@onready var info_name:     Label          = $InfoPanel/NameLabel
@onready var info_type:     Label          = $InfoPanel/TypeLabel
@onready var info_stats:    Label          = $InfoPanel/StatsLabel
@onready var action_equip:  Button         = $InfoPanel/EquipButton
@onready var action_use:    Button         = $InfoPanel/UseButton
@onready var action_sell:   Button         = $InfoPanel/SellButton
@onready var close_btn:     Button         = $CloseButton
@onready var gold_label:    Label          = $GoldLabel

# Equipment display labels (keyed by slot name)
var equip_labels: Dictionary = {}

var slot_buttons:    Array[Button]     = []
var selected_slot:   int               = -1
var dragging:        bool              = false
var drag_from_slot:  int               = -1
var drag_preview:    Control           = null

func _ready() -> void:
	close_btn.pressed.connect(_on_close)
	action_equip.pressed.connect(_on_equip_pressed)
	action_use.pressed.connect(_on_use_pressed)
	action_sell.pressed.connect(_on_sell_pressed)

	InventorySystem.inventory_changed.connect(_refresh)
	GameManager.gold_changed.connect(func(v): gold_label.text = "💰 %d" % v)

	gold_label.text = "💰 %d" % GameManager.gold
	_build_equip_panel()
	_build_slot_grid()
	_refresh()

# ─── Build grid ────────────────────────────────────────────────────────────────

func _build_slot_grid() -> void:
	slot_grid.columns = SLOT_COLS
	for i in InventorySystem.MAX_SLOTS:
		var btn := Button.new()
		btn.custom_minimum_size = SLOT_SIZE
		btn.flat = false
		var idx_capture := i
		btn.pressed.connect(func(): _on_slot_clicked(idx_capture))
		btn.gui_input.connect(func(ev): _on_slot_gui_input(idx_capture, ev))
		slot_grid.add_child(btn)
		slot_buttons.append(btn)

func _build_equip_panel() -> void:
	var slots_order := ["weapon","head","chest","legs","offhand","accessory"]
	var icons       := {"weapon":"⚔️","head":"⛑️","chest":"🥋","legs":"👢","offhand":"🛡️","accessory":"💍"}
	var vbox := equip_panel.get_node_or_null("VBoxContainer")
	if not vbox:
		return
	for slot_name in slots_order:
		var row  := HBoxContainer.new()
		var lbl  := Label.new()
		lbl.text = "%s %s:" % [icons.get(slot_name,""), slot_name.capitalize()]
		lbl.custom_minimum_size = Vector2(130, 0)
		var val_lbl := Label.new()
		val_lbl.text = "—"
		val_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var unequip_btn := Button.new()
		unequip_btn.text = "X"
		unequip_btn.custom_minimum_size = Vector2(30, 0)
		var sn_capture := slot_name
		unequip_btn.pressed.connect(func(): InventorySystem.unequip_slot(sn_capture))
		row.add_child(lbl)
		row.add_child(val_lbl)
		row.add_child(unequip_btn)
		vbox.add_child(row)
		equip_labels[slot_name] = val_lbl

# ─── Refresh ───────────────────────────────────────────────────────────────────

func _refresh() -> void:
	for i in slot_buttons.size():
		var btn   := slot_buttons[i]
		var item  := InventorySystem.get_item(i)
		if item.is_empty():
			btn.text     = ""
			btn.tooltip_text = ""
		else:
			var lvl  := item.get("enhance_level", 0)
			var enh  := ("+%d " % lvl) if lvl > 0 else ""
			btn.text = "%s\n%s%s" % [item["icon"], enh, item["name"]]
			btn.tooltip_text = "%s\n%s\n%s" % [item["name"], item.get("rarity","").capitalize(),
			                                    _stats_text(item)]
		if i == selected_slot:
			btn.modulate = Color(1.2, 1.2, 0.5)
		else:
			btn.modulate = Color.WHITE

	for slot_name in equip_labels:
		var eq := InventorySystem.get_equipped(slot_name)
		if eq.is_empty():
			equip_labels[slot_name].text = "—"
		else:
			var lvl := eq.get("enhance_level", 0)
			equip_labels[slot_name].text = "%s %s%s" % [eq["icon"], "+%d " % lvl if lvl > 0 else "", eq["name"]]

func _stats_text(item: Dictionary) -> String:
	if not item.has("stats"):
		return ""
	var parts: Array[String] = []
	for k in item["stats"]:
		parts.append("%s+%d" % [k, item["stats"][k]])
	return "  ".join(parts)

# ─── Slot interaction ──────────────────────────────────────────────────────────

func _on_slot_clicked(idx: int) -> void:
	selected_slot = idx
	_refresh()
	var item := InventorySystem.get_item(idx)
	if item.is_empty():
		_clear_info()
		return
	info_icon.text  = item["icon"]
	info_name.text  = item["name"]
	info_type.text  = item.get("type","").capitalize() + "  [" + item.get("rarity","").capitalize() + "]"
	info_stats.text = _stats_text(item)
	action_equip.visible = item.get("type") in ["weapon","head","chest","legs","offhand","accessory"]
	action_use.visible   = item.get("type") == "consumable"
	action_sell.visible  = true

func _clear_info() -> void:
	info_icon.text  = ""
	info_name.text  = "Select an item"
	info_type.text  = ""
	info_stats.text = ""
	action_equip.visible = false
	action_use.visible   = false
	action_sell.visible  = false

func _on_slot_gui_input(idx: int, event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
		var item := InventorySystem.get_item(idx)
		if item.is_empty():
			return
		var t := item.get("type","")
		if t in ["weapon","head","chest","legs","offhand","accessory"]:
			InventorySystem.equip_item(idx)
		elif t == "consumable":
			_use_consumable(idx)

# ─── Actions ───────────────────────────────────────────────────────────────────

func _on_equip_pressed() -> void:
	if selected_slot >= 0:
		InventorySystem.equip_item(selected_slot)
		selected_slot = -1
		_clear_info()

func _on_use_pressed() -> void:
	if selected_slot >= 0:
		_use_consumable(selected_slot)

func _use_consumable(slot: int) -> void:
	var item   := InventorySystem.get_item(slot)
	if item.is_empty():
		return
	var player := GameManager.player_ref as PlayerController
	if player:
		player.stats.heal(item.get("heal", 50))
	InventorySystem.consume_item(item["id"])
	selected_slot = -1
	_clear_info()

func _on_sell_pressed() -> void:
	if selected_slot >= 0:
		ShopSystem.sell_item(selected_slot)
		selected_slot = -1
		_clear_info()

func _on_close() -> void:
	GameManager.exit_inventory()
	queue_free()
