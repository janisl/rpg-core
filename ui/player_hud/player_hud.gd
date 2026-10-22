class_name PlayerHud
extends Control

const ITEM_SLOT_CONTROL = preload("uid://d3nmme6bfak14")
const ATTRIBUTE_CONTROL = preload("uid://dvyghe0kgmbqf")

@onready var hotbar_container: HBoxContainer = $HotbarBackground/HotbarContainer
@onready var selection_indicator: ColorRect = $HotbarBackground/SelectionIndicator
@onready var ammo_label: Label = $AmmoLabel
@onready var interact_label: Label = $InteractLabel
@onready var attributes_container: VBoxContainer = $AttributesContainer

var _player: Player
var _wieldable: Wieldable


func _ready() -> void:
	await get_tree().process_frame

	_player = get_tree().get_first_node_in_group("player")

	_update_slots()

	Managers.weapon_manager.current_slot_changed.connect(_update_current_slot)

	_player.inventory.changed.connect(_on_inventory_changed)
	_player.wield_controller.wieldable_changed.connect(_on_wieldable_changed)
	_player.interaction_controller.interactive_object_detected.connect(_on_interactive_object_detected)
	_player.interaction_controller.nothing_detected.connect(_on_nothing_detected)

	interact_label.visible = false

	for attribute in _player.player_attributes.values():
		var control := ATTRIBUTE_CONTROL.instantiate() as AttributeControl
		attributes_container.add_child(control)
		control.initialize(attribute)


func _update_current_slot() -> void:
	selection_indicator.position.x = Managers.weapon_manager.current_slot * 130
	_update_ammo_label()


func _on_inventory_changed() -> void:
	_update_slots()
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
	if Managers.weapon_manager.current_slot < 0:
		return

	var weapon := _player.inventory.slots[Managers.weapon_manager.current_slot]
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
	interact_label.text = ""
	for n: InteractionComponent in nodes:
		interact_label.text += n.input_map_action + " - " + tr(n.interaction_text) + "\n"
	interact_label.visible = true


func _on_nothing_detected() -> void:
	interact_label.visible = false


func _update_slots() -> void:
	for c in hotbar_container.get_children():
		c.queue_free()

	for i in 9:
		var slot := ITEM_SLOT_CONTROL.instantiate() as ItemSlotControl
		hotbar_container.add_child(slot)
		if i < _player.inventory.slots.size():
			slot.init(_player.inventory.slots[i])
