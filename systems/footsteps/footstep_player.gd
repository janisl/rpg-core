class_name FootstepPlayer
extends AudioStreamPlayer3D

@export var generic_footstep_profile : AudioStreamRandomizer
@export var generic_landing_profile : AudioStreamRandomizer


func play_footstep(volume: float) -> void:
	_play_sound(generic_footstep_profile, volume, 1.0)


func play_landing(volume: float, pitch: float) -> void:
	_play_sound(generic_landing_profile, volume, pitch)


func _play_sound(profile: AudioStreamRandomizer, volume: float, pitch: float) -> void:
	stream = profile
	volume_db = volume
	pitch_scale = pitch
	play()
