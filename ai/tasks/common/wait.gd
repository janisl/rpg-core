@tool
extends NpcBTAction
## Stands still for [member duration] seconds, optionally facing a position.
## Unlike [BTWait], the progress survives saving.

@export var duration := 1.0
## Blackboard variable with a Vector3 position to face. Empty to not turn.
@export var face_var: StringName

var _elapsed := 0.0


func _generate_name() -> String:
	var text := "Wait %ss" % duration
	if face_var:
		text += " facing %s" % LimboUtility.decorate_var(face_var)
	return text


func _start() -> void:
	_elapsed = 0.0


func _update(delta: float) -> Status:
	agent.stop_moving(delta)
	if face_var:
		agent.face_direction(blackboard.get_var(face_var, agent.global_position))

	_elapsed += delta
	if _elapsed >= duration:
		return SUCCESS
	return RUNNING


func _save_state() -> Dictionary:
	return { &"elapsed": _elapsed }


func _load_state(state: Dictionary) -> void:
	_elapsed = state.get(&"elapsed", 0.0)
