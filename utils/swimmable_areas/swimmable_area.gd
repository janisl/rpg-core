@tool
extends CSGBox3D

@export var water_texture_move_speed := Vector3(0.0025, 0.0025, 0.0025)
@export var water_texture_uv_scale := 0.04
@export var water_color := Color(0.3098039329052, 0.54117649793625, 0.86666667461395, 0.38823530077934)
@export var fog_color := Color(0, 0.04313725605607, 0.15686275064945)
@export_range(0.0, 250.0) var fog_fade_dist := 5.0

@onready var fog_volume: FogVolume = %FogVolume
@onready var detection_shape: CollisionShape3D = %DetectionShape


func _ready():
	if not Engine.is_editor_hint():
		GlobalManager.camera_underwater_effect_changed.connect(_on_camera_underwater_effect_changed)


func _process(delta):
	if not detection_shape or not fog_volume:
		return

	detection_shape.shape.size = self.size

	if material is StandardMaterial3D:
		if not Engine.is_editor_hint():
			material.uv1_offset += water_texture_move_speed * delta
		material.uv1_scale = Vector3(water_texture_uv_scale,water_texture_uv_scale,water_texture_uv_scale)
		material.albedo_color = water_color

	fog_volume.material.set_shader_parameter("albedo", fog_color)
	fog_volume.material.set_shader_parameter("emission", fog_color)
	fog_volume.size = size
	fog_volume.fade_distance = fog_fade_dist


func _on_camera_underwater_effect_changed() -> void:
	if GlobalManager.camera_underwater_effect:
		fog_volume.material.set_shader_parameter("edge_fade", 0.1)
	else:
		fog_volume.material.set_shader_parameter("edge_fade", 1.1)
