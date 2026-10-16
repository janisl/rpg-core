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

var _selected_item_stack: ItemStack


func _process(_delta: float) -> void:
	if wieldable:
		wieldable.update(
				camera.global_position,
				-camera.global_transform.basis.z,
				Input.is_action_pressed("primary_fire"),
				Input.is_action_just_pressed("reload"),
				Input.is_action_just_pressed("cycle_ammo"))


func switch_wieldable(item_stack: ItemStack) -> void:
	if wieldable and not wieldable.is_unequipping and item_stack == current_item_stack:
		return

	_selected_item_stack = item_stack

	if wieldable != null:
		wieldable.unequip()
		return

	_spawn_wieldable_scenes()


func _spawn_wieldable_scenes() -> void:
	if first_person_model:
		first_person_model.queue_free()
		first_person_model = null
	if wieldable:
		wieldable.queue_free()
		wieldable = null
	wieldable_data = null

	current_item_stack = _selected_item_stack
	if not current_item_stack or not current_item_stack.is_valid:
		current_item_stack = null
		return

	wieldable_data = current_item_stack.item as WieldableData
	if not wieldable_data:
		current_item_stack = null
		return

	assert(wieldable_data.controller_scene, "Wieldable has no controller scene")
	assert(wieldable_data.first_person_scene, "Wieldable has no first person scene")

	wieldable = wieldable_data.controller_scene.instantiate() as Wieldable
	add_child(wieldable)
	wieldable.initialize(player, player.inventory, current_item_stack)

	wieldable.primary_action_started.connect(_on_primary_action_started)
	wieldable.unequipped.connect(_on_unequipped)

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


func _on_unequipped() -> void:
	_spawn_wieldable_scenes()
