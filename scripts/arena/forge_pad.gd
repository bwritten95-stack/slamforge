extends StaticBody3D

@onready var _mesh: MeshInstance3D = $MeshInstance3D
@onready var _col: CollisionShape3D = $CollisionShape3D

var _life: float = 5.0
var _max_life: float = 5.0

func setup(size: float, life: float) -> void:
	_life = life
	_max_life = life
	var box := BoxMesh.new()
	box.size = Vector3(size, 0.35, size)
	_mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.55, 0.25, 1)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.35, 0.1, 1)
	mat.emission_energy_multiplier = 2.4
	_mesh.material_override = mat
	var shape := BoxShape3D.new()
	shape.size = Vector3(size, 0.35, size)
	_col.shape = shape
	scale = Vector3(0.2, 0.2, 0.2)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	_life -= delta
	var u := clampf(_life / _max_life, 0.0, 1.0)
	if _mesh.material_override is StandardMaterial3D:
		var m := _mesh.material_override as StandardMaterial3D
		m.albedo_color = Color(1.0, 0.55, 0.25, 1).lerp(Color(0.3, 0.08, 0.05, 1), 1.0 - u)
		m.emission_energy_multiplier = lerpf(0.2, 2.0, u)
	if _life <= 0.0:
		var tw := create_tween()
		tw.tween_property(self, "scale", Vector3(0.05, 0.05, 0.05), 0.15)
		tw.tween_callback(queue_free)
		set_process(false)
