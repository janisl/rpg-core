extends NpcStateProcessor

@export var investigate_sound: AudioStream

var _attention_spot: Sprite3D


func _on_investigate_state_entered() -> void:
	_enter_state()
	state_chart.send_event("ubody_raise_weapon")
	if npc.attention_target is Sprite3D:
		_attention_spot = npc.attention_target
		npc.nav_agent.target_position = _attention_spot.global_position
	play_sound(investigate_sound)


func _on_investigating_state_exited() -> void:
	_exit_state()
	if _attention_spot:
		_attention_spot.visible = false


func _on_investigate_state_physics_processing(delta: float) -> void:
	npc.move_npc_to_next_position(delta)
