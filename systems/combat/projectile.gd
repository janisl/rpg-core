class_name Projectile
extends RigidBody3D

var source: CharacterBody3D
var damage: float


func setup(src: CharacterBody3D, vel: Vector3, dmg: float) -> void:
	source = src
	linear_velocity = vel
	damage = dmg


func _ready() -> void:
	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = 10
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(10.0).timeout.connect(queue_free)


func _on_body_entered(body: Node3D) -> void:
	if body == source:
		return

	_spawn_impact_marker(global_position)

	var health_attribute := body.get_node_or_null("HealthAttribute") as HealthAttribute
	if health_attribute:
		var hit_info := HitInfo.new(damage)
		hit_info.source = source
		hit_info.direction = linear_velocity.normalized()
		hit_info.impact_position = global_position
		health_attribute.take_damage(hit_info)

	if body is RigidBody3D:
		body.apply_impulse(global_position.direction_to(body.global_position) * 5.0 / body.mass, global_position - body.global_position)

	queue_free()


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
