@tool
extends NpcBTAction
## Sets a bool blackboard variable. Unlike [BTSetVar] it's skipped when a save
## is loaded past it, so it can't overwrite restored progress.

@export var variable: StringName
@export var value := true


func _generate_name() -> String:
	return "Set %s = %s" % [LimboUtility.decorate_var(variable), value]


func _update(_delta: float) -> Status:
	blackboard.set_var(variable, value)
	return SUCCESS
