class_name WieldableData
extends ItemData

@export_group("Scenes")
@export var controller_scene: PackedScene
@export var first_person_scene: PackedScene
@export var first_person_position := Vector3.ZERO

@export_group("State durations")
@export var equip_time := 0.5
@export var unequip_time := 0.5

@export_group("Vertical lag")
@export var vertical_lag_amount := 0.0
