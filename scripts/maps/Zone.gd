class_name Zone
extends Node2D

@export var zone_type:        GameManager.ZoneType = GameManager.ZoneType.TOWN
@export var background_color: Color                = Color(0.15, 0.35, 0.15)
@export var ambient_light:    float                = 0.8

@onready var tilemap:      TileMap      = $TileMap
@onready var spawner:      EnemySpawner = $EnemySpawner
@onready var player_spawn: Marker2D     = $PlayerSpawn
@onready var hud_layer:    CanvasLayer  = $HUD
@onready var shop_ui_layer: CanvasLayer = $ShopLayer
@onready var inv_ui_layer:  CanvasLayer = $InvLayer

const PLAYER_SCENE         := "res://scenes/entities/Player.tscn"
const SHOP_UI_SCENE        := "res://scenes/ui/Shop.tscn"
const INV_UI_SCENE         := "res://scenes/ui/Inventory.tscn"
const TOUCH_CONTROLS_SCENE := "res://scenes/ui/TouchControls.tscn"

var player: PlayerController = null
var shop_ui_instance:  Control = null
var inv_ui_instance:   Control = null

func _ready() -> void:
	GameManager.current_zone = zone_type
	_spawn_player()
	_setup_background()

	GameManager.enter_shop.connect    # — not a signal; watch state instead
	# Watch UI state changes each frame

func _process(_delta: float) -> void:
	_check_ui_state()

func _spawn_player() -> void:
	var scene := load(PLAYER_SCENE) as PackedScene
	if not scene:
		return
	player = scene.instantiate() as PlayerController
	add_child(player)
	if player_spawn:
		player.global_position = player_spawn.global_position
	GameManager.player_ref = player
	_spawn_touch_controls()

func _spawn_touch_controls() -> void:
	var scene := load(TOUCH_CONTROLS_SCENE) as PackedScene
	if not scene:
		return
	var tc := scene.instantiate()
	tc.get_node("Root").add_to_group("touch_controls")
	add_child(tc)

func _setup_background() -> void:
	var backdrop := ColorRect.new()
	backdrop.color     = background_color
	backdrop.size      = Vector2(4096, 4096)
	backdrop.position  = Vector2(-2048, -2048)
	backdrop.z_index   = -10
	add_child(backdrop)

func _check_ui_state() -> void:
	# Shop UI
	if GameManager.current_state == GameManager.GameState.IN_SHOP:
		if shop_ui_instance == null or not is_instance_valid(shop_ui_instance):
			var scene := load(SHOP_UI_SCENE) as PackedScene
			if scene:
				shop_ui_instance = scene.instantiate() as Control
				shop_ui_layer.add_child(shop_ui_instance)
	else:
		if shop_ui_instance and is_instance_valid(shop_ui_instance):
			shop_ui_instance.queue_free()
			shop_ui_instance = null

	# Inventory UI
	if GameManager.current_state == GameManager.GameState.IN_INVENTORY:
		if inv_ui_instance == null or not is_instance_valid(inv_ui_instance):
			var scene := load(INV_UI_SCENE) as PackedScene
			if scene:
				inv_ui_instance = scene.instantiate() as Control
				inv_ui_layer.add_child(inv_ui_instance)
	else:
		if inv_ui_instance and is_instance_valid(inv_ui_instance):
			inv_ui_instance.queue_free()
			inv_ui_instance = null
