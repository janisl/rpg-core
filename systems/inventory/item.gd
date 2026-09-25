class_name Item
extends Resource

@export_group("Item")
@export var display_name := ""
@export_multiline var description := ""
@export var icon: Texture2D
@export var pickup_scene: PackedScene
@export var max_stack := 1
