class_name ItemData
extends Resource

@export_group("Item")
@export var display_name := ""
@export_multiline var description := ""
@export var icon: Texture2D
@export var max_stack := 1

@export_file_path("*.tscn") var pickup_scene: String
