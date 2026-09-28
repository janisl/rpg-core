extends WeaponStateBehaviour


func _on_state_entered() -> void:
	if weapon.animation_player:
		weapon.animation_player.play("idle")


func _on_state_processing(delta: float) -> void:
	if not weapon.current_weapon_data:
		return

	if Input.is_action_just_pressed("primary_fire") and weapon.can_fire():
		weapon.state_chart.send_event("onFiring")

	if not weapon.has_ammo():
		weapon.state_chart.send_event("onEmpty")
