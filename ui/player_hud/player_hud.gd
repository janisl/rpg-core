class_name PlayerHud
extends Control

const ITEM_SLOT_CONTROL = preload("uid://d3nmme6bfak14")
const ATTRIBUTE_CONTROL = preload("uid://dvyghe0kgmbqf")
const INTERACTION_CONTROL = preload("uid://4f6rvd4vlm08")
const NOTIFICATION_ITEM = preload("uid://h8tiw6y8mxk")
const OBJECT_NAME_CONTROL = preload("uid://c4twshu73fcms")

@onready var ammo_label: Label = $AmmoLabel
@onready var attributes_container: VBoxContainer = $AttributesContainer
@onready var water_ripple_overlay: TextureRect = $WaterRippleOverlay
@onready var interaction_container: VBoxContainer = $InteractionContainer
@onready var notifications_container: VBoxContainer = $NotificationsContainer

var _player: Player
var _wieldable: Wieldable


func connect_to_player(player: Player) -> void:
	_player = player

	_player.inventory.changed.connect(_on_inventory_changed)
	_player.wield_controller.wieldable_changed.connect(_on_wieldable_changed)
	_player.interaction_controller.interactive_object_detected.connect(_on_interactive_object_detected)
	_player.interaction_controller.nothing_detected.connect(_on_nothing_detected)
	_player.carry_controller.started_carrying.connect(_set_drop_prompt)
	_player.liquid_level_changed.connect(_on_liquid_level_changed)
	EventBus.show_notification.connect(_on_show_notification)

	interaction_container.visible = false

	for c in attributes_container.get_children():
		c.queue_free()
	for attribute: BaseAttribute in _player.player_attributes.values():
		var control := ATTRIBUTE_CONTROL.instantiate() as AttributeControl
		attributes_container.add_child(control)
		control.initialize(attribute)

	visible = true


func _on_liquid_level_changed() -> void:
	water_ripple_overlay.visible = _player.liquid_level >= Actor.LiquidLevel.EYES


func _on_inventory_changed() -> void:
	_update_ammo_label()


func _on_wieldable_changed() -> void:
	if _wieldable:
		_wieldable.data_changed.disconnect(_on_wieldable_data_changed)

	_wieldable = _player.wield_controller.wieldable
	_update_ammo_label()

	if _wieldable:
		_wieldable.data_changed.connect(_on_wieldable_data_changed)


func _on_wieldable_data_changed() -> void:
	_update_ammo_label()


func _update_ammo_label() -> void:
	var weapon := _player.wield_controller.current_item_stack
	if not weapon or weapon.item is not WeaponData:
		ammo_label.visible = false
		return

	ammo_label.visible = true
	var weapon_data := weapon.item as WeaponData
	if weapon_data.ammo_types.is_empty():
		ammo_label.visible = false
		return

	var magazine: int = weapon.metadata.get(Weapon.MAGAZINE_KEY, 0)
	var index: int = weapon.metadata.get(Weapon.SELECTED_AMMO_KEY, 0)
	var selected := weapon_data.ammo_types[index]
	var reserve := _player.inventory.get_available_amount(selected)
	ammo_label.text = tr("%d / %d %s") % [magazine, reserve, tr(selected.display_name)]


func _on_interactive_object_detected(nodes: Array[Node]) -> void:
	_clear_interaction_prompts()

	if nodes.size() < 1:
		return

	var interactive_object := nodes[0].get_parent()
	var display_name: String = interactive_object.display_name
	if display_name:
		var instanced_object_name : ObjectNameControl = OBJECT_NAME_CONTROL.instantiate()
		interaction_container.add_child(instanced_object_name)
		instanced_object_name.set_object_name(display_name)

	for node: InteractionComponent in nodes:
		if node.is_disabled:
			continue
		var control := INTERACTION_CONTROL.instantiate() as InteractionControl
		interaction_container.add_child(control)
		control.initialize(node)

	interaction_container.visible = true


func _on_nothing_detected() -> void:
	_clear_interaction_prompts()
	interaction_container.visible = false


func _set_drop_prompt(carrying_node: CarryInteraction) -> void:
	_clear_interaction_prompts()

	var carry_parent := carrying_node.get_parent()
	if carry_parent:
		for node: InteractionComponent in carry_parent.find_children("", "InteractionComponent", true):
			if node.is_disabled:
				continue
			if node is PickupInteraction:
				var take_prompt := INTERACTION_CONTROL.instantiate() as InteractionControl
				interaction_container.add_child(take_prompt)
				take_prompt.set_prompt(node.interaction_text, node.input_map_action)

	var drop_prompt := INTERACTION_CONTROL.instantiate() as InteractionControl
	interaction_container.add_child(drop_prompt)
	drop_prompt.set_prompt("INTERACT Drop", carrying_node.input_map_action)

	var throw_prompt := INTERACTION_CONTROL.instantiate() as InteractionControl
	interaction_container.add_child(throw_prompt)
	throw_prompt.set_prompt("INTERACT Throw", "primary_action")

	if carrying_node.enable_manual_rotating:
		var rotate_prompt := INTERACTION_CONTROL.instantiate() as InteractionControl
		interaction_container.add_child(rotate_prompt)
		rotate_prompt.set_prompt("INTERACT Rotate", "secondary_action")


func _clear_interaction_prompts() -> void:
	for n in interaction_container.get_children():
		n.queue_free()


func _on_show_notification(text: String) -> void:
	var item := NOTIFICATION_ITEM.instantiate()
	notifications_container.add_child(item)
	item.text = text
