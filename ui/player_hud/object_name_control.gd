class_name ObjectNameControl
extends PanelContainer

@onready var name_label: Label = %NameLabel


func set_object_name(object_name: String) -> void:
	name_label.text = tr(object_name)
