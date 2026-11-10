class_name ConsumableAttributeEffect
extends ConsumableEffect

@export var attribute_type := BaseAttribute.AttributeType.NONE
@export var attribute_change_amount := 0.0
@export var value_to_change := BaseAttribute.ValueType.CURRENT


func use(target: Actor, _item_stack: ItemStack) -> bool:
	return target.increase_attribute(attribute_type, attribute_change_amount, value_to_change)
