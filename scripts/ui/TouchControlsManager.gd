extends Control

@onready var joystick:      VirtualJoystick = $Joystick
@onready var attack_btn:    Button = $RightButtons/AttackButton
@onready var potion_btn:    Button = $RightButtons/PotionButton
@onready var dodge_btn:     Button = $RightButtons/DodgeButton
@onready var inv_btn:       Button = $TopButtons/InvButton
@onready var shop_btn:      Button = $TopButtons/ShopButton
@onready var menu_btn:      Button = $TopButtons/MenuButton

func _ready() -> void:
	attack_btn.pressed.connect(_on_attack)
	potion_btn.pressed.connect(_on_potion)
	dodge_btn.pressed.connect(_on_dodge)
	inv_btn.pressed.connect(_on_inv)
	shop_btn.pressed.connect(_on_shop)
	menu_btn.pressed.connect(_on_menu)

	# Only show on touch devices
	visible = DisplayServer.is_touchscreen_available()

func get_move_direction() -> Vector2:
	return joystick.get_direction()

func _on_attack() -> void:
	var player := GameManager.player_ref as PlayerController
	if player and player.attack_cooldown <= 0.0:
		player._start_attack()

func _on_potion() -> void:
	var player := GameManager.player_ref as PlayerController
	if player:
		player._use_potion()

func _on_dodge() -> void:
	var player := GameManager.player_ref as PlayerController
	if player:
		player._start_dodge()

func _on_inv() -> void:
	if GameManager.current_state == GameManager.GameState.IN_INVENTORY:
		GameManager.exit_inventory()
	else:
		GameManager.enter_inventory()

func _on_shop() -> void:
	if GameManager.current_state == GameManager.GameState.IN_SHOP:
		GameManager.exit_shop()
	else:
		GameManager.enter_shop()

func _on_menu() -> void:
	if GameManager.current_state == GameManager.GameState.PAUSED:
		GameManager.resume_game()
	else:
		GameManager.pause_game()
