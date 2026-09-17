class_name WeaponController
extends Node

@export_group("References")
@export var player: Player
@export var camera: Camera3D
@export var weapon_model_parent: Node3D
@export var weapon_state_chart: StateChart
@export_group("Weapon controller params")
@export var current_weapon: Weapon
@export_flags_3d_physics var hit_scan_collision_mask: int = 1

var current_weapon_model: Node3D
var current_ammo: int
var can_fire_next := true
var fire_rate_timer := 0.0


func _ready() -> void:
	if current_weapon:
		_spawn_weapon_model()
		current_ammo = current_weapon.max_amo


func _process(delta: float) -> void:
	if fire_rate_timer > 0.0:
		fire_rate_timer -= delta
		if fire_rate_timer <= 0:
			can_fire_next = true

func can_fire() -> bool:
	return current_ammo > 0 and can_fire_next


func fire_weapon() -> void:
	if not can_fire():
		return

	current_ammo -= 1
	print("Fired! Ammo: ", current_ammo)

	can_fire_next = false
	fire_rate_timer = 1.0 / current_weapon.fire_rate

	if current_weapon.is_hit_scan:
		_perform_hit_scan()
	else:
		_spawn_projectile()


func _spawn_weapon_model() -> void:
	if current_weapon_model:
		current_weapon_model.queue_free()

	if current_weapon.weapon_scene:
		current_weapon_model = current_weapon.weapon_scene.instantiate()
		weapon_model_parent.add_child(current_weapon_model)
		current_weapon_model.position = current_weapon.weapon_position


func _perform_hit_scan() -> void:
	if not camera:
		print("No camera assigned")
		return

	var space_state := camera.get_world_3d().direct_space_state
	var from := camera.global_position
	var forward := -camera.global_transform.basis.z

	var accuracy_spread := (100.0 - current_weapon.accuracy) / 1000.0

	for i in current_weapon.pellet_count:
		var accuracy_x := randf_range(-accuracy_spread, accuracy_spread)
		var accuracy_y := randf_range(-accuracy_spread, accuracy_spread)
		var direction := forward + Vector3(accuracy_x, accuracy_y, 0) * camera.global_transform.basis

		if current_weapon.pellet_count > 1:
			var spread_x := randf_range(-current_weapon.spread_angle, current_weapon.spread_angle)
			var spread_y := randf_range(-current_weapon.spread_angle, current_weapon.spread_angle)
			direction += Vector3(spread_x, spread_y, 0) * camera.global_transform.basis

		var to := from + direction * current_weapon.range

		var query := PhysicsRayQueryParameters3D.create(from, to)
		query.collision_mask = hit_scan_collision_mask
		var result := space_state.intersect_ray(query)

		if not result:
			print("No hit!")
			return

		print("Hit: ", result.collider.name, " at ", result.position)
		_spawn_impact_marker(result.position)


func _spawn_impact_marker(position: Vector3) -> void:
	var marker := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.1, 0.1, 0.1)
	marker.mesh = box

	var material := StandardMaterial3D.new()
	material.albedo_color = Color.RED
	marker.set_surface_override_material(0, material)

	get_tree().current_scene.add_child(marker)
	marker.global_position = position

	get_tree().create_timer(2.0).timeout.connect(marker.queue_free)


func _spawn_projectile() -> void:
	if not current_weapon.projectile_scene:
		print("No projectile addigned")
		return

	if not camera:
		print("No camera assigned")
		return

	var projectile := current_weapon.projectile_scene.instantiate() as Projectile
	get_tree().current_scene.add_child(projectile)

	projectile.global_position = camera.global_position

	var forward := -camera.global_transform.basis.z

	var accuracy_spread := (100.0 - current_weapon.accuracy) / 1000.0
	var accuracy_x := randf_range(-accuracy_spread, accuracy_spread)
	var accuracy_y := randf_range(-accuracy_spread, accuracy_spread)
	var direction := forward + Vector3(accuracy_x, accuracy_y, 0) * camera.global_transform.basis

	var velocity := direction * current_weapon.projectile_speed

	projectile.look_at(camera.global_position + direction, Vector3.UP)
	projectile.setup(player, velocity, current_weapon.damage)
