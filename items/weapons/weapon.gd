class_name Weapon
extends Item

signal weapon_idle
signal weapon_fired

var current_weapon_data: WeaponData
var player: Player
var camera: CameraEffects
var hit_scan_collision_mask: int
var weapon_manager: WeaponManager

var fire_rate_timer := 0.0

@onready var state_chart: StateChart = $StateChart


func has_ammo() -> bool:
	return weapon_manager.get_current_ammo(current_weapon_data.ammo_type) > 0


func can_fire() -> bool:
	return has_ammo()


func fire_weapon() -> void:
	if not can_fire():
		return

	Managers.weapon_manager.use_ammo(current_weapon_data.ammo_type)
	weapon_fired.emit()

	fire_rate_timer = 1.0 / current_weapon_data.fire_rate

	camera.add_recoil(
		current_weapon_data.recoil_cam_pitch,
		current_weapon_data.recoil_cam_yaw,
		current_weapon_data.recoil_cam_roll)

	_perform_attack()


func _perform_attack() -> void:
	pass


func _on_idle_state_entered() -> void:
	weapon_idle.emit()


func _on_idle_state_processing(_delta: float) -> void:
	if Input.is_action_just_pressed("primary_fire") and can_fire():
		state_chart.send_event("onFiring")

	if not has_ammo():
		state_chart.send_event("onEmpty")


func _on_firing_state_entered() -> void:
	fire_weapon()


func _on_firing_state_processing(delta: float) -> void:
	if fire_rate_timer > 0.0:
		fire_rate_timer -= delta
		if fire_rate_timer > 0.0:
			return

	if not has_ammo():
		state_chart.send_event("onEmpty")
		return

	if current_weapon_data.is_automatic:
		if Input.is_action_pressed("primary_fire"):
			if can_fire():
				fire_weapon()
			return

	state_chart.send_event("onIdle")


func _on_empty_state_entered() -> void:
	print("Weapon empty!")
