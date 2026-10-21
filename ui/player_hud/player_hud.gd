class_name PlayerHud
extends Control

const ITEM_SLOT_CONTROL = preload("uid://d3nmme6bfak14")

@onready var hotbar_container: HBoxContainer = $HotbarBackground/HotbarContainer
@onready var selection_indicator: ColorRect = $HotbarBackground/SelectionIndicator
@onready var health_label: Label = $HealthLabel
@onready var ammo_label: Label = $AmmoLabel
@onready var interact_label: Label = $InteractLabel

var _player: Player
var _wieldable: Wieldable


func _ready() -> void:
	_player = get_tree().get_nodes_in_group("player")[0]

	for i in 9:
		var slot := ITEM_SLOT_CONTROL.instantiate() as ItemSlotControl
		hotbar_container.add_child(slot)
		slot.init(_player.inventory, i)

	Managers.weapon_manager.current_slot_changed.connect(_update_current_slot)

	_player.health_attribute.value_changed.connect(_on_health_changed)
	_player.inventory.changed.connect(_on_inventory_changed)
	_player.wield_controller.wieldable_changed.connect(_on_wieldable_changed)
	_player.interaction_controller.interactive_object_detected.connect(_on_interactive_object_detected)
	_player.interaction_controller.nothing_detected.connect(_on_nothing_detected)

	interact_label.visible = false


func _update_current_slot() -> void:
	selection_indicator.position.x = Managers.weapon_manager.current_slot * 130
	_update_ammo_label()


func _on_health_changed(new_health: float, _old_health: float, _max_halth: float) -> void:
	health_label.text = str(int(new_health))


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
