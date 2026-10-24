extends NpcStateProcessor


func _on_attack_state_entered() -> void:
	_attack()


func _attack() -> void:
	npc.velocity = Vector3.ZERO
	npc.nav_agent.velocity = Vector3.ZERO

	if npc.target:
		var target_rotation = npc.get_look_at_angle(npc.target.global_position)
		npc.rotation.y = target_rotation
		_apply_damage_to_target()

	if npc.anim_tree_state.get_current_node() != "Melee":
		npc.anim_tree_state.travel("Melee")
	else:
		npc.anim_tree_state.start("Melee")

	await npc.animation_tree.animation_finished

	if npc.target:
		var distance = npc.global_position.distance_to(npc.target.global_position)
		if distance <= npc.melee_range:
			_attack()
		else:
			state_chart.send_event("onChase")
	else:
		state_chart.send_event("onIdle")


func _apply_damage_to_target() -> void:
	var target_health_attribute := npc.target.get_node_or_null("HealthAttribute") as HealthAttribute

	if target_health_attribute:
		var hit_info := HitInfo.new(npc.melee_damage)
		hit_info.source = npc
		var direction := npc.global_position.direction_to(npc.target.global_position)
		hit_info.direction = direction
		hit_info.impact_position = npc.target.global_position - direction * 0.5 + Vector3.UP * npc.melee_hit_height
		target_health_attribute.take_damage(hit_info)
