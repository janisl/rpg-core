class_name StateBehaviour
extends Node


func _ready() -> void:
	var state = get_parent() as StateChartState
	if not state:
		return

	state.state_entered.connect(_on_state_entered)
	state.state_exited.connect(_on_state_exited)
	state.state_processing.connect(_on_state_processing)
	state.state_physics_processing.connect(_on_state_physics_processing)
	state.state_unhandled_input.connect(_on_state_unhandled_input)


func _on_state_entered() -> void:
	pass


func _on_state_exited() -> void:
	pass


func _on_state_processing(delta: float) -> void:
	pass


func _on_state_physics_processing(delta: float) -> void:
	pass


func _on_state_unhandled_input(evemt: InputEvent) -> void:
	pass


func _find_owner() -> Node:
	var p = get_parent()
	while p:
		if p is StateChart:
			return p.get_parent()
		p = p.get_parent()

	return null
