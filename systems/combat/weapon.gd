class_name Weapon
extends Wieldable

const MAGAZINE_KEY := "magazine_ammo"
const LOADED_AMMO_KEY := "loaded_ammo_index"
const SELECTED_AMMO_KEY := "selected_ammo_index"

var _weapon_data: WeaponData

var _fire_rate_timer := 0.0
var _reload_timer := 0.0


func initialize(own: Actor, inventory: Inventory, stack: ItemStack) -> void:
	super(own, inventory, stack)

	_weapon_data = _item_stack.item as WeaponData


func _get_magazine_ammo() -> int:
	return _item_stack.metadata.get(MAGAZINE_KEY, 0)


func _set_magazine_ammo(value: int) -> void:
	_item_stack.metadata[MAGAZINE_KEY] = value
	_emit_data_changed()


func _get_loaded_ammo() -> AmmoData:
	if _weapon_data.ammo_types.is_empty():
		return null

	var index: int = _item_stack.metadata.get(LOADED_AMMO_KEY, 0)
	return _weapon_data.ammo_types[clampi(index, 0, _weapon_data.ammo_types.size() - 1)]


func _get_selected_ammo() -> AmmoData:
	if _weapon_data.ammo_types.is_empty():
		return null

	var index: int = _item_stack.metadata.get(SELECTED_AMMO_KEY, 0)
	return _weapon_data.ammo_types[clampi(index, 0, _weapon_data.ammo_types.size() - 1)]


func _get_reserve_ammo(ammo: AmmoData) -> int:
	if not ammo:
		return 0
	if not _owner_inventory:
		return _weapon_data.magazine_size

	return _owner_inventory.get_available_amount(ammo)


func _has_ammo() -> bool:
	return _get_magazine_ammo() > 0


func _can_reload() -> bool:
	var selected := _get_selected_ammo()
	if _get_reserve_ammo(selected) <= 0:
		return false

	return selected != _get_loaded_ammo() or _get_magazine_ammo() < _weapon_data.magazine_size


func _cycle_ammo() -> bool:
	var count := _weapon_data.ammo_types.size()
	var index: int = _item_stack.metadata.get(SELECTED_AMMO_KEY, 0)
	for i in range(1, count):
		var next := (index + i) % count
		if _get_reserve_ammo(_weapon_data.ammo_types[next]) > 0:
			_item_stack.metadata[SELECTED_AMMO_KEY] = next
			_emit_data_changed()
			return true

	return false


func _get_damage() -> float:
	var ammo := _get_loaded_ammo()
	return _weapon_data.damage * (ammo.damage_multiplier if ammo else 1.0)


func _get_accuracy_spread() -> float:
	var ammo := _get_loaded_ammo()
	var accuracy := _weapon_data.accuracy * (ammo.accuracy_multiplier if ammo else 1.0)
	return (100.0 - clampf(accuracy, 0.0, 100.0)) / 1000.0


func _get_spread_multiplier() -> float:
	var ammo := _get_loaded_ammo()
	return ammo.spread_multiplier if ammo else 1.0


func _get_pellet_count() -> int:
	var ammo := _get_loaded_ammo()
	if ammo and ammo.pellet_count_override > 0:
		return ammo.pellet_count_override
	return _weapon_data.pellet_count


func _get_projectile_scene() -> PackedScene:
	var ammo := _get_loaded_ammo()
	if ammo and ammo.projectile_scene_override:
		return ammo.projectile_scene_override
	return _weapon_data.projectile_scene


func _can_fire() -> bool:
	return _has_ammo()


func _fire_weapon() -> void:
	if not _can_fire():
		return

	_set_magazine_ammo(_get_magazine_ammo() - 1)
	_emit_primary_action_started()

	_fire_rate_timer = 1.0 / _weapon_data.fire_rate

	var camera_collision := _get_camera_collision()
	var look_basis := Basis.looking_at(_forward_direction)
	var from := _from_position + look_basis * _weapon_data.fire_offset
	var fire_direction := from.direction_to(camera_collision)

	_perform_attack(from, fire_direction)


func _perform_attack(_from: Vector3, _fire_direction: Vector3) -> void:
	pass


func _get_camera_collision() -> Vector3:
	var ray_end = _from_position + _forward_direction * _item_stack.item.range

	var query = PhysicsRayQueryParameters3D.create(_from_position, ray_end)
	query.exclude = [ _item_owner.get_rid() ]
	var result = get_world_3d().direct_space_state.intersect_ray(query)

	if result:
		return result.position
	return ray_end


func _finish_reload() -> void:
	var selected := _get_selected_ammo()
	var loaded := _get_loaded_ammo()

	if loaded != selected:
		if loaded and _owner_inventory and _get_magazine_ammo() > 0:
			_owner_inventory.add_item(loaded, _get_magazine_ammo())
		_item_stack.metadata[LOADED_AMMO_KEY] = _item_stack.metadata.get(SELECTED_AMMO_KEY, 0)
		_set_magazine_ammo(0)

	var amount := mini(_weapon_data.magazine_size - _get_magazine_ammo(), _get_reserve_ammo(selected))
	if _owner_inventory:
		_owner_inventory.remove_item(selected, amount)
	_set_magazine_ammo(_get_magazine_ammo() + amount)


func _on_idle_state_processing(_delta: float) -> void:
	if not _has_ammo():
		if not _can_reload():
			_cycle_ammo()
		state_chart.send_event("onReload" if _can_reload() else "onEmpty")
		return

	if _cycle_ammo_pressed and _cycle_ammo() and _can_reload():
		state_chart.send_event("onReload")
		return

	if _reload_pressed and _can_reload():
		state_chart.send_event("onReload")
		return

	if _primary_action_just_pressed and _can_fire():
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
		if _primary_action_pressed:
			if _can_fire():
				_fire_weapon()
			return

	state_chart.send_event("onIdle")


func _on_reloading_state_entered() -> void:
	_reload_timer = _weapon_data.reload_time
	_emit_reload_started()


func _on_reloading_state_processing(delta: float) -> void:
	_reload_timer -= delta
	if _reload_timer > 0.0:
		return

	_finish_reload()
	state_chart.send_event("onIdle")


func _on_empty_state_entered() -> void:
	print("Weapon empty!")


func _on_empty_state_processing(_delta: float) -> void:
	if _can_reload() or _cycle_ammo():
		state_chart.send_event("onIdle")


func _get_spread_delta(direction: Vector3, spread: float) -> Vector3:
	var spread_x := randf_range(-spread, spread)
	var spread_y := randf_range(-spread, spread)
	var direction_basis := Basis.looking_at(direction)
	return Vector3(spread_x, spread_y, 0) * direction_basis
