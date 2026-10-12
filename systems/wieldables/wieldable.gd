class_name Wieldable
extends Node3D

var _item_owner: Actor
var _owner_inventory: Inventory
var _item_stack: ItemStack

var _from_position := Vector3.ZERO
var _forward_direction := Vector3.ZERO
var _attack_pressed := false
var _attack_just_pressed := false
var _reload_pressed := false
var _cycle_ammo_pressed := false

func initialize(own: Actor, inventory: Inventory, stack: ItemStack) -> void:
	_item_owner = own
	_owner_inventory = inventory
	_item_stack = stack


func update(
		position: Vector3,
		direction: Vector3,
		atk_pressed: bool,
		rld_pressed := false,
		cyc_pressed := false) -> void:
	_from_position = position
	_forward_direction = direction
	_attack_just_pressed = atk_pressed and not _attack_pressed
	_attack_pressed = atk_pressed
	_reload_pressed = rld_pressed
	_cycle_ammo_pressed = cyc_pressed
