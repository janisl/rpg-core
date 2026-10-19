extends Node3D

@export var explosion_force := 15.0
@export var explosion_damage := 10.0

var _radius := 0.0


func _ready() -> void:
	_radius = $Area3D/CollisionShape3D.shape.radius
	$AnimationPlayer.play("fade_out_decal")
	$GPUParticles3D.emitting = true
	$GPUParticles3D2.emitting = true
	$AudioStreamPlayer3D.play()

	await get_tree().physics_frame
	await get_tree().physics_frame
	push_away_objects()

	var timer := get_tree().create_timer(5.0)
	timer.timeout.connect(queue_free)

func push_away_objects() -> void:
	for body: Node3D in $Area3D.get_overlapping_bodies():
		var body_pos := body.global_position
		var force_div := 1.0
		if body is CharacterBody3D:
			body_pos.y += 1.0
			force_div = 4.0
		elif body is RigidBody3D:
			force_div = maxf(0.01, body.mass)
		var force_dir := global_position.direction_to(body_pos)
		var body_dist := global_position.distance_to(body_pos)
		var factor := 1.0 - clampf((body_dist/ _radius), 0.0, 1.0)
		var explosion_vector := explosion_force * factor / force_div * force_dir
		if body is RigidBody3D:
			body.apply_impulse(explosion_vector * explosion_force)
		elif body is CharacterBody3D:
			body.velocity += explosion_vector * explosion_force

		var health_attribute := body.get_node_or_null("HealthAttribute") as HealthAttribute
		if health_attribute:
			var hit_info := HitInfo.new(explosion_damage * factor)
			hit_info.impact_position = global_position
			hit_info.direction = force_dir
			health_attribute.take_damage(hit_info)
