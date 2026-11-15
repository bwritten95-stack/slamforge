extends Node
## --lose-cap: force a magma death for result screenshot.

func _ready() -> void:
	print("LOSE_CAP: start")
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().create_timer(1.0).timeout
	var p := get_tree().get_first_node_in_group("player")
	if p and p.has_method("kill"):
		(p as SlamPlayer).kill("magma")
	await get_tree().create_timer(2.0).timeout
	print("LOSE_CAP: timeout")
	get_tree().quit(0)
