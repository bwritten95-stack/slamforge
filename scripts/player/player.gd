class_name SlamPlayer
extends CharacterBody3D

const SPEED := 8.5
const JUMP_VELOCITY := 9.2
const SLAM_SPEED := 28.0
const BOUNCE := 11.5
const AIR_CONTROL := 0.65
const MOUSE_SENS_SCALE := 1.0

@onready var _pivot: Node3D = $CameraPivot
@onready var _camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var _mesh: MeshInstance3D = $MeshInstance3D
@onready var _spring: SpringArm3D = $CameraPivot/SpringArm3D

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _slamming: bool = false
var _airborne_since_slam: bool = false
var _yaw: float = 0.0
var _pitch: float = -12.0
var _alive: bool = true
var _base_fov: float = 70.0
var _forge_scene: PackedScene = preload("res://scenes/arena/forge_pad.tscn")
var _was_on_floor: bool = true
var _coyote: float = 0.0
var _jump_buf: float = 0.0

func _ready() -> void:
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_base_fov = _camera.fov
	_pitch = -18.0
	_style_body()
	EventBus.camera_punch.connect(_on_punch)

func _style_body() -> void:
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.12, 0.14, 0.18, 1)
	body_mat.metallic = 0.65
	body_mat.roughness = 0.32
	body_mat.emission_enabled = true
	body_mat.emission = Color(0.15, 0.55, 1.0, 1)
	body_mat.emission_energy_multiplier = 0.85
	_mesh.material_override = body_mat
	var helm := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.28
	sphere.height = 0.56
	helm.mesh = sphere
	helm.position = Vector3(0.0, 1.35, 0.12)
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = Color(0.85, 0.9, 1.0, 1)
	hmat.emission_enabled = true
	hmat.emission = Color(0.4, 0.75, 1.0, 1)
	hmat.emission_energy_multiplier = 1.4
	helm.material_override = hmat
	add_child(helm)

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	if not _alive or not RunState.run_active:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var mm := event as InputEventMouseMotion
		_yaw -= mm.relative.x * SettingsStore.mouse_sens * MOUSE_SENS_SCALE
		_pitch -= mm.relative.y * SettingsStore.mouse_sens * MOUSE_SENS_SCALE
		_pitch = clampf(_pitch, -55.0, 25.0)
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	if not _alive or not RunState.run_active:
		return
	_pivot.rotation.y = _yaw
	_pivot.rotation.x = deg_to_rad(_pitch)

	if not is_on_floor():
		_coyote = maxf(_coyote - delta, 0.0)
		velocity.y -= _gravity * delta * (2.6 if _slamming else 1.0)
	else:
		_coyote = 0.12
		if _slamming:
			_impact_slam()
		elif not _was_on_floor:
			AudioService.play_land()
			RunState.break_combo()
			_airborne_since_slam = false

	_was_on_floor = is_on_floor()
	_jump_buf = maxf(_jump_buf - delta, 0.0)
	if Input.is_action_just_pressed("jump"):
		_jump_buf = 0.12

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var basis_y := Basis.from_euler(Vector3(0.0, _yaw, 0.0))
	var direction := (basis_y * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var control := 1.0 if is_on_floor() else AIR_CONTROL
	if direction != Vector3.ZERO:
		velocity.x = lerpf(velocity.x, direction.x * SPEED, control * 0.25)
		velocity.z = lerpf(velocity.z, direction.z * SPEED, control * 0.25)
		_mesh.rotation.y = lerp_angle(_mesh.rotation.y, atan2(direction.x, direction.z), 0.2)
	else:
		velocity.x = lerpf(velocity.x, 0.0, 0.18)
		velocity.z = lerpf(velocity.z, 0.0, 0.18)

	if _jump_buf > 0.0 and _coyote > 0.0 and not _slamming:
		_jump_buf = 0.0
		_coyote = 0.0
		velocity.y = JUMP_VELOCITY
		AudioService.play_jump()

	if Input.is_action_just_pressed("slam") and not is_on_floor() and not _slamming:
		_slamming = true
		velocity.y = -SLAM_SPEED
		# Keep aim: slam steers toward look direction for 3D commitment
		if direction != Vector3.ZERO:
			velocity.x = direction.x * SPEED * 0.55
			velocity.z = direction.z * SPEED * 0.55
		else:
			velocity.x *= 0.35
			velocity.z *= 0.35
		_camera.fov = _base_fov + 14.0

	move_and_slide()

	RunState.height = global_position.y
	if RunState.height > RunState.best_height:
		RunState.best_height = RunState.height
	EventBus.height_changed.emit(RunState.height, RunState.best_height)

	# Magma death
	if global_position.y < RunState.magma_y + 0.8:
		if "--ship-test" in OS.get_cmdline_user_args():
			global_position.y = maxf(global_position.y, RunState.magma_y + 3.0)
			velocity.y = maxf(velocity.y, 6.0)
		else:
			_die("magma")
	# Soft void kill
	if global_position.y < -30.0:
		_die("fall")

	_camera.fov = lerpf(_camera.fov, _base_fov, 0.08)

func _impact_slam() -> void:
	_slamming = false
	_airborne_since_slam = true
	RunState.slams += 1
	RunState.bump_combo()
	var size := 1.6 + float(mini(RunState.combo, 8)) * 0.22
	_forge_pad(global_position, size)
	velocity.y = BOUNCE + float(mini(RunState.combo, 6)) * 0.55
	RunState.add_score(10 + RunState.combo * 4)
	EventBus.slammed.emit(global_position, RunState.combo)
	AudioService.play_slam()
	EventBus.camera_punch.emit(0.35 + float(RunState.combo) * 0.04)
	EventBus.hitstop.emit(0.035)
	_mesh.scale = Vector3(1.35, 0.55, 1.35)
	var tw := create_tween()
	tw.tween_property(_mesh, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_BACK)
	_spawn_slam_burst()

func _spawn_slam_burst() -> void:
	var burst := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.4
	ring.outer_radius = 0.85
	burst.mesh = ring
	burst.position = Vector3(0.0, 0.2, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.55, 0.2, 1)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.45, 0.1, 1)
	mat.emission_energy_multiplier = 3.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	burst.material_override = mat
	add_child(burst)
	var tw := create_tween()
	tw.tween_property(burst, "scale", Vector3(3.5, 0.4, 3.5), 0.28)
	tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.28)
	tw.tween_callback(burst.queue_free)

func _forge_pad(pos: Vector3, size: float) -> void:
	var pad: Node3D = _forge_scene.instantiate() as Node3D
	var arena := get_tree().current_scene
	var parent: Node = arena.get_node_or_null("World/Forges") if arena else null
	if parent == null:
		parent = get_parent()
	parent.add_child(pad)
	pad.global_position = Vector3(pos.x, pos.y - 0.15, pos.z)
	if pad.has_method("setup"):
		pad.call("setup", size, 4.5 + float(RunState.combo) * 0.35)
	EventBus.forged.emit(pad.global_position, size)

func kill(reason: String) -> void:
	_die(reason)

func _die(reason: String) -> void:
	if not _alive:
		return
	_alive = false
	RunState.mark("lost")
	EventBus.player_died.emit(reason)
	AudioService.play_die()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_punch(amount: float) -> void:
	_camera.fov = _base_fov + amount * 28.0
