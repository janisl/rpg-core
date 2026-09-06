class_name PlayerStateMoving
extends PlayerState


func _on_moving_state_processing(_delta: float) -> void:
	if player.input_dir.length() == 0 and player.velocity.length() < 0.5:
		player.state_chart.send_event("onIdle")
