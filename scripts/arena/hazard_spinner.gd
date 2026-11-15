extends Node3D

var _speed: float = 1.0

func _ready() -> void:
	_speed = float(get_meta("spin", 1.0))

func _process(delta: float) -> void:
	rotate_y(_speed * delta)
