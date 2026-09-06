class_name PlayerStateIdle
extends PlayerState


func _on_idle_state_processing(_delta: float) -> void:
	if player and player.input_dir.length() > 0:
		player.state_chart.send_event("onMoving")
