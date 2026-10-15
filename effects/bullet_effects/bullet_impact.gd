class_name BulletImpact
extends GPUParticles3D


func _ready() -> void:
	emitting = true

	await get_tree().create_timer(1).timeout

	queue_free()
