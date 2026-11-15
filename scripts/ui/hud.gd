extends CanvasLayer

@onready var _score: Label = $Root/Top/Score
@onready var _combo: Label = $Root/Top/Combo
@onready var _height: Label = $Root/Top/Height
@onready var _magma: Label = $Root/Top/Magma
@onready var _hint: Label = $Root/Hint
@onready var _banner: Label = $Root/Banner

func _ready() -> void:
	EventBus.score_changed.connect(func(s: int) -> void: _score.text = "Score %d" % s)
	EventBus.combo_changed.connect(func(c: int, m: float) -> void:
		_combo.text = ("COMBO x%d  ×%.1f" % [c, m]) if c > 0 else "Combo —"
	)
	EventBus.height_changed.connect(func(h: float, b: float) -> void:
		_height.text = "Height %.0fm  (best %.0f)" % [h, b]
	)
	EventBus.magma_level.connect(func(y: float) -> void:
		_magma.text = "Magma %.0fm" % y
	)
	EventBus.slammed.connect(func(_p: Vector3, c: int) -> void:
		if c >= 3:
			_flash("SLAM x%d" % c)
	)
	_hint.text = "WASD move · Mouse look · Space jump · LMB/F/Ctrl slam · Esc pause"
	_banner.modulate.a = 0.0
	await get_tree().create_timer(0.4).timeout
	_flash("SLAM TO FORGE — CLIMB OR MELT")

func _flash(t: String) -> void:
	_banner.text = t
	_banner.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.tween_property(_banner, "modulate:a", 0.0, 0.4)
