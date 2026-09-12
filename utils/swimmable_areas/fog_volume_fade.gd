extends FogVolume

@export var fade_distance := 5


func _ready():
	GlobalManager.camera_underwater_effect_changed.connect(_on_camera_underwater_effect_changed)


func _process(_delta):
	if not get_viewport():
		return

	var cam = get_viewport().get_camera_3d()
	if not cam:
		return

	var fade_plane_normal = cam.global_transform.basis.z * -1
	var fade_plane_pos = cam.global_transform.origin + cam.global_transform.basis.z * -fade_distance
	var fade_plane_distance = fade_plane_pos.dot(fade_plane_normal)
	var fade_plane = Vector4(fade_plane_normal.x, fade_plane_normal.y, fade_plane_normal.z, fade_plane_distance)
	material.set_shader_parameter("fade_plane", fade_plane)


func _on_camera_underwater_effect_changed() -> void:
	if GlobalManager.camera_underwater_effect:
		material.set_shader_parameter("edge_fade", 0.1)
	else:
		material.set_shader_parameter("edge_fade", 1.1)
