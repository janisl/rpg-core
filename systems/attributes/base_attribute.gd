class_name BaseAttribute
extends Node

enum ValueType { CURRENT, MAX }

signal value_changed(new_value: float, old_value: float, max_value: float)
signal value_reached_zero()

@export var attribute_name : String
@export var display_name : String
@export var max_value : float
@export var initial_value : float

var value : float:
	set(new_value):
		var prev_value := value
		value = clampf(new_value, 0, max_value)
		if value == prev_value:
			return

		value_changed.emit(value, prev_value, max_value)
		if value <= 0:
			value = 0
			value_reached_zero.emit()


func _ready() -> void:
	value = initial_value
	add_to_group("persist_component")


func set_attribute(_value: float, _max_value: float) -> void:
	max_value = _max_value
	value = _value


func add(amount: float) -> void:
	value += amount


func subtract(amount: float) ->void:
	value -= amount


func save_state() -> Dictionary:
	return {
		&"value" : value,
		&"max_value" : max_value,
	}


func load_state(state: Dictionary) -> void:
	value = state.get(&"value", value)
	max_value = state.get(&"max_value", max_value)
