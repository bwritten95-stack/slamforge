extends Control

@onready var _play: Button = $Center/VBox/Play
@onready var _quit: Button = $Center/VBox/Quit
@onready var _settings: Button = $Center/VBox/Settings
@onready var _panel: Control = $SettingsPanel
@onready var _master: HSlider = $SettingsPanel/Panel/VBox/MasterRow/Slider
@onready var _sfx: HSlider = $SettingsPanel/Panel/VBox/SfxRow/Slider
@onready var _fs: CheckButton = $SettingsPanel/Panel/VBox/Fullscreen
@onready var _close: Button = $SettingsPanel/Panel/VBox/Close
@onready var _title: Label = $Center/VBox/Title
@onready var _bg: ColorRect = $BG

func _ready() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_dress_menu()
	_play.pressed.connect(func() -> void:
		AudioService.play_ui()
		get_tree().change_scene_to_file("res://scenes/arena/arena.tscn")
	)
	_quit.pressed.connect(func() -> void: get_tree().quit())
	_settings.pressed.connect(func() -> void:
		AudioService.play_ui()
		_panel.visible = true
	)
	_close.pressed.connect(func() -> void: _panel.visible = false)
	_panel.visible = false
	_master.value = SettingsStore.master_volume
	_sfx.value = SettingsStore.sfx_volume
	_fs.button_pressed = SettingsStore.fullscreen
	_master.value_changed.connect(func(v: float) -> void: SettingsStore.set_master_volume(v))
	_sfx.value_changed.connect(func(v: float) -> void: SettingsStore.set_sfx_volume(v))
	_fs.toggled.connect(func(on: bool) -> void: SettingsStore.set_fullscreen(on))
	var tw := create_tween().set_loops()
	tw.tween_property(_title, "modulate", Color(1.0, 0.7, 0.35, 1), 1.4)
	tw.tween_property(_title, "modulate", Color(1.0, 0.45, 0.2, 1), 1.4)
	var args := OS.get_cmdline_user_args()
	if "--autoplay" in args or "--ship-test" in args:
		await get_tree().create_timer(0.6).timeout
		await _cap("sf-menu")
		get_tree().change_scene_to_file("res://scenes/arena/arena.tscn")

func _dress_menu() -> void:
	_bg.color = Color(0.04, 0.03, 0.05, 1)
	var glow := ColorRect.new()
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.color = Color(0.55, 0.12, 0.04, 0.22)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)
	move_child(glow, 1)
	var band := ColorRect.new()
	band.anchor_left = 0.0
	band.anchor_right = 1.0
	band.anchor_top = 0.62
	band.anchor_bottom = 1.0
	band.offset_left = 0.0
	band.offset_right = 0.0
	band.offset_top = 0.0
	band.offset_bottom = 0.0
	band.color = Color(0.9, 0.25, 0.05, 0.18)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(band)
	move_child(band, 2)

func _cap(label: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var tex := get_viewport().get_texture()
	if tex == null:
		return
	var img := tex.get_image()
	if img:
		img.save_png("user://%s.png" % label)
		print("MENU_CAPTURE: ", label)
