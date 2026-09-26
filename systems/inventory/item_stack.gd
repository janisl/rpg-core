class_name ItemStack
extends Resource

@export var item: Item
@export var amount := 1
@export var metadata: Dictionary[String, Variant]

var is_valid: bool:
	get:
		return is_instance_valid(item) and amount > 0


func _init(_item: Item = null, _amount := 1, _metadata: Dictionary[String, Variant] = {}) -> void:
	item = _item
	amount = _amount
	metadata = _metadata.duplicate_deep()
