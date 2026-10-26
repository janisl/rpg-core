extends Area3D


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") :
		body.increase_attribute("visibility", 1, BaseAttribute.ValueType.CURRENT)


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player") :
		body.decrease_attribute("visibility", 1)
