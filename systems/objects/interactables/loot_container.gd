@tool
class_name LootContainer
extends InteractableContainer

@export_category("Loot Table Configuration")
@export var loot_table: LootTable


func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		return

	_handle_inventory.call_deferred()


func _handle_inventory() -> void:
	var lootgen := LootGenerator.new()
	var finalized_items := lootgen.generate(loot_table)
	_populate_the_container(finalized_items)


func _populate_the_container(_items: Array[LootTableEntry]) -> void:
	inventory.clear()
	for item in _items:
		var amount := randi_range(item.quantity_min, item.quantity_max)
		inventory.add_item(item.item, amount)
