class_name TownNPC
extends CharacterBody2D

@export var npc_name:    String = "Guard"
@export var dialogue:    Array[String] = ["Hello, traveler!"]
@export var is_shopkeeper: bool = false

@onready var sprite:      AnimatedSprite2D = $AnimatedSprite2D
@onready var name_label:  Label            = $NameLabel
@onready var interact_lbl: Label           = $InteractLabel
@onready var dialog_box:  PanelContainer   = $DialogBox
@onready var dialog_text: Label            = $DialogBox/Label

var player_nearby: bool    = false
var dialog_index:  int     = 0

func _ready() -> void:
	add_to_group("shop_npc" if is_shopkeeper else "npc")
	name_label.text  = npc_name
	interact_lbl.hide()
	dialog_box.hide()
	$InteractArea.body_entered.connect(_on_player_enter)
	$InteractArea.body_exited.connect(_on_player_exit)

func _process(_delta: float) -> void:
	if player_nearby and Input.is_action_just_pressed("attack"):
		_advance_dialogue()

func _on_player_enter(body: Node) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		interact_lbl.show()

func _on_player_exit(body: Node) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		interact_lbl.hide()
		dialog_box.hide()
		dialog_index = 0

func _advance_dialogue() -> void:
	if not dialog_box.visible:
		dialog_index = 0
		dialog_box.show()

	if dialog_index < dialogue.size():
		dialog_text.text = dialogue[dialog_index]
		dialog_index    += 1
	else:
		dialog_box.hide()
		dialog_index = 0
		if is_shopkeeper:
			GameManager.enter_shop()
