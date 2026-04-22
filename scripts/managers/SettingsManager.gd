extends Node

const SETTINGS_PATH := "user://settings.json"

var master_volume: float = 1.0
var fullscreen:    bool  = false
var resolution:    Vector2i = Vector2i(1920, 1080)

func _ready() -> void:
	load_settings()
	_apply_settings()

func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(master_volume))
	save_settings()

func set_fullscreen(value: bool) -> void:
	fullscreen = value
	if value:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	save_settings()

func save_settings() -> void:
	var data := {
		"master_volume": master_volume,
		"fullscreen":    fullscreen,
	}
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if not file:
		return
	var result := JSON.parse_string(file.get_as_text())
	file.close()
	if result is Dictionary:
		master_volume = result.get("master_volume", 1.0)
		fullscreen    = result.get("fullscreen",    false)

func _apply_settings() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(master_volume))
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
