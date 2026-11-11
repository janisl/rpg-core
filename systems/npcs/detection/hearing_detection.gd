@tool
extends Node3D
class_name HearingDetection

const HEARING_POINT = preload("uid://b4r73momnv102")

@export_group("Nodepaths")
@export var collision_shape: CollisionShape3D
@export var npc: Npc

@export var hearing_radius := 10.0:
	set(new_radius):
		hearing_radius = new_radius
		_update_debug_state()

@export var show_hearing_radius := false:
	set(new_value):
		show_hearing_radius = new_value
		_update_debug_state()

@export var ignore_sounds_under_x_magnitude := 3.0

@export_group("Suspicion Build-Up")
@export var noise_suspicion_indicator: DetectionIndicator
@export var suspicion_threshold_before_investigating := 10.0
@export var delay_before_suspicion_decays := 3.0
@export var suspicion_decay_rate := 0.5
@export var noise_suspicion_curve := _linear_curve()

var current_suspicion := 0.0

var _decay_timer: Timer
var _is_decaying := false


func _ready() -> void:
	_decay_timer = Timer.new()
	_decay_timer.wait_time = delay_before_suspicion_decays
	_decay_timer.timeout.connect(func() -> void: _is_decaying = true)
	_decay_timer.one_shot = true
	add_child(_decay_timer)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if noise_suspicion_indicator and current_suspicion > 0:
		noise_suspicion_indicator.update(current_suspicion, suspicion_threshold_before_investigating)

	if _decay_timer.is_stopped() and not _is_decaying:
		_decay_timer.start()
	elif _is_decaying and current_suspicion > 0:
		current_suspicion -= delta


## True when heard noises are suspicious enough to investigate.
func is_suspicious_of_noise() -> bool:
	return current_suspicion > suspicion_threshold_before_investigating


func reset() -> void:
	current_suspicion = 0
	noise_suspicion_indicator.update(current_suspicion, suspicion_threshold_before_investigating)


func generate_attention_target(pos: Vector3) -> void:
	var attention_point := HEARING_POINT.instantiate()
	get_tree().current_scene.add_child(attention_point)
	attention_point.global_position = pos
	npc.attention_target = attention_point


func _on_hearing_radius_area_entered(area: Area3D) -> void:
	if area is not ObjectNoise:
		return
	var noise := area as ObjectNoise
	if noise.noise_type == ObjectNoise.NoiseType.Impact:
		npc.notify_alerted(generate_attention_target.bind(noise.global_position))
	elif noise.magnitude > ignore_sounds_under_x_magnitude and current_suspicion < suspicion_threshold_before_investigating + 0.5:
		_decay_timer.stop()
		current_suspicion += noise_suspicion_curve.sample(noise.magnitude)
	if is_suspicious_of_noise():
		npc.notify_suspicious_noise(generate_attention_target.bind(noise.global_position))


func _linear_curve() -> Curve:
	var curve := Curve.new()
	curve.max_domain = 10
	curve.min_domain = 0
	curve.max_value = 10
	curve.min_value = 0
	curve.add_point(Vector2(0, 0), 0, 1, Curve.TANGENT_FREE, Curve.TANGENT_LINEAR)
	curve.add_point(Vector2(10,10), 1, 0, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
	return curve


func _update_debug_state() -> void:
	for mesh in find_children("", "MeshInstance3D", false):
		mesh.free()
	if show_hearing_radius:
		generate_debug_mesh()
	if collision_shape:
		collision_shape.shape.radius = hearing_radius


func generate_debug_mesh() -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "HearingRadiusMesh"
	var sphere := SphereMesh.new()
	sphere.radius = hearing_radius
	sphere.height = hearing_radius*2
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0,0,1,0.1)
	sphere.material = material
	mesh_instance.mesh = sphere
	add_child(mesh_instance)
	if Engine.is_editor_hint():
		mesh_instance.owner = get_tree().edited_scene_root
