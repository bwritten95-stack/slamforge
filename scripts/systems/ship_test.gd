extends Node
## --ship-test / --autoplay: climb by auto-jumping and slamming.

var _t: float = 0.0
var _shot: Dictionary = {}

func _ready() -> void:
	print("SHIP_TEST: slamforge")
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	_t += delta
	var p := get_tree().get_first_node_in_group("player")
	if p == null:
		return
	var body := p as CharacterBody3D
	var node := p as Node3D

	# Hold on start pad for first beauty shot
	if _t < 2.2:
		node.global_position = Vector3(0.0, 2.0, 0.0)
		body.velocity = Vector3.ZERO
		p.set("_pitch", -28.0)
		p.set("_yaw", 0.55)
		if _t > 1.4 and not _shot.get("play", false):
			_shot["play"] = true
			await _cap("sf-arena")
		return

	p.set("_pitch", -22.0)
	p.set("_yaw", 0.8 + _t * 0.15)
	Input.action_press("move_forward")
	if fmod(_t, 0.85) < delta:
		Input.action_press("jump")
		await get_tree().process_frame
		Input.action_release("jump")
	if fmod(_t, 0.7) < delta and not body.is_on_floor():
		Input.action_press("slam")
		await get_tree().process_frame
		Input.action_release("slam")

	if _t > 4.0 and not _shot.get("mid", false):
		_shot["mid"] = true
		node.global_position = Vector3(4.0, 18.0, 2.5)
		body.velocity = Vector3(0.0, 4.0, 0.0)
		p.set("_pitch", -20.0)
		p.set("_yaw", 1.1)
		await _cap("sf-climb")

	if _t > 7.5 and RunState.run_active and not _shot.get("summit", false):
		_shot["summit"] = true
		node.global_position = Vector3(0.0, RunState.summit_y + 1.2, 0.0)
		body.velocity = Vector3.ZERO
		await _cap("sf-summit")

	if not RunState.run_active and RunState.outcome != "" and not _shot.get("done", false):
		_shot["done"] = true
		print("SHIP_TEST: outcome=", RunState.outcome, " score=", RunState.score, " height=", RunState.best_height)
		await get_tree().create_timer(1.2).timeout
		get_tree().quit(0)

	if _t > 24.0:
		print("SHIP_TEST: timeout height=", RunState.best_height, " score=", RunState.score, " outcome=", RunState.outcome)
		get_tree().quit(1)

func _cap(label: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var tex := get_viewport().get_texture()
	if tex == null:
		return
	var img := tex.get_image()
	if img:
		img.save_png("user://%s.png" % label)
		print("SHIP_TEST: shot ", label)
