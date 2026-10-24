class_name NpcStateProcessor
extends Node

@export var npc: Npc
@export var state_chart: StateChart
@export var audio: AudioStreamPlayer3D


func play_sound(sound: AudioStream) -> void:
	if audio and sound:
		audio.stream = sound
		audio.play()
