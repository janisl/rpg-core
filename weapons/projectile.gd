class_name Projectile
extends Area3D

var source: CharacterBody3D
var velocity: Vector3
var damage: float


func setup(src: CharacterBody3D, vel: Vector3, dmg: float) -> void:
	source = src
	velocity = vel
	damage = dmg


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(10.0).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	var space_state := get_world_3d().direct_space_state
	var start_pos := global_position
	var end_pos := global_position + velocity * delta

	var query := PhysicsRayQueryParameters3D.create(start_pos, end_pos)
	query.collision_mask = collision_mask
	query.exclude.append(source.get_rid())
	var result = space_state.intersect_ray(query)

	if result:
		global_position = result.position
		_on_body_entered(result.collider)
		return

	global_position = end_pos


func _on_body_entered(body: Node3D) -> void:
	if body == source:
		return

	_spawn_impact_marker(global_position)

	var health_component := body.get_node_or_null("HealthComponent") as HealthComponent
	if health_component:
		health_component.take_damage(damage, self)

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
