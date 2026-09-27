class_name ItemData
extends Resource

@export_group("Item")
@export var display_name := ""
@export_multiline var description := ""
@export var icon: Texture2D
@export var max_stack := 1

@export_group("Scenes")
@export var item_scene: PackedScene
@export var pickup_scene: PackedScene
