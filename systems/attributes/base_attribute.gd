class_name BaseAttribute
extends Node

signal value_changed(new_value: float, old_value: float, max_value: float)
signal value_reached_zero()

@export var attribute_name : String
@export var max_value : float
@export var initial_value : float

var value : float:
	set(new_value):
		var prev_value = value
		value = clampf(new_value, 0, max_value)
		if value == prev_value:
			return

		value_changed.emit(value, prev_value, max_value)
		if value <= 0:
			value = 0
			value_reached_zero.emit()


func _ready() -> void:
	value = initial_value


func set_attribute(_value: float, _max_value: float):
	max_value = _max_value
	value = _value


func add(amount):
	value += amount


func subtract(amount):
	value -= amount
