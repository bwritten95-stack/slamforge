extends Node

signal slammed(world_pos: Vector3, combo: int)
signal forged(world_pos: Vector3, size: float)
signal combo_changed(combo: int, mult: float)
signal score_changed(score: int)
signal height_changed(height: float, best: float)
signal player_died(reason: String)
signal run_won
signal run_lost
signal magma_level(y: float)
signal camera_punch(amount: float)
signal hitstop(duration: float)
