extends NpcStateProcessor

@export var animation_tree: AnimationTree
@export var idle_random_range := 1.0


func _ready() -> void:
	animation_tree["parameters/LowerBody/Standing/BlendTree/TimeSeek/seek_request"] = randf_range(0.0, idle_random_range)
	animation_tree.process_mode = Node.PROCESS_MODE_INHERIT


func _on_walking_state_physics_processing(_delta: float) -> void:
	var relative_velocity := npc.global_basis.inverse() * ((npc.velocity * Vector3(0.5,0,0.5)) / npc.walk_speed)
	_set_animation_ready(relative_velocity)


func _on_running_state_physics_processing(_delta: float) -> void:
	var relative_velocity := npc.global_basis.inverse() * ((npc.velocity * Vector3(1,0,1)) / npc.sprint_speed)
	_set_animation_ready(relative_velocity)


func _set_animation_ready(relative_velocity: Vector3) -> void:
	var rel_velocity_xz := Vector2(relative_velocity.x, -relative_velocity.z)
	npc.velocity_debug_shape.position = relative_velocity
	animation_tree["parameters/LowerBody/Standing/blend_position"] = rel_velocity_xz


func _on_neutral_state_entered() -> void:
	_upper_body_travel("Neutral")
	npc.unequip_weapon()


func _on_raised_weapon_state_entered() -> void:
	if npc.is_using_weapon():
		npc.equip_weapon()
		_upper_body_travel("PistolReady")
	else:
		_upper_body_travel("RaisedFists")


func _upper_body_travel(state: String) -> void:
	var upper_body_state = animation_tree.get("parameters/UpperBody/playback")
	if upper_body_state.get_current_node() != state:
		upper_body_state.travel(state)


func _on_attack_state_entered() -> void:
	animation_tree.set("parameters/UpperBody/RaisedFists/attack/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func _on_attack_state_physics_processing(_delta: float) -> void:
	var is_attack_active = animation_tree.get("parameters/UpperBody/RaisedFists/attack/active")
	if !is_attack_active:
		state_chart.send_event("ubody_raise_weapon")


func _on_health_attribute_damage_taken(_hit_info: HitInfo) -> void:
	animation_tree.set("parameters/hurt/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
