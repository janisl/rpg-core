class_name LootGenerator
extends RefCounted

var _guaranteed_drops_table: Array[LootTableEntry] = []
var _chance_drops_table: Array[LootTableEntry] = []


func generate(loot_table: LootTable) -> Array[LootTableEntry]:
	var input_array: Array[LootTableEntry] = []
	var output_array: Array[LootTableEntry] = []

	if loot_table and loot_table.amount_of_items_to_drop > 0:
		_sort_loot_table(loot_table)

		if _chance_drops_table.size() > 0:
			input_array.append_array(_chance_drops_table)

		output_array = _roll_for_randomized_items(input_array, loot_table.amount_of_items_to_drop)

		if _guaranteed_drops_table.size() > 0:
			output_array.append_array(_guaranteed_drops_table)

	return output_array


func _sort_loot_table(loot_table: LootTable) -> void:
	var loot_to_generate := loot_table.drops
	assert(loot_to_generate, "Loot table is not set up. Loot Component will not function.")
	for index in loot_to_generate:
		match index.droptype:
			LootTableEntry.DropType.GUARANTEED:
				_guaranteed_drops_table.append(index)
			LootTableEntry.DropType.CHANCE:
				_chance_drops_table.append(index)


func _roll_for_randomized_items(items: Array[LootTableEntry], amount: int) -> Array[LootTableEntry]:
	if items.is_empty():
		var empty_lootdrop_array : Array[LootTableEntry] = []
		return empty_lootdrop_array

	var inventory_items := items.map(func (k: LootTableEntry) -> LootTableEntry: return k)
	var item_weights := items.map(func (k: LootTableEntry) -> float: return k.weight)

	var rng := RandomNumberGenerator.new()
	var result: Array[LootTableEntry]
	var failsafe := 0
	while result.size() < amount:
		var _winner: LootTableEntry = inventory_items[rng.rand_weighted(item_weights)]
		result.append(_winner)

		failsafe += 1
		if failsafe > 32:
			break

	return result
