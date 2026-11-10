class_name AttributeControl
extends Control

var _attribute: BaseAttribute

@onready var name_label: Label = $NameLabel
@onready var value_label: Label = $ValueLabel


func initialize(attribute: BaseAttribute) -> void:
	_attribute = attribute
	name_label.text = tr(_attribute.display_name)
	_update_value()

	_attribute.value_changed.connect(_on_value_changed)


func _on_value_changed(_new_value: float, _old_value: float, _max_value: float) -> void:
	_update_value()


func _update_value() -> void:
	if _attribute.is_unlimited:
		value_label.text = str(int(_attribute.value))
	else:
		value_label.text = str(int(_attribute.value)) + "/" + str(int(_attribute.max_value))
