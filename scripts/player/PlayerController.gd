class_name PlayerController
extends CharacterBody2D

# ─── Nodes ─────────────────────────────────────────────────────────────────────
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area:     Area2D           = $AttackArea
@onready var attack_shape:    CollisionShape2D = $AttackArea/CollisionShape2D
@onready var hurt_area:       Area2D           = $HurtArea
@onready var stats:           PlayerStats      = $PlayerStats
@onready var camera:          Camera2D         = $Camera2D
@onready var level_up_fx:     GPUParticles2D   = $LevelUpFX
@onready var attack_fx:       GPUParticles2D   = $AttackFX
@onready var hud:             CanvasLayer      = null   # injected after scene load

var _touch_controls: TouchControlsManager = null

# ─── State ─────────────────────────────────────────────────────────────────────
enum State { IDLE, WALK, ATTACK, HIT, DEAD, DODGE }

var current_state: State = State.IDLE
var facing_dir:    Vector2 = Vector2.RIGHT
var attack_cooldown:  float = 0.0
const ATTACK_COOLDOWN := 0.5
var attack_duration:  float = 0.0
const ATTACK_DURATION  := 0.25

var hit_flash_timer: float = 0.0
var dodge_timer:     float = 0.0
const DODGE_DURATION   := 0.35
const DODGE_SPEED      := 500.0
var dodge_direction: Vector2 = Vector2.ZERO
var is_invincible:   bool    = false

var knockback: Vector2 = Vector2.ZERO
const KNOCKBACK_DECAY := 8.0

# ─── Ready ─────────────────────────────────────────────────────────────────────

func _ready() -> void:
	GameManager.player_ref = self
	stats.hp_changed.connect(_on_hp_changed)
	stats.leveled_up.connect(_on_leveled_up)
	stats.died.connect(_on_died)
	hurt_area.area_entered.connect(_on_hurt_area_entered)
	attack_shape.disabled = true

	add_to_group("player")
	_play_anim("idle")
	# Grab touch controls if present
	await get_tree().process_frame
	var tc := get_tree().get_first_node_in_group("touch_controls")
	if tc is TouchControlsManager:
		_touch_controls = tc

# ─── Process ───────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if current_state == State.DEAD:
		return
	_tick_timers(delta)
	_handle_input()
	_update_animation()

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return
	if current_state == State.DODGE:
		velocity = dodge_direction * DODGE_SPEED
	else:
		var move_input := _get_move_input()
		if move_input != Vector2.ZERO:
			facing_dir = move_input
		if current_state == State.ATTACK or current_state == State.HIT:
			velocity = move_input * stats.effective_speed() * 0.3
		else:
			velocity = move_input * stats.effective_speed()

	knockback = knockback.lerp(Vector2.ZERO, KNOCKBACK_DECAY * delta)
	velocity  += knockback
	move_and_slide()

# ─── Input ─────────────────────────────────────────────────────────────────────

func _handle_input() -> void:
	if current_state in [State.DEAD, State.ATTACK, State.HIT]:
		return

	# Dodge (spacebar)
	if Input.is_action_just_pressed("dodge") and current_state != State.DODGE:
		_start_dodge()
		return

	# Attack (LMB)
	if Input.is_action_just_pressed("attack") and attack_cooldown <= 0.0:
		_start_attack()
		return

	# Use potion
	if Input.is_action_just_pressed("use_potion"):
		_use_potion()

	# Open inventory
	if Input.is_action_just_pressed("open_inventory"):
		_toggle_inventory()

	# Open shop (near NPC)
	if Input.is_action_just_pressed("open_shop"):
		_try_open_shop()

	# Pause
	if Input.is_action_just_pressed("pause"):
		GameManager.pause_game()

func _get_move_input() -> Vector2:
	if current_state == State.DODGE:
		return dodge_direction
	# Keyboard
	var kb_dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	if kb_dir.length_squared() > 0.01:
		return kb_dir.normalized()
	# Virtual joystick (touch)
	if _touch_controls:
		var joy_dir := _touch_controls.get_move_direction()
		if joy_dir.length_squared() > 0.01:
			return joy_dir
	return Vector2.ZERO

# ─── Actions ───────────────────────────────────────────────────────────────────

func _start_attack() -> void:
	current_state    = State.ATTACK
	attack_duration  = ATTACK_DURATION
	attack_cooldown  = ATTACK_COOLDOWN
	attack_shape.disabled = false
	_position_attack_area()
	_play_anim("attack")
	if attack_fx:
		attack_fx.restart()
	_deal_attack_damage()

func _deal_attack_damage() -> void:
	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("enemy") and body.has_method("take_damage"):
			var dmg := CombatSystem.calculate_damage(
				stats.effective_attack(), body.stats.defense
			)
			body.take_damage(dmg, global_position)

func _position_attack_area() -> void:
	attack_area.position = facing_dir * 36.0

func _start_dodge() -> void:
	current_state    = State.DODGE
	dodge_direction  = _get_move_input()
	if dodge_direction == Vector2.ZERO:
		dodge_direction = facing_dir
	dodge_timer      = DODGE_DURATION
	is_invincible    = true
	animated_sprite.modulate.a = 0.5

func _use_potion() -> void:
	# Try small potion first, then large, then elixir
	for potion_id in ["potion_small", "potion_large", "elixir"]:
		if InventorySystem.count_item(potion_id) > 0:
			var heal_amount := 50 if potion_id == "potion_small" else (150 if potion_id == "potion_large" else 9999)
			if InventorySystem.consume_item(potion_id):
				stats.heal(heal_amount)
				return

func _toggle_inventory() -> void:
	if GameManager.current_state == GameManager.GameState.IN_INVENTORY:
		GameManager.exit_inventory()
	else:
		GameManager.enter_inventory()

func _try_open_shop() -> void:
	for body in get_tree().get_nodes_in_group("shop_npc"):
		if global_position.distance_to(body.global_position) < 120.0:
			GameManager.enter_shop()
			return

# ─── Timer ticks ───────────────────────────────────────────────────────────────

func _tick_timers(delta: float) -> void:
	if attack_cooldown > 0.0:
		attack_cooldown -= delta

	if attack_duration > 0.0:
		attack_duration -= delta
		if attack_duration <= 0.0:
			attack_shape.disabled = true
			if current_state == State.ATTACK:
				current_state = State.IDLE

	if hit_flash_timer > 0.0:
		hit_flash_timer -= delta
		if hit_flash_timer <= 0.0:
			animated_sprite.modulate = Color.WHITE
			if current_state == State.HIT:
				current_state = State.IDLE

	if dodge_timer > 0.0:
		dodge_timer -= delta
		if dodge_timer <= 0.0:
			is_invincible = false
			animated_sprite.modulate.a = 1.0
			current_state = State.IDLE

# ─── Signals from stats ────────────────────────────────────────────────────────

func take_hit(damage: int, from_position: Vector2) -> void:
	if is_invincible or current_state == State.DEAD:
		return
	stats.take_damage(damage)
	knockback = CombatSystem.knockback_vector(from_position, global_position, 250.0)

func _on_hp_changed(current: int, maximum: int) -> void:
	if current > 0 and current_state != State.DEAD:
		current_state   = State.HIT
		hit_flash_timer = 0.3
		animated_sprite.modulate = Color(1.5, 0.3, 0.3)

func _on_leveled_up(new_level: int) -> void:
	if level_up_fx:
		level_up_fx.restart()

func _on_hurt_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_attack"):
		var enemy: Node = area.get_parent()
		if enemy and enemy.has_method("get_attack_damage"):
			var dmg := CombatSystem.calculate_damage(
				enemy.get_attack_damage(), stats.effective_defense()
			)
			take_hit(dmg, enemy.global_position)

func _on_died() -> void:
	current_state = State.DEAD
	_play_anim("death")
	set_physics_process(false)
	await get_tree().create_timer(1.5).timeout
	GameManager.trigger_game_over()

# ─── Animation ─────────────────────────────────────────────────────────────────

func _update_animation() -> void:
	match current_state:
		State.IDLE:
			_play_anim("idle")
		State.WALK:
			if _get_move_input() != Vector2.ZERO:
				_play_anim("walk")
				current_state = State.WALK
			else:
				_play_anim("idle")
				current_state = State.IDLE
		_:
			pass  # attack / hit / dodge handled in their own calls

	if _get_move_input() != Vector2.ZERO and current_state == State.IDLE:
		current_state = State.WALK

	if facing_dir.x < 0:
		animated_sprite.flip_h = true
	elif facing_dir.x > 0:
		animated_sprite.flip_h = false

func _play_anim(anim: String) -> void:
	if animated_sprite.animation != anim:
		animated_sprite.play(anim)
