class_name WieldController
extends Node3D

signal wieldable_changed

@export_group("References")
@export var player: Player
@export var camera: CameraEffects
@export var first_person_parent: WieldableEffects
@export var third_person_parent: Node3D

@export_group("Mesh layers")
@export_flags_3d_render var first_person_mesh_layer := 1
@export_flags_3d_render var third_person_mesh_layer := 1

var is_wielding: bool:
	get: return wieldable_data != null

var current_item_stack: ItemStack
var wieldable_data: WieldableData
var wieldable: Wieldable
var first_person_model: FirstPersonWieldable
var third_person_model: ThirdPersonWieldable
var is_changing_wieldables := false

var _selected_item_stack: ItemStack
var _item_to_auto_equip: ItemStack
var _auto_equip_after_carrying := false


func _ready() -> void:
	add_to_group("persist_component")


func _physics_process(_delta: float) -> void:
	if wieldable:
		wieldable.update(
				camera.global_position,
				-camera.global_transform.basis.z,
				player.input_controller.primary_action_pressed,
				player.input_controller.secondary_action_pressed,
				player.input_controller.reload_just_pressed,
				player.input_controller.cycle_ammo_just_pressed)


func save_state() -> Dictionary:
	var state := Dictionary()
	if current_item_stack:
		state[&"wielded_item"] = player.inventory.slots.find(current_item_stack)
	if wieldable:
		state[&"wieldable"] = wieldable.save_state()
	if first_person_model:
		state[&"first_person_model"] = first_person_model.save_state()
	if third_person_model:
		state[&"third_person_model"] = third_person_model.save_state()
	if _item_to_auto_equip:
		state[&"item_to_auto_equip"] = player.inventory.slots.find(_item_to_auto_equip)
	state[&"_auto_equip_after_carrying"] = _auto_equip_after_carrying
	return state


func load_state(state: Dictionary) -> void:
	var index := state.get(&"wielded_item", -1) as int
	if index >= 0 and index < player.inventory.slots.size():
		_selected_item_stack = player.inventory.slots[index]
		_spawn_wieldable_scenes()
		_selected_item_stack = null
	if wieldable:
		wieldable.load_state(state.get(&"wieldable", Dictionary()))
	if first_person_model:
		first_person_model.load_state(state.get(&"first_person_model", Dictionary()))
	if third_person_model:
		third_person_model.load_state(state.get(&"third_person_model", Dictionary()))
	var auto_index := state.get(&"item_to_auto_equip", -1) as int
	if auto_index >= 0 and auto_index < player.inventory.slots.size():
		_item_to_auto_equip = player.inventory.slots[auto_index]
	_auto_equip_after_carrying = state.get(&"_auto_equip_after_carrying", false)


func switch_wieldable(item_stack: ItemStack) -> void:
	if wieldable and not wieldable.is_unequipping and item_stack == current_item_stack:
		return

	if player.carry_controller.carried_object and not player.carry_controller.carried_object.is_carryable_while_wielding:
		if !is_wielding:
			setup_wieldable_to_auto_equip(item_stack)
			player.carry_controller.drop_carried_object()
		return

	_switch_to(item_stack)


func setup_wieldable_to_auto_equip(next_item: ItemStack = null) -> void:
	if wieldable:
		_item_to_auto_equip = current_item_stack
	elif next_item:
		_item_to_auto_equip = next_item
	else:
		return

	_switch_to(null)
	_auto_equip_after_carrying = true


func auto_equip_last_wieldable() -> void:
	if not _auto_equip_after_carrying or not _item_to_auto_equip:
		return

	switch_wieldable(_item_to_auto_equip)
	_auto_equip_after_carrying = false


func _switch_to(item_stack: ItemStack) -> void:
	is_changing_wieldables = true
	_selected_item_stack = item_stack

	if wieldable != null:
		wieldable.unequip()
		return

	_spawn_wieldable_scenes()


func _spawn_wieldable_scenes() -> void:
	if first_person_model:
		first_person_model.queue_free()
		first_person_model = null
	if third_person_model:
		third_person_model.queue_free()
		third_person_model = null
	if wieldable:
		wieldable.queue_free()
		wieldable = null
	wieldable_data = null

	current_item_stack = _selected_item_stack
	if not current_item_stack or not current_item_stack.is_valid:
		current_item_stack = null
		wieldable_changed.emit()
		is_changing_wieldables = false
		return

	wieldable_data = current_item_stack.item as WieldableData
	if not wieldable_data:
		current_item_stack = null
		wieldable_changed.emit()
		is_changing_wieldables = false
		return

	assert(wieldable_data.controller_scene, "Wieldable has no controller scene")
	assert(wieldable_data.first_person_scene, "Wieldable has no first person scene")
	assert(wieldable_data.third_person_scene, "Wieldable has no third person scene")

	wieldable = wieldable_data.controller_scene.instantiate() as Wieldable
	add_child(wieldable)
	wieldable.initialize(player, player.inventory, current_item_stack)

	wieldable.primary_action_started.connect(_on_primary_action_started)
	wieldable.unequipped.connect(_on_unequipped)

	first_person_model = wieldable_data.first_person_scene.instantiate() as FirstPersonWieldable
	first_person_parent.add_child(first_person_model)
	first_person_model.initialize(player, wieldable, first_person_mesh_layer)

	third_person_model = wieldable_data.third_person_scene.instantiate() as ThirdPersonWieldable
	third_person_parent.add_child(third_person_model)
	third_person_model.initialize(wieldable, third_person_mesh_layer)

	first_person_parent.reset_effects()

	wieldable_changed.emit()
	is_changing_wieldables = false


func _on_primary_action_started() -> void:
	first_person_parent.add_model_recoil()

	camera.add_recoil(
		wieldable_data.recoil_cam_pitch,
		wieldable_data.recoil_cam_yaw,
		wieldable_data.recoil_cam_roll)


func _on_unequipped() -> void:
	_spawn_wieldable_scenes()
