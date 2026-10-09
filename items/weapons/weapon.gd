class_name Weapon
extends Wieldable

signal weapon_idle
signal weapon_fired
signal weapon_reload_started
signal bullet_fired(target_position: Vector3)

const MAGAZINE_KEY := "magazine_ammo"

var _weapon_data: WeaponData

var _fire_rate_timer := 0.0
var _reload_timer := 0.0

@onready var state_chart: StateChart = $StateChart


func initialize(own: Actor, inventory: Inventory, stack: ItemStack) -> void:
	super(own, inventory, stack)

	_weapon_data = _item_stack.item as WeaponData


func _get_magazine_ammo() -> int:
	return _item_stack.metadata.get(MAGAZINE_KEY, 0)


func _set_magazine_ammo(value: int) -> void:
	_item_stack.metadata[MAGAZINE_KEY] = value
	if _owner_inventory:
		_owner_inventory.changed.emit()


func _get_reserve_ammo() -> int:
	if not _owner_inventory:
		return _weapon_data.magazine_size

	return _owner_inventory.get_available_amount(_weapon_data.ammo_type)


func _has_ammo() -> bool:
	return _get_magazine_ammo() > 0


func _can_reload() -> bool:
	return _get_magazine_ammo() < _weapon_data.magazine_size and _get_reserve_ammo() > 0


func _can_fire() -> bool:
	return _has_ammo()


func _fire_weapon() -> void:
	if not _can_fire():
		return

	_set_magazine_ammo(_get_magazine_ammo() - 1)
	weapon_fired.emit()

	_fire_rate_timer = 1.0 / _weapon_data.fire_rate

	_perform_attack()


func _perform_attack() -> void:
	pass


func _finish_reload() -> void:
	var amount := mini(_weapon_data.magazine_size - _get_magazine_ammo(), _get_reserve_ammo())
	if _owner_inventory:
		_owner_inventory.remove_item(_weapon_data.ammo_type, amount)
	_set_magazine_ammo(_get_magazine_ammo() + amount)


func _on_idle_state_entered() -> void:
	weapon_idle.emit()


func _on_idle_state_processing(_delta: float) -> void:
	if not _has_ammo():
		state_chart.send_event("onReload" if _can_reload() else "onEmpty")
		return

	if _reload_pressed and _can_reload():
		state_chart.send_event("onReload")
		return

	if _attack_just_pressed and _can_fire():
		state_chart.send_event("onFiring")


func _on_firing_state_entered() -> void:
	_fire_weapon()


func _on_firing_state_processing(delta: float) -> void:
	if _fire_rate_timer > 0.0:
		_fire_rate_timer -= delta
		if _fire_rate_timer > 0.0:
			return

	if not _has_ammo():
		state_chart.send_event("onIdle")
		return

	if _weapon_data.is_automatic:
		if _attack_pressed:
			if _can_fire():
				_fire_weapon()
			return

	state_chart.send_event("onIdle")


func _on_reloading_state_entered() -> void:
	_reload_timer = _weapon_data.reload_time
	weapon_reload_started.emit()


func _on_reloading_state_processing(delta: float) -> void:
	_reload_timer -= delta
	if _reload_timer > 0.0:
		return

	_finish_reload()
	state_chart.send_event("onIdle")


func _on_empty_state_entered() -> void:
	print("Weapon empty!")


func _on_empty_state_processing(_delta: float) -> void:
	if _can_reload():
		state_chart.send_event("onIdle")


func _get_spread_delta(spread: float) -> Vector3:
	var spread_x := randf_range(-spread, spread)
	var spread_y := randf_range(-spread, spread)
	var basis := Basis.looking_at(_forward_direction)
	return Vector3(spread_x, spread_y, 0) * basis
