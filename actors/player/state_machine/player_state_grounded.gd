class_name PlayerStateGrounded
extends PlayerState


func _on_grounded_state_physics_processing(_delta: float) -> void:
	if Input.is_action_just_pressed("jump") and player.is_on_floor():
		player.jump()
		player.state_chart.send_event("onAirborne")

	if not player.is_on_floor():
		player.state_chart.send_event("onAirborne")
