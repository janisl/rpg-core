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


func _ready() -> void:
	if current_weapon:
		spawn_weapon_model()
		current_ammo = current_weapon.max_amo


func spawn_weapon_model() -> void:
	if current_weapon_model:
		current_weapon_model.queue_free()

	if current_weapon.weapon_scene:
		current_weapon_model = current_weapon.weapon_scene.instantiate()
		weapon_model_parent.add_child(current_weapon_model)
		current_weapon_model.position = current_weapon.weapon_position


func can_fire() -> bool:
	return current_ammo > 0


func fire_weapon() -> void:
	if not can_fire():
		return

	current_ammo -= 1
	print("Fired! Ammo: ", current_ammo)
	if current_weapon.is_hit_scan:
		_perform_hit_scan()
	else:
		_spawn_projectile()


func _perform_hit_scan() -> void:
	if not camera:
		print("No camera assigned")
		return

	var space_state := camera.get_world_3d().direct_space_state
	var from := camera.global_position
	var forward := -camera.global_transform.basis.z
	var to := from + forward * current_weapon.range

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
	var velocity := forward * current_weapon.projectile_speed

	projectile.look_at(camera.global_position + forward, Vector3.UP)
	projectile.setup(player, velocity, current_weapon.damage)
