class_name LootTableEntry extends Resource

enum DropType {
	NONE = 0,
	GUARANTEED = 1,
	CHANCE = 2,
}

@export var item: ItemData
@export var droptype := DropType.CHANCE
@export var weight := 100.0
@export var quantity_min := 0
@export var quantity_max := 1
