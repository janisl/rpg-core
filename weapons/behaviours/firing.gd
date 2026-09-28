extends WeaponStateBehaviour


func _on_state_entered() -> void:
	weapon.fire_weapon()


func _on_state_physics_processing(_delta: float) -> void:
	if not weapon.has_ammo():
		weapon.state_chart.send_event("onEmpty")
		return

	if weapon.current_weapon_data.is_automatic:
		if Input.is_action_pressed("primary_fire"):
			if weapon.can_fire():
				weapon.fire_weapon()
			return

	if not weapon.animation_player.is_playing():
		weapon.state_chart.send_event("onIdle")
