class_name NpcIdleAction
extends Node

@onready var npc: Npc = $".."


func start() -> void:
	npc.set_upper_body_neutral()


func physics_process(delta: float) -> bool:
	npc.sight_detection.update_suspicion(delta, true)

	npc.stop_moving(delta)

	if npc.sight_detection.is_suspicious_of_target():
		npc.set_sight_target(npc.sight_detection.detected_target.global_position)
		npc.start_investigating()
		return true
	return false
