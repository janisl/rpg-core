class_name AttentionPoint
extends Sprite3D


func _init(sprite_texture: Texture2D, visible_to_player: bool) -> void:
	modulate = Color(1, 0, 0, 1 if visible_to_player else 0)
	texture = sprite_texture
	billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
