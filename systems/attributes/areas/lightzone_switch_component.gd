extends Node

@export var switchable: bool = true

func _on_switched(is_on: bool) -> void:
	if switchable:
		var lightzone: Area3D = get_parent()
		if lightzone:
			lightzone.set_monitoring(is_on)
