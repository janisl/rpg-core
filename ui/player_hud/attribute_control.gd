class_name AttributeControl
extends Control

var _attribute: BaseAttribute

@onready var name_label: Label = $NameLabel
@onready var value_label: Label = $ValueLabel


func initialize(attribute: BaseAttribute) -> void:
	_attribute = attribute
	name_label.text = tr(_attribute.display_name)
	value_label.text = str(int(_attribute.value))

	_attribute.value_changed.connect(_on_value_changed)


func _on_value_changed(new_value: float, _old_value: float, _max_value: float) -> void:
	value_label.text = str(int(new_value))
