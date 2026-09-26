class_name PlayerHud
extends Control

const ITEM_SLOT_CONTROL = preload("uid://d3nmme6bfak14")

@onready var hotbar_container: HBoxContainer = $HotbarBackground/HotbarContainer
@onready var selection_indicator: ColorRect = $HotbarBackground/SelectionIndicator
@onready var health_label: Label = $HealthLabel
@onready var ammo_label: Label = $AmmoLabel

var _player: Player


func _ready() -> void:
	_player = get_tree().get_nodes_in_group("player")[0]

	for i in 9:
		var slot := ITEM_SLOT_CONTROL.instantiate() as ItemSlotControl
		hotbar_container.add_child(slot)
		slot.init(_player.inventory, i)

	Managers.weapon_manager.current_slot_changed.connect(_update_current_slot)

	_player.health_component.health_changed.connect(_on_health_changed)
	_player.inventory.changed.connect(_on_inventory_changed)


func _update_current_slot() -> void:
	selection_indicator.position.x = Managers.weapon_manager.current_slot * 130
	_update_ammo_label()


func _on_health_changed(new_health: float, _max_halth: float) -> void:
	health_label.text = str(int(new_health))


func _on_inventory_changed() -> void:
	_update_ammo_label()


func _update_ammo_label() -> void:
	var weapon := _player.inventory.slots[Managers.weapon_manager.current_slot]
	if not weapon or weapon.item is not Weapon:
		ammo_label.visible = false
		return

	ammo_label.visible = true
	ammo_label.text = str(_player.inventory.get_available_amount(weapon.item.ammo_type))
