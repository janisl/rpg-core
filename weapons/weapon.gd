class_name Weapon
extends Resource

@export var weapon_name := "Weapon"
@export var damage := 25.0
@export var max_ammo := 12
@export var fire_rate := 2.0
@export var is_automatic := false
@export var range := 25.0
@export_range(0, 100) var accuracy := 100
@export var projectile_speed := 50.0
@export var is_hit_scan := true
@export var weapon_scene: PackedScene
@export var projectile_scene: PackedScene
@export var pellet_count := 1
@export var spread_angle := 0.0
@export var weapon_position := Vector3.ZERO
