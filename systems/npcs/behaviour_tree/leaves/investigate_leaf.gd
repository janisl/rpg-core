@tool
extends NpcActionLeaf

@export var investigate_sound: AudioStream

var _investigate_action: NpcInvestigateAction


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	_investigate_action = NpcInvestigateAction.new(npc)


func _start() -> void:
	npc.set_upper_body_raised_weapon()
	_investigate_action.start()
	npc.play_sound(investigate_sound)


func tick(_actor: Node, _blackboard: Blackboard) -> int:
	_investigate_action.physics_process(get_physics_process_delta_time())
	return RUNNING
