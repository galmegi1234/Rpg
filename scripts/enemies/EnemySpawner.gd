class_name EnemySpawner
extends Node2D

@export var zone: GameManager.ZoneType = GameManager.ZoneType.PLAINS
@export var max_enemies: int  = 8
@export var spawn_radius: float = 300.0
@export var respawn_time: float = 8.0

const ENEMY_SCENE := "res://scenes/entities/Enemy.tscn"

const ZONE_CONFIGS: Dictionary = {
	GameManager.ZoneType.PLAINS: {
		"enemies": [
			{
				"name": "Slime", "max_hp": 40, "attack": 8,
				"defense": 1, "speed": 70.0, "xp": 15, "gold_min": 2, "gold_max": 5,
				"detect": 180.0, "attack_range": 40.0, "color": Color.GREEN,
				"drops": [
					{"id":"potion_small","name":"Small Potion","type":"consumable",
					 "icon":"🧪","value":30,"stackable":true,"rarity":"common","stats":{},"heal":50,"count":1,"chance":25}
				]
			},
			{
				"name": "Goblin", "max_hp": 60, "attack": 12,
				"defense": 3, "speed": 100.0, "xp": 25, "gold_min": 4, "gold_max": 10,
				"detect": 220.0, "attack_range": 45.0, "color": Color(0.4,0.8,0.2),
				"drops": [
					{"id":"sword_iron","name":"Iron Sword","type":"weapon",
					 "icon":"⚔️","value":150,"stackable":false,"rarity":"common",
					 "stats":{"attack":10},"enhance_level":0,"chance":10}
				]
			},
		],
		"weight": [60, 40]
	},
	GameManager.ZoneType.FOREST: {
		"enemies": [
			{
				"name": "Forest Wolf", "max_hp": 100, "attack": 18,
				"defense": 5, "speed": 120.0, "xp": 45, "gold_min": 8, "gold_max": 18,
				"detect": 250.0, "attack_range": 50.0, "color": Color(0.4,0.2,0.0),
				"drops": [
					{"id":"armor_leather","name":"Leather Armor","type":"chest",
					 "icon":"🥋","value":120,"stackable":false,"rarity":"common",
					 "stats":{"defense":8},"enhance_level":0,"chance":15}
				]
			},
			{
				"name": "Dark Elf", "max_hp": 80, "attack": 22,
				"defense": 8, "speed": 130.0, "xp": 55, "gold_min": 12, "gold_max": 25,
				"detect": 270.0, "attack_range": 42.0, "color": Color(0.3,0.0,0.5),
				"drops": [
					{"id":"sword_steel","name":"Steel Sword","type":"weapon",
					 "icon":"🗡️","value":400,"stackable":false,"rarity":"uncommon",
					 "stats":{"attack":25},"enhance_level":0,"chance":8}
				]
			},
		],
		"weight": [50, 50]
	},
	GameManager.ZoneType.DUNGEON: {
		"enemies": [
			{
				"name": "Skeleton Knight", "max_hp": 180, "attack": 30,
				"defense": 15, "speed": 90.0, "xp": 90, "gold_min": 20, "gold_max": 40,
				"detect": 300.0, "attack_range": 55.0, "color": Color.WHITE,
				"drops": [
					{"id":"armor_chain","name":"Chainmail","type":"chest",
					 "icon":"🛡️","value":350,"stackable":false,"rarity":"uncommon",
					 "stats":{"defense":20},"enhance_level":0,"chance":12}
				]
			},
			{
				"name": "Dungeon Boss", "max_hp": 500, "attack": 55,
				"defense": 25, "speed": 70.0, "xp": 300, "gold_min": 80, "gold_max": 150,
				"detect": 350.0, "attack_range": 60.0, "color": Color(0.8,0.0,0.0),
				"drops": [
					{"id":"ring_power","name":"Ring of Power","type":"accessory",
					 "icon":"💍","value":0,"stackable":false,"rarity":"epic",
					 "stats":{"attack":30,"defense":15},"enhance_level":0,"chance":50}
				]
			},
		],
		"weight": [70, 30]
	},
}

var active_enemies:  Array[Node] = []
var spawn_timers:    Array[float] = []

func _ready() -> void:
	if zone == GameManager.ZoneType.TOWN:
		return
	_initial_spawn()

func _process(delta: float) -> void:
	if zone == GameManager.ZoneType.TOWN:
		return
	for i in spawn_timers.size():
		spawn_timers[i] -= delta
		if spawn_timers[i] <= 0.0:
			spawn_timers.remove_at(i)
			_spawn_one()
			break
	active_enemies = active_enemies.filter(func(e): return is_instance_valid(e))
	while active_enemies.size() < max_enemies:
		_spawn_one()

func _initial_spawn() -> void:
	for i in max_enemies:
		_spawn_one()

func _spawn_one() -> void:
	if not ZONE_CONFIGS.has(zone):
		return
	var cfg: Dictionary = ZONE_CONFIGS[zone]
	var template := _pick_weighted(cfg["enemies"], cfg["weight"])
	var enemy_scene := load(ENEMY_SCENE) as PackedScene
	if not enemy_scene:
		return
	var enemy := enemy_scene.instantiate() as EnemyAI
	enemy.enemy_name   = template["name"]
	enemy.max_hp       = template["max_hp"]
	enemy.attack_power = template["attack"]
	enemy.defense_val  = template["defense"]
	enemy.move_speed   = template["speed"]
	enemy.xp_reward    = template["xp"]
	enemy.gold_min     = template["gold_min"]
	enemy.gold_max     = template["gold_max"]
	enemy.detect_range = template["detect"]
	enemy.attack_range = template["attack_range"]
	enemy.drop_table   = template["drops"].duplicate(true)

	var offset  := Vector2(randf_range(-spawn_radius, spawn_radius),
	                       randf_range(-spawn_radius, spawn_radius))
	enemy.global_position = global_position + offset
	get_tree().current_scene.add_child(enemy)

	# Color-code sprite to identify enemy type
	if enemy.get_node_or_null("AnimatedSprite2D"):
		enemy.get_node("AnimatedSprite2D").modulate = template.get("color", Color.WHITE)

	active_enemies.append(enemy)
	enemy.tree_exited.connect(func(): _schedule_respawn())

func _schedule_respawn() -> void:
	spawn_timers.append(respawn_time)

func _pick_weighted(items: Array, weights: Array) -> Dictionary:
	var total := 0
	for w in weights:
		total += w
	var roll := randi() % total
	var acc  := 0
	for i in items.size():
		acc += weights[i]
		if roll < acc:
			return items[i]
	return items[0]
