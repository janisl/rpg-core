class_name HitInfo
extends RefCounted

var initial_damage := 0.0
var actual_damage := 0.0
var source: Node3D
var impact_position := Vector3.ZERO
var direction := Vector3.ZERO


func _init(amount: float) -> void:
	initial_damage = max(0.0, amount)
	actual_damage = initial_damage
