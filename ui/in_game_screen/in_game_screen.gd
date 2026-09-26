class_name InGameScreen
extends Control

const ITEM_SLOT_CONTROL = preload("uid://d3nmme6bfak14")

@onready var slots_container: FlowContainer = $ColorRect/SlotsContainer

var _player: Player


func _ready() -> void:
	_player = get_tree().get_nodes_in_group("player")[0]


func show_screen() -> void:
	visible = true
	_recreate_slots()


func hide_screen() -> void:
	visible = false
	_clear()


func _clear() -> void:
	for c in slots_container.get_children():
		c.queue_free()


func _recreate_slots() -> void:
	_clear()
	for i in _player.inventory.slots.size():
		var slot := ITEM_SLOT_CONTROL.instantiate() as ItemSlotControl
		slots_container.add_child(slot)
		slot.init(_player.inventory, i)
