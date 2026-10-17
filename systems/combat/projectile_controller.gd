class_name ProjectileController
extends Node

@export var spawn_on_death: Array[PackedScene] = []

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

	deal_damage(body, _rigid_body.linear_velocity.normalized(), _rigid_body.global_position)
	die()


func deal_damage(body: Node3D, hit_direction: Vector3, hit_position: Vector3) -> void:
	var health_attribute := body.get_node_or_null("HealthAttribute") as HealthAttribute
	if not health_attribute:
		return

	var hit_info := HitInfo.new(_damage)
	hit_info.source = _source
	hit_info.direction = hit_direction
	hit_info.impact_position = hit_position
	health_attribute.take_damage(hit_info)


func die() -> void:
	for scene in spawn_on_death:
		if scene:
			var spawned_object = scene.instantiate()
			spawned_object.global_position = _rigid_body.global_position
			get_tree().current_scene.add_child(spawned_object)

	_rigid_body.queue_free()
