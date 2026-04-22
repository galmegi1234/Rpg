class_name WorldMap
extends Control

# Full-screen world map overlay showing all zones with travel buttons.

@onready var close_btn: Button = $CloseButton

const ZONE_DATA: Array[Dictionary] = [
	{
		"zone": GameManager.ZoneType.TOWN,
		"label": "🏘️ Aetheria Town",
		"desc": "Safe haven. Shop, rest, NPC quests.",
		"color": Color(0.3, 0.6, 0.3),
		"pos": Vector2(200, 300),
		"min_level": 1
	},
	{
		"zone": GameManager.ZoneType.PLAINS,
		"label": "🌿 Greenwood Plains",
		"desc": "Beginner hunting ground. Slimes & Goblins.",
		"color": Color(0.4, 0.7, 0.2),
		"pos": Vector2(500, 280),
		"min_level": 1
	},
	{
		"zone": GameManager.ZoneType.FOREST,
		"label": "🌲 Dark Forest",
		"desc": "Intermediate zone. Wolves & Dark Elves.",
		"color": Color(0.1, 0.4, 0.1),
		"pos": Vector2(820, 260),
		"min_level": 5
	},
	{
		"zone": GameManager.ZoneType.DUNGEON,
		"label": "🔥 Infernal Dungeon",
		"desc": "High danger. Skeleton Knights & Boss.",
		"color": Color(0.6, 0.1, 0.05),
		"pos": Vector2(1100, 300),
		"min_level": 10
	},
]

func _ready() -> void:
	close_btn.pressed.connect(queue_free)
	_build_zone_buttons()

func _build_zone_buttons() -> void:
	var player_level := 1
	var player       := GameManager.player_ref
	if player and player.has_node("PlayerStats"):
		player_level = player.get_node("PlayerStats").level

	for zd in ZONE_DATA:
		var btn := Button.new()
		btn.text                = "%s\n%s" % [zd["label"], zd["desc"]]
		btn.custom_minimum_size = Vector2(200, 70)
		btn.position            = zd["pos"]
		btn.disabled            = player_level < zd["min_level"]
		var zone_capture        := zd["zone"] as GameManager.ZoneType
		btn.pressed.connect(func():
			queue_free()
			GameManager.travel_to_zone(zone_capture)
		)
		# Highlight current zone
		if zd["zone"] == GameManager.current_zone:
			btn.modulate = Color(1.3, 1.3, 0.3)
		add_child(btn)
