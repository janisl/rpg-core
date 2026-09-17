extends WeaponStateBehaviour


func _on_state_entered() -> void:
	if not weapon_controller:
		return

	weapon_controller.fire_weapon()


func _on_state_physics_processing(_delta: float) -> void:
	if not weapon_controller:
		return

	if not weapon_controller.has_ammo():
		weapon_controller.weapon_state_chart.send_event("onEmpty")
		return

	if weapon_controller.current_weapon.is_automatic:
		if Input.is_action_pressed("primary_fire"):
			if weapon_controller.can_fire():
				weapon_controller.fire_weapon()
			return

	weapon_controller.weapon_state_chart.send_event("onIdle")
