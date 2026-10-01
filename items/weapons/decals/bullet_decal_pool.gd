class_name BulletDecalPool

const BULLET_DECAL = preload("uid://bdrf1d353xxqq")

const MAX_BULLET_DECALS := 100

static var decal_pool: Array


static func spawn_bullet_decal(position: Vector3, normal: Vector3, parent: Node3D, bullet_basis: Basis, texture_override = null) -> void:
	var decal_instance: Decal
	if decal_pool.size() >= MAX_BULLET_DECALS and is_instance_valid(decal_pool[0]):
		decal_instance = decal_pool.pop_front()
		decal_instance.reparent(parent)
	else:
		decal_instance = BULLET_DECAL.instantiate()
		parent.add_child(decal_instance)

	decal_pool.push_back(decal_instance)

	if not is_instance_valid(decal_pool[0]):
		decal_pool.pop_front()

	decal_instance.global_transform = Transform3D(bullet_basis, position) * Transform3D(Basis().rotated(Vector3.RIGHT, PI * 0.5), Vector3.ZERO)
	decal_instance.global_basis = Basis(Quaternion(decal_instance.global_basis.y, normal)) * decal_instance.global_basis
	decal_instance.get_node("Particles").emitting = true

	if texture_override is Texture2D:
		decal_instance.texture_albedo = texture_override
