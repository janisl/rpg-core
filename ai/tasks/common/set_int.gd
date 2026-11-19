@tool
extends NpcBTAction
## Sets an int blackboard variable. Unlike [BTSetVar] it's skipped when a save
## is loaded past it, so it can't overwrite restored progress.

@export var variable: StringName
@export var value := 0


func _generate_name() -> String:
	return "Set %s = %d" % [LimboUtility.decorate_var(variable), value]


func _update(_delta: float) -> Status:
	blackboard.set_var(variable, value)
	return SUCCESS
