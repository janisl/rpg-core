class_name WeaponController
extends Node3D

@export_group("References")
@export var player: Player
@export var camera: CameraEffects
@export var weapon_model_parent: WieldableEffects

@export_group("Weapon controller params")
@export_flags_3d_render var weapon_mesh_layer := 1

var current_weapon_data: WieldableData
var current_weapon_model: FirstPersonWieldable
var current_item_stack: ItemStack
var current_weapon: Wieldable


func _process(delta: float) -> void:
	if current_weapon:
		current_weapon.update(
				camera.global_position,
				-camera.global_transform.basis.z,
				Input.is_action_pressed("primary_fire"),
				Input.is_action_just_pressed("reload"),
				Input.is_action_just_pressed("cycle_ammo"))


func switch_weapon(item_stack: ItemStack) -> void:
	current_item_stack = item_stack
	current_weapon_data = item_stack.item as WieldableData if item_stack else null
	_spawn_weapon_model()


func _spawn_weapon_model() -> void:
	if current_weapon_model:
		current_weapon_model.queue_free()
		current_weapon_model = null
	if current_weapon:
		current_weapon.queue_free()
		current_weapon = null

	if not current_weapon_data:
		return

	assert(current_weapon_data.controller_scene, "Wieldable has no controller scene")
	assert(current_weapon_data.first_person_scene, "Wieldable has no first person scene")

	current_weapon = current_weapon_data.controller_scene.instantiate() as Wieldable
	add_child(current_weapon)
	current_weapon.initialize(player, player.inventory, current_item_stack)

	current_weapon.weapon_fired.connect(_on_weapon_fired)

	current_weapon_model = current_weapon_data.first_person_scene.instantiate() as FirstPersonWieldable
	weapon_model_parent.add_child(current_weapon_model)
	current_weapon_model.initialize(player, current_weapon)
	weapon_model_parent.position = current_weapon_data.first_person_position

	_apply_clip_and_fov_shader_to_view_model(current_weapon_model)

	weapon_model_parent.reset_effects()


func _on_weapon_fired() -> void:
	weapon_model_parent.add_model_recoil()

	camera.add_recoil(
		current_weapon_data.recoil_cam_pitch,
		current_weapon_data.recoil_cam_yaw,
		current_weapon_data.recoil_cam_roll)


func _apply_clip_and_fov_shader_to_view_model(node3d : Node3D, fov_or_negative_for_unchanged = -1.0) -> void:
	var all_mesh_instances := node3d.find_children("*", "MeshInstance3D")
	if node3d is MeshInstance3D:
		all_mesh_instances.push_back(node3d)

	for mesh_instance in all_mesh_instances:
		var mesh = mesh_instance.mesh

		mesh_instance.layers = weapon_mesh_layer
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

		for surface_idx in mesh.get_surface_count():
			var base_mat = mesh.surface_get_material(surface_idx)
			if not base_mat is BaseMaterial3D:
				continue

			var weapon_shader_material := ShaderMaterial.new()
			weapon_shader_material.shader = preload("res://shaders/weapon_clip_and_fov_shader.gdshader")
			weapon_shader_material.set_shader_parameter("texture_albedo", base_mat.albedo_texture)
			weapon_shader_material.set_shader_parameter("texture_metallic", base_mat.metallic_texture)
			weapon_shader_material.set_shader_parameter("texture_roughness", base_mat.roughness_texture)
			weapon_shader_material.set_shader_parameter("texture_normal", base_mat.normal_texture)
			weapon_shader_material.set_shader_parameter("albedo", base_mat.albedo_color)
			weapon_shader_material.set_shader_parameter("metallic", base_mat.metallic)
			weapon_shader_material.set_shader_parameter("specular", base_mat.metallic_specular)
			weapon_shader_material.set_shader_parameter("roughness", base_mat.roughness)
			weapon_shader_material.set_shader_parameter("viewmodel_fov", fov_or_negative_for_unchanged)
			var tex_channels = { 0: Vector4(1., 0., 0., 0.), 1: Vector4(0., 1., 0., 0.), 2: Vector4(0., 0., 1., 0.), 3: Vector4(1., 0., 0., 1.), 4: Vector4() }
			weapon_shader_material.set_shader_parameter("metallic_texture_channel", tex_channels[base_mat.metallic_texture_channel])
			mesh.surface_set_material(surface_idx, weapon_shader_material)
