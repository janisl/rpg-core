class_name PlayerStateJumping
extends PlayerState


func _on_jumping_state_processing(delta: float) -> void:
	if player.velocity.y < 0:
		player.state_chart.send_event("onFalling")
