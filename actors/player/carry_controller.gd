class_name CarryController
extends Marker3D

signal started_carrying(interaction_node: CarryInteraction)

@export var player: Player
@export var rotation_speed := 2.0

var carried_object: CarryInteraction:
	set = _set_carried_object

var is_carrying: bool:
	get: return carried_object != null

var _is_rotating := false


func _physics_process(_delta: float) -> void:
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
