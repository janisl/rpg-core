extends NpcStateProcessor

@export var investigate_sound: AudioStream

var _investigate_action: NpcInvestigateAction


func _enter_tree() -> void:
	_investigate_action = NpcInvestigateAction.new(npc)


func save_state() -> Dictionary:
	return _investigate_action.save_state()


func load_state(state: Dictionary) -> void:
	_investigate_action.load_state(state)


func _on_investigate_state_entered() -> void:
	_enter_state()
	npc.set_upper_body_raised_weapon()
	_investigate_action.start()
	play_sound(investigate_sound)


func _on_investigating_state_exited() -> void:
	_exit_state()


func _on_investigate_state_physics_processing(delta: float) -> void:
	_investigate_action.physics_process(delta)
