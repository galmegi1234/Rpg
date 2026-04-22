class_name EnemyAI
extends CharacterBody2D

# ─── Enemy data (set per instance or via spawn) ────────────────────────────────
@export var enemy_name:   String = "Slime"
@export var max_hp:       int    = 40
@export var attack_power: int    = 8
@export var defense_val:  int    = 2
@export var move_speed:   float  = 80.0
@export var xp_reward:    int    = 30
@export var gold_min:     int    = 3
@export var gold_max:     int    = 8
@export var detect_range: float  = 200.0
@export var attack_range: float  = 45.0
@export var attack_cd:    float  = 1.2
@export var drop_table:   Array[Dictionary] = []

# ─── Internal state ────────────────────────────────────────────────────────────
enum AIState { IDLE, PATROL, CHASE, ATTACK, HIT, DEAD }

var ai_state:         AIState = AIState.IDLE
var hp:               int     = 40
var attack_timer:     float   = 0.0
var hit_flash_timer:  float   = 0.0
var patrol_timer:     float   = 0.0
var patrol_direction: Vector2 = Vector2.RIGHT
var target:           Node    = null

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var nav_agent:       NavigationAgent2D = $NavigationAgent2D
@onready var attack_hitbox:   Area2D            = $AttackHitbox
@onready var detect_area:     Area2D            = $DetectArea
@onready var hp_bar:          ProgressBar       = $HPBar

# Drop particles / label node paths (optional, may not exist in all enemies)
var _drop_label: Label = null

# ─── Ready ─────────────────────────────────────────────────────────────────────

func _ready() -> void:
	hp = max_hp
	add_to_group("enemy")
	attack_hitbox.add_to_group("enemy_attack")
	attack_hitbox.monitoring = false

	detect_area.body_entered.connect(_on_detect_area_body_entered)
	detect_area.body_exited.connect(_on_detect_area_body_exited)

	hp_bar.max_value = max_hp
	hp_bar.value     = hp

	patrol_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

	nav_agent.path_desired_distance   = 4.0
	nav_agent.target_desired_distance = 12.0

func _physics_process(delta: float) -> void:
	if ai_state == AIState.DEAD:
		return
	_tick_timers(delta)
	_run_state_machine(delta)
	move_and_slide()

# ─── State machine ─────────────────────────────────────────────────────────────

func _run_state_machine(delta: float) -> void:
	match ai_state:
		AIState.IDLE:
			velocity = Vector2.ZERO
			patrol_timer -= delta
			if patrol_timer <= 0.0:
				ai_state         = AIState.PATROL
				patrol_timer     = randf_range(1.5, 3.5)
				patrol_direction = Vector2(randf_range(-1,1), randf_range(-1,1)).normalized()
			_play_anim("idle")

		AIState.PATROL:
			velocity      = patrol_direction * move_speed * 0.5
			patrol_timer -= delta
			if patrol_timer <= 0.0:
				ai_state     = AIState.IDLE
				patrol_timer = randf_range(2.0, 4.0)
			_play_anim("walk")

		AIState.CHASE:
			if not is_instance_valid(target):
				ai_state = AIState.PATROL
				return
			var dist := global_position.distance_to(target.global_position)
			if dist > detect_range * 1.5:
				ai_state = AIState.PATROL
				target   = null
				return
			if dist <= attack_range:
				ai_state = AIState.ATTACK
				return
			nav_agent.target_position = target.global_position
			var next_pos := nav_agent.get_next_path_position()
			var dir      := (next_pos - global_position).normalized()
			velocity     = dir * move_speed
			_face_target()
			_play_anim("walk")

		AIState.ATTACK:
			velocity = Vector2.ZERO
			if not is_instance_valid(target):
				ai_state = AIState.PATROL
				return
			var dist := global_position.distance_to(target.global_position)
			if dist > attack_range * 1.3:
				ai_state = AIState.CHASE
				return
			if attack_timer <= 0.0:
				_do_attack()
			_face_target()
			_play_anim("attack")

		AIState.HIT:
			velocity    = velocity.lerp(Vector2.ZERO, 0.2)

		AIState.DEAD:
			velocity = Vector2.ZERO

# ─── Combat ────────────────────────────────────────────────────────────────────

func take_damage(amount: int, from_position: Vector2 = Vector2.ZERO) -> void:
	if ai_state == AIState.DEAD:
		return
	hp = max(0, hp - amount)
	hp_bar.value = hp
	_show_damage_label(amount)

	if hp == 0:
		_die()
		return

	ai_state        = AIState.HIT
	hit_flash_timer = 0.25
	animated_sprite.modulate = Color(1.5, 0.3, 0.3)

	# knock back
	if from_position != Vector2.ZERO:
		var kb_dir  := (global_position - from_position).normalized()
		velocity    = kb_dir * 180.0

	if is_instance_valid(target) == false:
		target   = get_tree().get_first_node_in_group("player")
		ai_state = AIState.CHASE

func get_attack_damage() -> int:
	return attack_power

func _do_attack() -> void:
	attack_timer            = attack_cd
	attack_hitbox.monitoring = true
	_play_anim("attack")
	# Deal damage to player if in range
	if is_instance_valid(target) and global_position.distance_to(target.global_position) <= attack_range:
		if target.has_method("take_hit"):
			var dmg := CombatSystem.calculate_damage(attack_power, 0)
			target.take_hit(dmg, global_position)
	await get_tree().create_timer(0.15).timeout
	if is_instance_valid(self):
		attack_hitbox.monitoring = false

func _die() -> void:
	ai_state = AIState.DEAD
	_play_anim("death")
	set_physics_process(false)
	hp_bar.hide()

	var player := get_tree().get_first_node_in_group("player") as PlayerController
	if player:
		var xp := CombatSystem.calculate_xp_reward(int(xp_reward / 15), player.stats.level)
		player.stats.gain_xp(xp)
		GameManager.add_monster_kill()
		var gold := CombatSystem.calculate_gold_drop(int(xp_reward / 15))
		GameManager.add_gold(gold)
		_spawn_drops()

	await get_tree().create_timer(0.8).timeout
	if is_instance_valid(self):
		queue_free()

func _spawn_drops() -> void:
	for drop in drop_table:
		if randi() % 100 < drop.get("chance", 30):
			InventorySystem.add_item(drop.duplicate(true))

# ─── Detection ─────────────────────────────────────────────────────────────────

func _on_detect_area_body_entered(body: Node) -> void:
	if body.is_in_group("player") and ai_state != AIState.DEAD:
		target   = body
		ai_state = AIState.CHASE

func _on_detect_area_body_exited(body: Node) -> void:
	if body == target:
		await get_tree().create_timer(3.0).timeout
		if is_instance_valid(self) and ai_state == AIState.CHASE:
			target   = null
			ai_state = AIState.PATROL

# ─── Helpers ───────────────────────────────────────────────────────────────────

func _tick_timers(delta: float) -> void:
	if attack_timer > 0.0:
		attack_timer -= delta

	if hit_flash_timer > 0.0:
		hit_flash_timer -= delta
		if hit_flash_timer <= 0.0:
			animated_sprite.modulate = Color.WHITE
			if ai_state == AIState.HIT:
				ai_state = AIState.CHASE if is_instance_valid(target) else AIState.PATROL

func _face_target() -> void:
	if not is_instance_valid(target):
		return
	var diff := target.global_position - global_position
	if diff.x < 0:
		animated_sprite.flip_h = true
	elif diff.x > 0:
		animated_sprite.flip_h = false

func _play_anim(anim: String) -> void:
	if animated_sprite.animation != anim:
		animated_sprite.play(anim)

func _show_damage_label(amount: int) -> void:
	var lbl := Label.new()
	lbl.text = "-%d" % amount
	lbl.add_theme_color_override("font_color", Color.RED)
	lbl.add_theme_font_size_override("font_size", 18)
	get_tree().current_scene.add_child(lbl)
	lbl.global_position = global_position + Vector2(-10, -30)
	var tween := lbl.create_tween()
	tween.tween_property(lbl, "position:y", lbl.position.y - 40, 0.7)
	tween.parallel().tween_property(lbl, "modulate:a", 0.0, 0.7)
	tween.tween_callback(lbl.queue_free)
