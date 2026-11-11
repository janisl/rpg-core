@tool
class_name NpcActionLeaf
extends ActionLeaf

## Base for leaves that run one NPC action.
## Keeps the NPC's current and previous behaviour up to date, like the state processors do.

@export var npc: Npc
@export var behaviour_state := Npc.BehaviourState.None

var _is_running := false


func before_run(_actor: Node, _blackboard: Blackboard) -> void:
	if _is_running:
		return

	_is_running = true
	npc.current_behaviour = behaviour_state
	_start()


func after_run(_actor: Node, _blackboard: Blackboard) -> void:
	_finish()


func interrupt(actor: Node, blackboard: Blackboard) -> void:
	_finish()
	super(actor, blackboard)


func _finish() -> void:
	if not _is_running:
		return

	_is_running = false
	npc.previous_behaviour = behaviour_state
	_stop()


func _start() -> void: # virtual
	pass


func _stop() -> void: # virtual
	pass
