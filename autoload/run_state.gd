extends Node

var run_active: bool = false
var outcome: String = "" # won | lost | ""
var score: int = 0
var combo: int = 0
var best_combo: int = 0
var mult: float = 1.0
var height: float = 0.0
var best_height: float = 0.0
var slams: int = 0
var magma_y: float = -14.0
var summit_y: float = 42.0

func reset() -> void:
	run_active = true
	outcome = ""
	score = 0
	combo = 0
	best_combo = 0
	mult = 1.0
	height = 0.0
	best_height = 0.0
	slams = 0
	magma_y = -14.0

func add_score(base: int) -> void:
	score += int(round(float(base) * mult))
	EventBus.score_changed.emit(score)

func bump_combo() -> void:
	combo += 1
	best_combo = max(best_combo, combo)
	mult = 1.0 + float(mini(combo, 15)) * 0.2
	EventBus.combo_changed.emit(combo, mult)
	AudioService.play_combo(combo)

func break_combo() -> void:
	combo = 0
	mult = 1.0
	EventBus.combo_changed.emit(combo, mult)

func mark(end: String) -> void:
	run_active = false
	outcome = end
