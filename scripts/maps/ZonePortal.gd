class_name ZonePortal
extends Area2D

@export var destination: GameManager.ZoneType = GameManager.ZoneType.PLAINS
@export var required_level: int = 1
@export var portal_label: String = "→ Plains"

@onready var label: Label = $PortalLabel

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if label:
		label.text = portal_label

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	var player := body as PlayerController
	if player and player.stats.level < required_level:
		var hud := get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_popup"):
			hud.show_popup("Need level %d to enter!" % required_level, Color.ORANGE)
		return
	GameManager.travel_to_zone(destination)
