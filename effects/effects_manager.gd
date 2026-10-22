extends Node

const MAX_DECALS := 100

var decal_pool: Array


func spawn_decal(decal_scene: PackedScene, position: Vector3, normal: Vector3, parent: Node3D, bullet_basis: Basis) -> void:
	if not decal_scene:
		return

	if decal_pool.size() >= MAX_DECALS:
		decal_pool.pop_front().queue_free()

	var decal_instance : Decal = decal_scene.instantiate()
	parent.add_child(decal_instance)

	decal_pool.push_back(decal_instance)

	decal_instance.global_transform = Transform3D(bullet_basis, position) * Transform3D(Basis().rotated(Vector3.RIGHT, PI * 0.5), Vector3.ZERO)
	decal_instance.global_basis = Basis(Quaternion(decal_instance.global_basis.y, normal)) * decal_instance.global_basis


func spawn_light_flash(position: Vector3, color: Color, energy: float, duration: float) -> void:
	if not duration:
		return

	var light = OmniLight3D.new()
	get_tree().current_scene.add_child(light)
	light.global_position = position
	light.light_color = color
	light.light_energy = energy

	var tween = create_tween()
	tween.tween_property(light, "light_energy", 0.0, duration)

	await tween.finished

	light.queue_free()
