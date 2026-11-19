@tool
class_name NpcBTAction
extends BTAction
## Base for NPC leaf tasks, adding save support. Subclasses implement
## [method _start], [method _update] and [method _end] instead of the
## [BTAction] callbacks, and [method _save_state] / [method _load_state] for
## progress that must survive a save.
##
## Loading marks the leaves that were running as [member resuming] (the next
## enter calls [method _resume] instead of [method _start]) and leaves that had
## already completed in a running sequence or parallel as [member skip] (the
## next run returns SUCCESS without doing anything).

var resuming := false
var skip := false

var _skipping := false


func _enter() -> void:
	if skip:
		skip = false
		_skipping = true
	elif resuming:
		resuming = false
		_resume()
	else:
		_start()


func _tick(delta: float) -> Status:
	if _skipping:
		return SUCCESS
	return _update(delta)


func _exit() -> void:
	if _skipping:
		_skipping = false
	else:
		_end()


func _start() -> void:
	pass


## Called instead of [method _start] when continuing after a load, after
## [method _load_state]. Re-attach runtime state that isn't saved.
func _resume() -> void:
	pass


func _update(_delta: float) -> Status:
	return SUCCESS


func _end() -> void:
	pass


func _save_state() -> Dictionary:
	return {}


func _load_state(_state: Dictionary) -> void:
	pass
