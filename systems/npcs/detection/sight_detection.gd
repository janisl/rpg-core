class_name SightDetection
extends Node3D

@export var detection_area: Area3D
@export var npc: Npc

var _nodes_inside_detection_area: Array[Node3D] = []


func _ready() -> void:
	_connect_detection_signals()


func _physics_process(_delta: float) -> void:
	if _nodes_inside_detection_area.size():
		npc.on_triggered()


func _connect_detection_signals():
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D):
	if body.is_in_group("player"):
		_nodes_inside_detection_area.append(body)


func _on_body_exited(body: Node3D):
	_nodes_inside_detection_area.erase(body)
