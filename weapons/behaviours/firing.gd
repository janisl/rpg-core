extends WeaponStateBehaviour


func _on_state_entered() -> void:
	if not weapon_controller:
		return

	weapon_controller.fire_weapon()


func _on_state_physics_processing(_delta: float) -> void:
	if not weapon_controller:
		return

	if weapon_controller.current_ammo <= 0:
		weapon_controller.weapon_state_chart.send_event("onEmpty")
		return

	weapon_controller.weapon_state_chart.send_event("onIdle")
