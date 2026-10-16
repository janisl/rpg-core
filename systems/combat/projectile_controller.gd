class_name ProjectileController
extends Node

var _rigid_body: RigidBody3D
var _source: CharacterBody3D
var _damage: float


func _ready() -> void:
	_rigid_body = get_parent() as RigidBody3D
	_rigid_body.continuous_cd = true
	_rigid_body.contact_monitor = true
	_rigid_body.max_contacts_reported = 10
	_rigid_body.body_entered.connect(_on_body_entered)
	get_tree().create_timer(10.0).timeout.connect(_rigid_body.queue_free)


func setup(src: CharacterBody3D, vel: Vector3, dmg: float) -> void:
	_source = src
	_rigid_body.linear_velocity = vel
	_damage = dmg


func _on_body_entered(body: Node3D) -> void:
	if body == _source:
		return

	_spawn_impact_marker(_rigid_body.global_position)

	var health_attribute := body.get_node_or_null("HealthAttribute") as HealthAttribute
	if health_attribute:
		var hit_info := HitInfo.new(_damage)
		hit_info.source = _source
		hit_info.direction = _rigid_body.linear_velocity.normalized()
		hit_info.impact_position = _rigid_body.global_position
		health_attribute.take_damage(hit_info)

	if body is RigidBody3D:
		body.apply_impulse(
			_rigid_body.global_position.direction_to(body.global_position) * 5.0 / body.mass,
			_rigid_body.global_position - body.global_position)

	_rigid_body.queue_free()


func _spawn_impact_marker(impact_position: Vector3) -> void:
	var marker := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.1, 0.1, 0.1)
	marker.mesh = box

	var material := StandardMaterial3D.new()
	material.albedo_color = Color.RED
	marker.set_surface_override_material(0, material)

	get_tree().current_scene.add_child(marker)
	marker.global_position = impact_position

	get_tree().create_timer(2.0).timeout.connect(marker.queue_free)
