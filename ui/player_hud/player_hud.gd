class_name PlayerHud
extends Control

const ITEM_SLOT_CONTROL = preload("uid://d3nmme6bfak14")
const ATTRIBUTE_CONTROL = preload("uid://dvyghe0kgmbqf")
const INTERACTION_CONTROL = preload("uid://4f6rvd4vlm08")

@onready var ammo_label: Label = $AmmoLabel
@onready var attributes_container: VBoxContainer = $AttributesContainer
@onready var water_ripple_overlay: TextureRect = $WaterRippleOverlay
@onready var interaction_container: VBoxContainer = $InteractionContainer

var _player: Player
var _wieldable: Wieldable


func connect_to_player(player: Player) -> void:
	_player = player

	_player.inventory.changed.connect(_on_inventory_changed)
	_player.wield_controller.wieldable_changed.connect(_on_wieldable_changed)
	_player.interaction_controller.interactive_object_detected.connect(_on_interactive_object_detected)
	_player.interaction_controller.nothing_detected.connect(_on_nothing_detected)
	_player.liquid_level_changed.connect(_on_liquid_level_changed)

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
	for n in interaction_container.get_children():
		n.queue_free()

	for n: InteractionComponent in nodes:
		var control := INTERACTION_CONTROL.instantiate() as InteractionControl
		interaction_container.add_child(control)
		control.initialize(n)
	interaction_container.visible = true


func _on_nothing_detected() -> void:
	interaction_container.visible = false
