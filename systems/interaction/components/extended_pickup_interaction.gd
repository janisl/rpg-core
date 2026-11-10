class_name ExtendedPickupInteraction
extends HoldInteraction

@export var hold_interaction_text: String
@export var separator_text: String

var _pickup: PickupInteraction


func _ready() -> void:
	super()

	_pickup = get_parent().get_node_or_null("PickupInteraction") as PickupInteraction
	if !_pickup or _pickup is not PickupInteraction or !_pickup.item_stack or !_pickup.item_stack.item:
		assert(false, "ExtendedPickupInteraction can't find a pickup component")
		is_disabled = true
		return

	interaction_text = tr(_pickup.interaction_text) + tr(separator_text) + tr(hold_interaction_text)

	_pickup.is_disabled = true


func update_disabled_state(player: Player) -> void:
	if !_pickup:
		is_disabled = true
		return

	var item := _pickup.item_stack.item
	if item is ConsumableItem:
		var consumable := item as ConsumableItem
		if player.player_attributes.has(consumable.consumable_effects[0].attribute_type):
			var attribute := player.player_attributes[consumable.consumable_effects[0].attribute_type] as BaseAttribute
			if consumable.consumable_effects[0].value_to_change == BaseAttribute.ValueType.CURRENT:
				is_disabled = not attribute.is_unlimited and attribute.value == attribute.max_value
			elif consumable.consumable_effects[0].value_to_change == BaseAttribute.ValueType.MAX:
				is_disabled = false
	elif item is WieldableData:
		is_disabled = player.carry_controller.is_carrying

	_pickup.is_disabled = !is_disabled


func _on_object_state_change(_interaction_text: String) -> void:
	pass


func _hold_released() -> void:
	_pickup.interact(_player)


func _complete() -> void:
	if _pickup.item_stack.item is ConsumableItem:
		_consume(_player, _pickup.item_stack)
	elif _pickup.item_stack.item is WieldableData:
		_attempt_wield(_player, _pickup.item_stack)


func _consume(player: Player, item_stack: ItemStack) -> void:
	if not item_stack.item.use(player, item_stack):
		return
	was_interacted_with.emit()
	AudioManager.play_sound_3d(item_stack.item.pickup_sound, get_parent().global_position)
	get_parent().queue_free()


func _attempt_wield(player: Player, item_stack: ItemStack) -> void:
	if player.wield_controller.is_changing_wieldables:
		return

	var new_stack := player.inventory.add_stack(item_stack)
	player.wield_controller.switch_wieldable(new_stack)
	was_interacted_with.emit()
	AudioManager.play_sound_3d(item_stack.item.pickup_sound, get_parent().global_position)
	get_parent().queue_free()
