class_name FootstepPlayer
extends AudioStreamPlayer3D

@export var generic_footstep_profile : AudioStreamRandomizer
@export var generic_landing_profile : AudioStreamRandomizer

@export_group("Object noise generation")
@export var is_npc := false
@export var use_debug_shape_noise := false
@export var sound_reduction_divisor := 2.0
@export var footstep_noise_duration := 0.5
@export_flags_3d_physics var footstep_noise_layer := PhysicsLayers.NOISE_DETECTION_MASK


func play_footstep(volume: float, speed: float) -> void:
	_play_sound(generic_footstep_profile, volume, 1.0)
	_spawn_footstep_noise(speed)


func play_landing(volume: float, pitch: float, speed: float) -> void:
	_play_sound(generic_landing_profile, volume, pitch)
	_spawn_footstep_noise(speed)


func _play_sound(profile: AudioStreamRandomizer, volume: float, pitch: float) -> void:
	stream = profile
	volume_db = volume
	pitch_scale = pitch
	play()


func _spawn_footstep_noise(noise_size: float) -> void:
	if is_npc:
		return
	var noise: ObjectNoise = ObjectNoise.new(use_debug_shape_noise)
	noise.set_parameters(ObjectNoise.NoiseType.Footstep, noise_size / sound_reduction_divisor, footstep_noise_duration, footstep_noise_layer)
	get_tree().current_scene.add_child(noise)
	noise.global_position = global_position
