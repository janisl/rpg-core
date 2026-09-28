class_name Item
extends Node

var item_owner: Actor
var owner_inventory: Inventory
var item_stack: ItemStack


func initialize(own: Actor, inventory: Inventory, stack: ItemStack) -> void:
	item_owner = own
	owner_inventory = inventory
	item_stack = stack
