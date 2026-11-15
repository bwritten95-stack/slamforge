extends Node3D

@onready var _magma: Node3D = $World/Magma
@onready var _beacon: Area3D = $World/Beacon
@onready var _player_spawn: Marker3D = $World/PlayerSpawn
@onready var _forges: Node3D = $World/Forges
@onready var _rings: Node3D = $World/Rings
@onready var _pause: CanvasLayer = $PauseOverlay
@onready var _hud: CanvasLayer = $HUD

var _player_scene: PackedScene = preload("res://scenes/player/player.tscn")
var _player: Node3D
var _ended: bool = false
var _hitstop: float = 0.0
var _magma_speed: float = 0.48
var _ledges: Array[StaticBody3D] = []

func _ready() -> void:
	RunState.reset()
	_pause.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	EventBus.player_died.connect(_on_dead)
	EventBus.hitstop.connect(func(d: float) -> void: _hitstop = maxf(_hitstop, d))
	EventBus.run_won.connect(_on_won)
	_style_start_platform()
	_build_tower_rings()
	_build_core_shaft()
	_style_beacon()
	_style_magma()
	_spawn_player()
	_beacon.body_entered.connect(_on_beacon)
	if "--autoplay" in OS.get_cmdline_user_args() or "--ship-test" in OS.get_cmdline_user_args():
		add_child(preload("res://scripts/systems/ship_test.gd").new())

func _spawn_player() -> void:
	_player = _player_scene.instantiate() as Node3D
	_player.global_position = _player_spawn.global_position
	$World.add_child(_player)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause") and RunState.run_active and not _ended:
		var paused := not get_tree().paused
		get_tree().paused = paused
		_pause.visible = paused
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED

	if _hitstop > 0.0:
		_hitstop -= delta
		Engine.time_scale = 0.12
	else:
		Engine.time_scale = 1.0

	if not RunState.run_active:
		return

	var accel := 1.0 + clampf(RunState.best_height / 40.0, 0.0, 1.6)
	var speed := _magma_speed
	if "--ship-test" in OS.get_cmdline_user_args():
		speed = 0.12
	RunState.magma_y += speed * accel * delta
	if _magma:
		_magma.global_position.y = RunState.magma_y
	EventBus.magma_level.emit(RunState.magma_y)
	_cull_melted_ledges()

func _style_start_platform() -> void:
	var start := $World/StartPlatform as StaticBody3D
	var mesh_i := start.get_node("Mesh") as MeshInstance3D
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.16, 0.2, 1)
	mat.metallic = 0.55
	mat.roughness = 0.35
	mesh_i.material_override = mat
	# rim glow ring under start pad
	var rim := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 4.6
	torus.outer_radius = 5.2
	rim.mesh = torus
	rim.position = Vector3(0.0, 0.55, 0.0)
	var rim_mat := StandardMaterial3D.new()
	rim_mat.albedo_color = Color(1.0, 0.45, 0.15, 1)
	rim_mat.emission_enabled = true
	rim_mat.emission = Color(1.0, 0.4, 0.1, 1)
	rim_mat.emission_energy_multiplier = 2.2
	rim.material_override = rim_mat
	start.add_child(rim)

func _build_core_shaft() -> void:
	var shaft := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.55
	cyl.bottom_radius = 0.9
	cyl.height = RunState.summit_y + 8.0
	shaft.mesh = cyl
	shaft.position = Vector3(0.0, cyl.height * 0.5 - 2.0, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.1, 0.14, 1)
	mat.metallic = 0.7
	mat.roughness = 0.28
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.35, 0.12, 1)
	mat.emission_energy_multiplier = 0.55
	shaft.material_override = mat
	_rings.add_child(shaft)

func _build_tower_rings() -> void:
	for child in _rings.get_children():
		child.queue_free()
	_ledges.clear()
	for i in 12:
		var y := 3.2 + float(i) * 3.35
		var count := 4 + (i % 4)
		var radius := 5.2 + float(i % 3) * 1.1
		var biome := _biome_color(i)
		for j in count:
			var ang := TAU * float(j) / float(count) + float(i) * 0.42
			var size := Vector3(2.1 + float(i % 2) * 0.4, 0.38, 1.7)
			var ledge := _make_box(size, biome)
			ledge.position = Vector3(cos(ang) * radius, y, sin(ang) * radius)
			ledge.rotation.y = -ang + PI * 0.5
			_rings.add_child(ledge)
			_ledges.append(ledge)
			if i % 2 == 0 and j % 2 == 0:
				var cable := MeshInstance3D.new()
				var cmesh := BoxMesh.new()
				cmesh.size = Vector3(0.06, 2.4, 0.06)
				cable.mesh = cmesh
				cable.position = ledge.position + Vector3(0.0, 1.2, 0.0)
				var cmat := StandardMaterial3D.new()
				cmat.albedo_color = biome.darkened(0.35)
				cable.material_override = cmat
				_rings.add_child(cable)
	_spawn_biome_bands()
	var summit := _make_box(Vector3(9.0, 0.55, 9.0), Color(0.95, 0.72, 0.28, 1), true)
	summit.position = Vector3(0.0, RunState.summit_y, 0.0)
	_rings.add_child(summit)
	_beacon.global_position = Vector3(0.0, RunState.summit_y + 1.4, 0.0)
	_spawn_hazard_rings()

func _biome_color(ring: int) -> Color:
	# Lower forge iron → mid ash → upper brass
	if ring < 4:
		return Color(0.22, 0.16, 0.14, 1)
	if ring < 8:
		return Color(0.16, 0.18, 0.22, 1)
	return Color(0.28, 0.22, 0.14, 1)

func _spawn_biome_bands() -> void:
	var bands := [
		{"y": 8.0, "c": Color(0.7, 0.25, 0.08, 1)},
		{"y": 22.0, "c": Color(0.25, 0.35, 0.55, 1)},
		{"y": 34.0, "c": Color(0.75, 0.55, 0.2, 1)},
	]
	for b in bands:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 9.5
		torus.outer_radius = 10.2
		ring.mesh = torus
		ring.position = Vector3(0.0, float(b["y"]), 0.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = b["c"] as Color
		mat.emission_enabled = true
		mat.emission = b["c"] as Color
		mat.emission_energy_multiplier = 1.4
		ring.material_override = mat
		_rings.add_child(ring)

func _spawn_hazard_rings() -> void:
	if "--ship-test" in OS.get_cmdline_user_args():
		return
	var spinner_script: Script = load("res://scripts/arena/hazard_spinner.gd") as Script
	for i in 3:
		var y := 10.0 + float(i) * 10.0
		var spinner := Node3D.new()
		spinner.set_script(spinner_script)
		spinner.name = "Hazard_%d" % i
		spinner.position = Vector3(0.0, y, 0.0)
		spinner.set_meta("spin", 0.7 + float(i) * 0.25)
		# telegraph disc so blades read before they hit
		var warn := MeshInstance3D.new()
		var disc := TorusMesh.new()
		disc.inner_radius = 2.6
		disc.outer_radius = 3.0
		warn.mesh = disc
		var wmat := StandardMaterial3D.new()
		wmat.albedo_color = Color(1.0, 0.2, 0.1, 0.55)
		wmat.emission_enabled = true
		wmat.emission = Color(1.0, 0.15, 0.05, 1)
		wmat.emission_energy_multiplier = 2.0
		wmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		warn.material_override = wmat
		spinner.add_child(warn)
		for j in 2:
			var blade := _make_box(Vector3(5.5, 0.25, 0.7), Color(0.85, 0.2, 0.15, 1), true)
			blade.position = Vector3(cos(float(j) * PI) * 3.2, 0.0, sin(float(j) * PI) * 3.2)
			blade.rotation.y = float(j) * PI
			var area := Area3D.new()
			area.collision_layer = 0
			area.collision_mask = 2
			area.monitoring = true
			var col := CollisionShape3D.new()
			var shape := BoxShape3D.new()
			shape.size = Vector3(5.5, 0.6, 0.9)
			col.shape = shape
			area.add_child(col)
			blade.add_child(area)
			area.body_entered.connect(_on_hazard)
			spinner.add_child(blade)
		_rings.add_child(spinner)

func _style_beacon() -> void:
	var mesh_i := _beacon.get_node_or_null("Mesh") as MeshInstance3D
	if mesh_i == null:
		return
	var sphere := SphereMesh.new()
	sphere.radius = 1.15
	sphere.height = 2.3
	mesh_i.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.9, 0.45, 1)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.75, 0.25, 1)
	mat.emission_energy_multiplier = 5.5
	mesh_i.material_override = mat
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.8, 0.35, 1)
	light.light_energy = 4.0
	light.omni_range = 18.0
	_beacon.add_child(light)

func _style_magma() -> void:
	var mesh_i := _magma.get_node("Mesh") as MeshInstance3D
	var plane := CylinderMesh.new()
	plane.top_radius = 48.0
	plane.bottom_radius = 48.0
	plane.height = 1.2
	mesh_i.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.22, 0.05, 1)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.35, 0.05, 1)
	mat.emission_energy_multiplier = 4.5
	mat.roughness = 0.85
	mesh_i.material_override = mat
	var glow := OmniLight3D.new()
	glow.light_color = Color(1.0, 0.4, 0.1, 1)
	glow.light_energy = 2.5
	glow.omni_range = 30.0
	glow.position = Vector3(0.0, 2.0, 0.0)
	_magma.add_child(glow)
	_magma.global_position.y = RunState.magma_y

func _make_box(size: Vector3, color: Color, emissive: bool = false) -> StaticBody3D:
	var body := StaticBody3D.new()
	var mesh_i := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_i.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.45
	mat.roughness = 0.4
	if emissive:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 1.8
	mesh_i.material_override = mat
	body.add_child(mesh_i)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	return body

func _cull_melted_ledges() -> void:
	var keep: Array[StaticBody3D] = []
	for ledge in _ledges:
		if not is_instance_valid(ledge):
			continue
		if ledge.global_position.y < RunState.magma_y + 1.0:
			var tw := create_tween()
			tw.tween_property(ledge, "scale", Vector3(0.05, 0.05, 0.05), 0.25)
			tw.tween_callback(ledge.queue_free)
		else:
			keep.append(ledge)
	_ledges = keep

func _on_hazard(body: Node3D) -> void:
	if _ended:
		return
	if body is SlamPlayer:
		(body as SlamPlayer).kill("hazard")

func _on_beacon(body: Node3D) -> void:
	if _ended or not (body is SlamPlayer):
		return
	_ended = true
	RunState.mark("won")
	RunState.add_score(500)
	EventBus.run_won.emit()
	AudioService.play_win()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await get_tree().create_timer(0.9).timeout
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://scenes/ui/result_screen.tscn")

func _on_dead(_reason: String) -> void:
	if _ended:
		return
	_ended = true
	EventBus.run_lost.emit()
	await get_tree().create_timer(0.8).timeout
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://scenes/ui/result_screen.tscn")

func _on_won() -> void:
	pass
