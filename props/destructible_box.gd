extends StaticBody3D


func _on_health_attribute_died() -> void:
	queue_free()
