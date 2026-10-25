class_name NpcStateProcessor
extends Node

@export var npc: Npc
@export var state_chart: StateChart
@export var audio: AudioStreamPlayer3D
@export var behaviour_state := Npc.BehaviourState.None


func _enter_state():
	npc.current_behaviour = behaviour_state


func _exit_state():
	npc.previous_behaviour = behaviour_state


func play_sound(sound: AudioStream) -> void:
	if audio and sound:
		audio.stream = sound
		audio.play()
