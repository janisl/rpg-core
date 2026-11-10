class_name CarryController
extends Marker3D

signal started_carrying(interaction_node: CarryInteraction)

@export var player: Player
@export var rotation_speed := 2.0

@export_group("Drop Settings")
@export var max_drop_power := 1.0
@export var drop_power_mass_multiplier := 1.0

@export_group("Throw Settings")
@export var max_throw_power := 25.0
@export var throw_power_mass_multiplier := 10.0
@export var throw_stamina_threshold := 20.0
@export var throw_stamina_drain := 5.0
@export var drop_when_cant_throw := true

var carried_object: CarryInteraction:
	set = _set_carried_object

var is_carrying: bool:
	get: return carried_object != null

var _is_rotating := false


func _physics_process(_delta: float) -> void:
	if is_carrying and is_instance_valid(carried_object):
		if player.input_controller.primary_action_just_pressed:
			_attempt_throw()
			return

	if _is_rotating and (not is_carrying or not player.input_controller.secondary_action_pressed):
		_is_rotating = false
		player.state_chart.set_expression_property(&"is_rotating_carried_object", false)

	if not is_carrying:
		return

	if not _is_rotating and carried_object.enable_manual_rotating and player.input_controller.secondary_action_pressed:
		_is_rotating = true
		player.state_chart.set_expression_property(&"is_rotating_carried_object", true)


func save_state() -> Dictionary:
	var state := Dictionary()
	SaveUtils.save_ref(state, &"carried_object", carried_object)
	return state


func load_state(state: Dictionary) -> void:
	carried_object = SaveUtils.load_ref(state, &"carried_object")


func start_carrying(_carried_object: CarryInteraction) -> void:
	carried_object = _carried_object


func stop_carrying() -> void:
	carried_object = null
	EventBus.interactable_changed.emit()


func get_carry_destination_point(distance_offset: float) -> Vector3:
	var destination_point := global_position - distance_offset * player.camera_effects.global_basis.z

	if player.interaction_controller.is_colliding():
		var collision_point := player.interaction_controller.get_collision_point()
		var interaction_origin := player.interaction_controller.global_position

		if interaction_origin.distance_squared_to(destination_point) < interaction_origin.distance_squared_to(collision_point):
			return destination_point
		else:
			return collision_point

	return destination_point


func get_look_direction() -> Vector3:
	return -global_basis.z


func drop_carried_object() -> void:
	if !player.carry_controller.is_carrying:
		return
	var carried_object_mass := _get_carried_object_mass()
	var drop_force := carried_object_mass * drop_power_mass_multiplier
	drop_force = clamp(drop_force, 0, max_drop_power)
	carried_object.throw(drop_force)


func _on_rotating_carried_object_state_physics_processing(_delta: float) -> void:
	if not carried_object:
		return

	var input := player.input_controller.consume_look_delta()

	var object: Node3D = carried_object.get_parent()
	object.global_rotate(player.global_basis.y, -input.x)
	object.global_rotate(player.global_basis.x, -input.y)


func _set_carried_object(new_carried_object: CarryInteraction) -> void:
	carried_object = new_carried_object
	if carried_object != null:
		started_carrying.emit(carried_object)


func _attempt_throw() -> void:
	var carried_object_mass := _get_carried_object_mass()
	var throw_force := carried_object_mass * throw_power_mass_multiplier
	throw_force = clamp(throw_force, 0, max_throw_power)

	if throw_force >= throw_stamina_threshold:
		if player.stamina_attribute.value < throw_stamina_drain:
			if drop_when_cant_throw:
				player.carry_controller.drop_carried_object()
			return
		player.decrease_attribute(BaseAttribute.AttributeType.STAMINA, throw_stamina_drain)

	player.carry_controller.carried_object.throw(throw_force)


func _get_carried_object_mass() -> float:
	var carried_object_mass := 0.0
	var carried_object_parent := carried_object.get_parent()
	if carried_object_parent is RigidBody3D:
		carried_object_mass = (carried_object_parent as RigidBody3D).mass
	elif carried_object_parent is PhysicalBone3D:
		carried_object_mass = (carried_object_parent as PhysicalBone3D).mass
	return carried_object_mass
