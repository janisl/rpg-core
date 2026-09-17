extends WeaponStateBehaviour


func _on_state_processing(delta: float) -> void:
	if not weapon_controller:
		return

	if Input.is_action_just_pressed("primary_fire") and weapon_controller.can_fire():
		weapon_controller.weapon_state_chart.send_event("onFiring")

	if weapon_controller.current_ammo <= 0:
		weapon_controller.weapon_state_chart.send_event("onEmpty")
