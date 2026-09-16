class_name LadderArea
extends Area3D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if body is Actor:
		body.on_ladder_area_entered(self)


func _on_body_exited(body: Node3D) -> void:
	if body is Actor:
		body.on_ladder_area_exited(self)
