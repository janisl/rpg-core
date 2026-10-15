class_name HealthAttribute
extends BaseAttribute

signal damage_taken(amount: float, source: Node3D)
signal died()

var is_alive := true


func take_damage(amount: float, source: Node3D = null) -> void:
	if not is_alive:
		return

	var actual_damage = max(0.0, amount)
	subtract(actual_damage)

	damage_taken.emit(actual_damage, source)

	print(get_parent().name, " took ", actual_damage, " damage. Health: ", value, "/", max_value)

	if value <= 0.0:
		_handle_death()


func heal(amount: float) -> void:
	if not is_alive:
		return

	var actual_heal = max(0.0, amount)
	add(actual_heal)

	print(get_parent().name, " healed ", actual_heal, " health. Health: ", value, "/", max_value)


func _handle_death() -> void:
	if not is_alive:
		return

	is_alive = false
	value = 0.0
	died.emit()

	print(get_parent().name, " died!")
