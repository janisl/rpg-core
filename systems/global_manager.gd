extends Node

signal camera_underwater_effect_changed()

var camera_underwater_effect := false:
	set(value):
		if camera_underwater_effect == value:
			return
		camera_underwater_effect = value
		camera_underwater_effect_changed.emit()
