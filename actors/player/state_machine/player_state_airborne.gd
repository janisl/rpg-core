class_name PlayerStateAirborne
extends PlayerState


func _on_airborne_state_physics_processing(_delta: float) -> void:
	if player.is_on_floor():
		player.state_chart.send_event("onGrounded")
