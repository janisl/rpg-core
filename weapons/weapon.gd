class_name Weapon
extends Resource

@export var weapon_name := "Weapon"
@export var damage := 25.0
@export var max_amo := 12
@export var range := 25.0
@export var projectile_speed := 50.0
@export var is_hit_scan := true
@export var weapon_scene: PackedScene
@export var projectile_scene: PackedScene
@export var weapon_position := Vector3.ZERO
