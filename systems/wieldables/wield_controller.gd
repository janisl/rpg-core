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

	wieldable.primary_action_started.connect(_on_primary_action_started)

	first_person_model = wieldable_data.first_person_scene.instantiate() as FirstPersonWieldable
	first_person_parent.add_child(first_person_model)
	first_person_model.initialize(player, wieldable, first_person_mesh_layer)
	first_person_parent.position = wieldable_data.first_person_position

	first_person_parent.reset_effects()


func _on_primary_action_started() -> void:
	first_person_parent.add_model_recoil()

	camera.add_recoil(
		wieldable_data.recoil_cam_pitch,
		wieldable_data.recoil_cam_yaw,
		wieldable_data.recoil_cam_roll)
