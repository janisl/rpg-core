class_name Item
extends Node

var item_owner: Actor
var owner_inventory: Inventory
var item_stack: ItemStack

var from_position := Vector3.ZERO
var forward_direction := Vector3.ZERO


func initialize(own: Actor, inventory: Inventory, stack: ItemStack) -> void:
	item_owner = own
	owner_inventory = inventory
	item_stack = stack


func update(position: Vector3, direction: Vector3) -> void:
	from_position = position
	forward_direction = direction
