class_name NpcBTAction
extends BTAction
## Base for NPC leaf tasks. Set [member resuming] (done by save loading) to make
## the next [method _enter] call [method _resume] instead of [method _start], so
## state restored from a save isn't reset.

var resuming := false


func _enter() -> void:
	if resuming:
		resuming = false
		_resume()
	else:
		_start()


func _start() -> void:
	pass


func _resume() -> void:
	pass
