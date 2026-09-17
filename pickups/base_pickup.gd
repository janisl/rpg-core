class_name BasePickup
extends Area3D

@export var rotation_speed := 60.0
@export var float_height := 0.1
@export var float_speed := 2.0

var start_y := 0.0
var time := 0.0


func _ready() -> void:
	body_entered.connect(_on_pickup)
	start_y = position.y


func _process(delta: float) -> void:
	time += delta
	if float_speed and float_height:
		position.y = start_y + sin(time * float_speed) * float_height
	if rotation_speed:
		rotate_y(deg_to_rad(rotation_speed) * delta)


func _on_pickup(body: Node3D) -> void:
	if not body is Player:
		return

	if _can_pickup(body):
		_apply_pickup(body)
		queue_free()


func _can_pickup(player: Player) -> bool:
	return true;


func _apply_pickup(player: Player) -> void:
	pass
