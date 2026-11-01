class_name InteractableDoor
extends DynamicObject

@export_group("Door Settings")
@export var is_open := false
@export var ignore_interaction_raycast := false

@export_group("Door Parameters")
@export var open_position: Vector3
@export var closed_position: Vector3
@export var door_speed := 1.0


func _ready() -> void:
	super()
	if !ignore_interaction_raycast:
		add_to_group("interactable")


func interact(player: Player) -> void:
	if !is_open:
		open_door(player)
	else:
		close_door()


func open_door(player: Player) -> void:
	var tween_door := get_tree().create_tween()
	tween_door.tween_property(self, "position", open_position, door_speed)

	is_open = true


func close_door() -> void:
	var tween_door := get_tree().create_tween()
	tween_door.tween_property(self,"position", closed_position, door_speed)

	is_open = false
