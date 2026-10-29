class_name LevelTransition
extends Area3D

@export_file("*.tscn") var target_level: String


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if !body.is_in_group("player"):
		return

	_transition_to_next_level()


func _transition_to_next_level() -> void:
	LevelManager.transition_to_level(target_level)
