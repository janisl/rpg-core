class_name Wieldable
extends Node3D

signal idle_started
signal primary_action_started
signal reload_started

var _item_owner: Actor
var _owner_inventory: Inventory
var _item_stack: ItemStack

var _from_position := Vector3.ZERO
var _forward_direction := Vector3.ZERO
var _primary_action_pressed := false
var _primary_action_just_pressed := false
var _reload_pressed := false
var _cycle_ammo_pressed := false

@onready var state_chart: StateChart = $StateChart

func initialize(own: Actor, inventory: Inventory, stack: ItemStack) -> void:
	_item_owner = own
	_owner_inventory = inventory
	_item_stack = stack


func update(
		position: Vector3,
		direction: Vector3,
		primary_action_pressed: bool,
		reload_pressed := false,
		cycle_ammo_pressed := false) -> void:
	_from_position = position
	_forward_direction = direction
	_primary_action_just_pressed = primary_action_pressed and not _primary_action_pressed
	_primary_action_pressed = primary_action_pressed
	_reload_pressed = reload_pressed
	_cycle_ammo_pressed = cycle_ammo_pressed
