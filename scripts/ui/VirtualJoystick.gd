class_name VirtualJoystick
extends Control

signal direction_changed(dir: Vector2)

@export var joystick_radius: float  = 80.0
@export var knob_radius:     float  = 34.0
@export var dead_zone:       float  = 0.12

var direction: Vector2 = Vector2.ZERO
var is_pressed: bool   = false
var touch_index: int   = -1
var base_center: Vector2 = Vector2.ZERO

@onready var base_circle: Control = $Base
@onready var knob:        Control = $Knob

func _ready() -> void:
	base_center = size / 2.0

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if touch_index == -1 and _is_inside(event.position):
			touch_index = event.index
			is_pressed  = true
			_update_knob(event.position)
	else:
		if event.index == touch_index:
			touch_index = -1
			is_pressed  = false
			direction   = Vector2.ZERO
			_reset_knob()
			direction_changed.emit(direction)

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == touch_index:
		_update_knob(event.position)

func _update_knob(touch_pos: Vector2) -> void:
	var local_pos := touch_pos - global_position
	var offset    := local_pos - base_center
	var dist      := offset.length()
	var clamped   := offset.normalized() * min(dist, joystick_radius)
	knob.position = base_center + clamped - Vector2(knob_radius, knob_radius)
	direction      = clamped / joystick_radius
	if direction.length() < dead_zone:
		direction = Vector2.ZERO
	direction_changed.emit(direction)

func _reset_knob() -> void:
	knob.position = base_center - Vector2(knob_radius, knob_radius)

func _is_inside(pos: Vector2) -> bool:
	var local := pos - global_position
	return local.distance_to(base_center) <= joystick_radius + 20.0

func get_direction() -> Vector2:
	return direction

func _draw() -> void:
	# Outer ring
	draw_arc(base_center, joystick_radius, 0, TAU, 64, Color(1,1,1,0.15), 3.0)
	draw_circle(base_center, joystick_radius, Color(0,0,0,0.25))
	# Knob
	var knob_center := knob.position + Vector2(knob_radius, knob_radius)
	draw_circle(knob_center, knob_radius, Color(1,1,1,0.45))
	draw_arc(knob_center, knob_radius, 0, TAU, 48, Color(1,1,1,0.8), 2.0)
