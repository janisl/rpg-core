extends NpcStateProcessor

@export var alerted_sound: AudioStream
@export var must_have_been_the_wind_sound: AudioStream

func _on_alerted_state_entered() -> void:
	_enter_state()
	play_sound(alerted_sound)


func _on_alerted_state_exited() -> void:
	_exit_state()


func _on_alerted_state_physics_processing(delta: float) -> void:
	if not npc.attention_target:
		state_chart.send_event("idle")
		return
