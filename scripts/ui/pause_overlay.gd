extends CanvasLayer

@onready var _resume: Button = $Root/Panel/VBox/Resume
@onready var _menu: Button = $Root/Panel/VBox/Menu
@onready var _vbox: VBoxContainer = $Root/Panel/VBox

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_resume.pressed.connect(func() -> void:
		get_tree().paused = false
		visible = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		AudioService.play_ui()
	)
	_menu.pressed.connect(func() -> void:
		get_tree().paused = false
		Engine.time_scale = 1.0
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	)
	_add_slider("Master", SettingsStore.master_volume, func(v: float) -> void: SettingsStore.set_master_volume(v))
	_add_slider("SFX", SettingsStore.sfx_volume, func(v: float) -> void: SettingsStore.set_sfx_volume(v))
	var fs := CheckButton.new()
	fs.text = "Fullscreen"
	fs.button_pressed = SettingsStore.fullscreen
	fs.toggled.connect(func(on: bool) -> void: SettingsStore.set_fullscreen(on))
	_vbox.add_child(fs)
	_vbox.move_child(fs, _resume.get_index())

func _add_slider(title: String, value: float, cb: Callable) -> void:
	var row := HBoxContainer.new()
	var lab := Label.new()
	lab.text = title
	lab.custom_minimum_size = Vector2(70, 0)
	var s := HSlider.new()
	s.min_value = 0
	s.max_value = 1
	s.step = 0.01
	s.value = value
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.value_changed.connect(cb)
	row.add_child(lab)
	row.add_child(s)
	_vbox.add_child(row)
	_vbox.move_child(row, _resume.get_index())
