class_name NpcIdleAction
extends Node

@onready var npc: Npc = $".."


func physics_process(delta: float) -> void:
	npc.sight_detection.update_suspicion(delta, true)

	npc.stop_moving(delta)
