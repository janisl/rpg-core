class_name AttentionPoint
extends DynamicObject

@onready var sprite: Sprite3D = $Sprite


func _init() -> void:
	visible = DevTools.show_attention_points
