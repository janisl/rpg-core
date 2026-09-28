class_name Item
extends Node

var item_owner: Actor
var owner_inventory: Inventory
var item_stack: ItemStack

var from_position := Vector3.ZERO
var forward_direction := Vector3.ZERO
var attack_pressed := false
var attack_just_pressed := false

func initialize(own: Actor, inventory: Inventory, stack: ItemStack) -> void:
	item_owner = own
	owner_inventory = inventory
	item_stack = stack


func update(
		position: Vector3,
		direction: Vector3,
		atk_pressed: bool,
		atk_just_pressed: bool) -> void:
	from_position = position
	forward_direction = direction
	attack_pressed = atk_pressed
	attack_just_pressed = atk_just_pressed
