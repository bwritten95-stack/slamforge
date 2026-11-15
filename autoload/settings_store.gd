extends Node

const PATH := "user://slamforge_settings.cfg"
var master_volume: float = 0.85
var sfx_volume: float = 1.0
var fullscreen: bool = false
var mouse_sens: float = 0.003

func _ready() -> void:
	load_settings()
	apply()

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	master_volume = float(cfg.get_value("audio", "master", master_volume))
	sfx_volume = float(cfg.get_value("audio", "sfx", sfx_volume))
	fullscreen = bool(cfg.get_value("display", "fullscreen", fullscreen))
	mouse_sens = float(cfg.get_value("input", "mouse_sens", mouse_sens))

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.set_value("input", "mouse_sens", mouse_sens)
	cfg.save(PATH)

func apply() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(clampf(master_volume, 0.0001, 1.0)))
	var sfx_idx := AudioServer.get_bus_index("SFX")
	if sfx_idx >= 0:
		AudioServer.set_bus_volume_db(sfx_idx, linear_to_db(clampf(sfx_volume, 0.0001, 1.0)))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)

func set_master_volume(v: float) -> void:
	master_volume = clampf(v, 0.0, 1.0)
	apply()
	save_settings()

func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
	apply()
	save_settings()

func set_fullscreen(on: bool) -> void:
	fullscreen = on
	apply()
	save_settings()
