class_name WieldController
extends Node3D

@export_group("References")
@export var player: Player
@export var camera: CameraEffects
@export var first_person_parent: WieldableEffects

@export_group("Mesh layers")
@export_flags_3d_render var first_person_mesh_layer := 1

var current_item_stack: ItemStack
var wieldable_data: WieldableData
var wieldable: Wieldable
var first_person_model: FirstPersonWieldable


func _process(_delta: float) -> void:
	if wieldable:
		wieldable.update(
				camera.global_position,
				-camera.global_transform.basis.z,
				Input.is_action_pressed("primary_fire"),
				Input.is_action_just_pressed("reload"),
				Input.is_action_just_pressed("cycle_ammo"))


func switch_wieldable(item_stack: ItemStack) -> void:
	current_item_stack = item_stack
	wieldable_data = item_stack.item as WieldableData if item_stack else null
	_spawn_wieldable_scenes()


func _spawn_wieldable_scenes() -> void:
	if first_person_model:
		first_person_model.queue_free()
		first_person_model = null
	if wieldable:
		wieldable.queue_free()
		wieldable = null

	if not wieldable_data:
		return

	assert(wieldable_data.controller_scene, "Wieldable has no controller scene")
	assert(wieldable_data.first_person_scene, "Wieldable has no first person scene")

	wieldable = wieldable_data.controller_scene.instantiate() as Wieldable
	add_child(wieldable)
	wieldable.initialize(player, player.inventory, current_item_stack)

	wieldable.weapon_fired.connect(_on_weapon_fired)

	first_person_model = wieldable_data.first_person_scene.instantiate() as FirstPersonWieldable
	first_person_parent.add_child(first_person_model)
	first_person_model.initialize(player, wieldable)
	first_person_parent.position = wieldable_data.first_person_position

	_apply_clip_and_fov_shader_to_view_model(first_person_model, first_person_mesh_layer)

	first_person_parent.reset_effects()


func _on_weapon_fired() -> void:
	first_person_parent.add_model_recoil()

	camera.add_recoil(
		wieldable_data.recoil_cam_pitch,
		wieldable_data.recoil_cam_yaw,
		wieldable_data.recoil_cam_roll)


func _apply_clip_and_fov_shader_to_view_model(node3d: Node3D, mesh_layer: int, fov_or_negative_for_unchanged = -1.0) -> void:
	var all_mesh_instances := node3d.find_children("*", "MeshInstance3D")
	if node3d is MeshInstance3D:
		all_mesh_instances.push_back(node3d)

	for mesh_instance in all_mesh_instances:
		var mesh = mesh_instance.mesh

		mesh_instance.layers = mesh_layer
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
