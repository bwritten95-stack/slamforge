extends Control

@onready var _title: Label = $Center/VBox/Title
@onready var _stats: Label = $Center/VBox/Stats
@onready var _again: Button = $Center/VBox/Again
@onready var _menu: Button = $Center/VBox/Menu

func _ready() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var won := RunState.outcome == "won"
	_title.text = "SUMMIT FORGED" if won else "FORGE MELTED"
	_title.modulate = Color(1.0, 0.7, 0.35) if won else Color(1.0, 0.35, 0.3)
	_stats.text = "Score %d\nBest height %.0fm  ·  Best combo x%d  ·  Slams %d" % [
		RunState.score, RunState.best_height, RunState.best_combo, RunState.slams
	]
	_again.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/arena/arena.tscn")
	)
	_menu.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	)
	var args := OS.get_cmdline_user_args()
	if "--autoplay" in args or "--ship-test" in args or "--lose-cap" in args:
		await get_tree().create_timer(0.5).timeout
		var tex := get_viewport().get_texture()
		if tex:
			var img := tex.get_image()
			if img:
				img.save_png("user://sf-result-%s.png" % RunState.outcome)
				print("RESULT_CAPTURE: ", RunState.outcome)
		get_tree().quit(0)
