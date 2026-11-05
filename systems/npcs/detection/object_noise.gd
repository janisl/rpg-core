class_name ObjectNoise
extends Area3D

enum NoiseType {
	Impact,
	Footstep,
}

var spawn_debug_shape: bool
var magnitude: float
var noise_duration: float
var noise_type: NoiseType

var collider: CollisionShape3D
var debug_mesh: MeshInstance3D

func _init(_spawn_debug_shape: bool) -> void:
	spawn_debug_shape = _spawn_debug_shape


func _ready() -> void:
	collider = CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = magnitude
	collider.shape = sphere
	set_collision_layer_value(1, false)
	set_collision_layer_value(10, true)
	add_child(collider)

	if spawn_debug_shape:
		debug_mesh = MeshInstance3D.new()
		debug_mesh.mesh = SphereMesh.new()
		debug_mesh.mesh.radius = magnitude
		debug_mesh.mesh.height = magnitude*2
		var mat := StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(1, 0, 0, 0.5)
		debug_mesh.material_override = mat
		add_child(debug_mesh)

	fire_off_noise()


func set_parameters(_noise_type: NoiseType, _noise_size: float, _noise_duration: float, _noise_layer: int) -> void:
	noise_type = _noise_type
	magnitude = _noise_size
	noise_duration = _noise_duration
	set_collision_layer(_noise_layer)


func fire_off_noise() -> void:
	var tween := create_tween()
	if debug_mesh:
		tween.tween_property(debug_mesh, "material_override:albedo_color", Color(1, 0, 0, 0), noise_duration)

	tween.tween_callback(queue_free)
