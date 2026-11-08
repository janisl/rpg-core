class_name CarryController
extends Marker3D

signal started_carrying(interaction_node: CarryInteraction)

#@export var player: Player

var carried_object: CarryInteraction:
	set = _set_carried_object

var is_carrying: bool:
	get: return carried_object != null


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


func _set_carried_object(new_carried_object: CarryInteraction) -> void:
	carried_object = new_carried_object
	if carried_object != null:
		started_carrying.emit(carried_object)
