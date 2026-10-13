class_name FirstPersonWieldable
extends Node3D

const WIELDABLE_CLIP_AND_FOV_SHADER = preload("uid://dn5emhygjupes")

@export var animation_player: AnimationPlayer
@export var muzzle_flash: MuzzleFlash

var _player: Player
var _wieldable: Wieldable


func initialize(player: Player, wieldable: Wieldable, mesh_layer: int) -> void:
	_player = player
	_wieldable = wieldable

	_apply_clip_and_fov_shader_to_view_model(mesh_layer)
	_connect_signals()


func _apply_clip_and_fov_shader_to_view_model(mesh_layer: int, fov_or_negative_for_unchanged = -1.0) -> void:
	var all_mesh_instances := find_children("*", "MeshInstance3D")
	for mesh_instance in all_mesh_instances:
		var mesh = mesh_instance.mesh

		mesh_instance.layers = mesh_layer
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

		for surface_idx in mesh.get_surface_count():
			var base_mat = mesh.surface_get_material(surface_idx)
			if not base_mat is BaseMaterial3D:
				continue

			var weapon_shader_material := ShaderMaterial.new()
			weapon_shader_material.shader = WIELDABLE_CLIP_AND_FOV_SHADER
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


func _connect_signals() -> void:
	_wieldable.idle_started.connect(_on_idle_started)
	_wieldable.primary_action_started.connect(_on_primary_action_started)
	_wieldable.reload_started.connect(_on_reload_started)


func _on_idle_started() -> void:
	if animation_player:
		animation_player.play("idle")


func _on_primary_action_started() -> void:
	if animation_player:
		animation_player.play("fire")

	if muzzle_flash:
		muzzle_flash.flash()


func _on_reload_started() -> void:
	if animation_player:
		animation_player.play("reload")
