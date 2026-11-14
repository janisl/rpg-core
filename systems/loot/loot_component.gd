class_name LootComponent
extends Node3D

@export var enabled := true
@export var percentage_of_chance_to_spawn := 100.0
@export var loot_table: LootTable
@export var health_component_to_monitor: HealthAttribute


func _get_configuration_warnings() -> PackedStringArray:
	if !loot_table:
		return ["Loot table is not set. It is required for the loot component to function."]
	return []


func _ready() -> void:
	health_component_to_monitor.died.connect(_spawn_loot)


func _spawn_loot() -> void:
	if not enabled:
		return

	var parent_position: Vector3 = get_parent().global_position

	var lootgen := LootGenerator.new()
	var items_to_spawn := lootgen.generate(loot_table)

	for item in items_to_spawn:
		assert(item.item.pickup_scene)
		var item_to_spawn := load(item.item.pickup_scene)
		var spawned_item: DynamicObject = item_to_spawn.instantiate()
		spawned_item.position = parent_position
		get_tree().current_scene.add_child(spawned_item)

		for child in spawned_item.get_children():
			if child is PickupInteraction:
				child.item_stack.amount = randi_range(item.quantity_min, item.quantity_max)
				if child.item_stack.amount > 1:
					spawned_item.display_name = tr(child.item_stack.item.display_name) + " x" + str(child.item_stack.amount)

		var impulse := Vector3(randf_range(0,3), 5, randf_range(0,3))
		spawned_item.call_deferred("apply_central_impulse", impulse)
