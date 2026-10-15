class_name HealthAttribute
extends BaseAttribute

signal damage_taken(hit_info: HitInfo)
signal died()

var is_alive := true


func take_damage(hit_info: HitInfo) -> void:
	if not is_alive:
		return

	subtract(hit_info.actual_damage)

	damage_taken.emit(hit_info)

	print(get_parent().name, " took ", hit_info.actual_damage, " damage. Health: ", value, "/", max_value)

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
