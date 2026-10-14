class_name Wieldable
extends Node3D

signal equip_started
signal unequip_started
signal idle_started
signal primary_action_started
signal reload_started

signal unequiped

var _item_owner: Actor
var _owner_inventory: Inventory
var _item_stack: ItemStack
var _wieldable_data: WieldableData

var _from_position := Vector3.ZERO
var _forward_direction := Vector3.ZERO
var _primary_action_pressed := false
var _primary_action_just_pressed := false
var _reload_pressed := false
var _cycle_ammo_pressed := false

var _equip_timer := 0.0
var _unequip_timer := 0.0
var _is_unequiping := false

@onready var state_chart: StateChart = $StateChart

func initialize(own: Actor, inventory: Inventory, stack: ItemStack) -> void:
	_item_owner = own
	_owner_inventory = inventory
	_item_stack = stack
	_wieldable_data = stack.item


func update(
		from_position: Vector3,
		direction: Vector3,
		primary_action_pressed: bool,
		reload_pressed := false,
		cycle_ammo_pressed := false) -> void:
	_from_position = from_position
	_forward_direction = direction
	_primary_action_just_pressed = primary_action_pressed and not _primary_action_pressed
	_primary_action_pressed = primary_action_pressed
	_reload_pressed = reload_pressed
	_cycle_ammo_pressed = cycle_ammo_pressed


func unequip() -> void:
	if _is_unequiping:
		return

	_is_unequiping = true
	state_chart.send_event("onUnequiping")


func _emit_unequiped() -> void:
	unequiped.emit()


func _on_equiping_state_entered() -> void:
	_equip_timer = _wieldable_data.equip_time
	equip_started.emit()


func _on_equiping_state_processing(delta: float) -> void:
	_equip_timer -= delta
	if _equip_timer <= 0:
		state_chart.send_event("onIdle")


func _on_unequiping_state_entered() -> void:
	_unequip_timer = _wieldable_data.unequip_time
	unequip_started.emit()


func _on_unequiping_state_processing(delta: float) -> void:
	_unequip_timer -= delta
	if _unequip_timer <= 0:
		_emit_unequiped()
