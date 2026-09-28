class_name Item
extends Node

var item_owner: Actor
var item_stack: ItemStack


func initialize(own: Actor, stack: ItemStack) -> void:
	item_owner = own
	item_stack = stack
