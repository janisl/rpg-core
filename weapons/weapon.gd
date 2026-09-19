class_name Weapon
extends Resource

@export var weapon_name := "Weapon"

@export_group("General")
@export var damage := 25.0
@export var max_ammo := 12
@export var fire_rate := 2.0
@export var is_automatic := false
@export_range(0, 100) var accuracy := 100

@export_group("Visuals")
@export var weapon_scene: PackedScene
@export var weapon_position := Vector3.ZERO

@export_group("Hit scan")
@export var is_hit_scan := true
@export var hit_scan_range := 25.0
@export var pellet_count := 1
@export var spread_angle := 0.0

@export_group("Projectile")
@export var projectile_speed := 50.0
@export var projectile_scene: PackedScene

@export_group("Recoil")
@export_range(0, 90, 0.1, "radians_as_degrees") var recoil_cam_pitch := deg_to_rad(1.0)
@export_range(0, 90, 0.1, "radians_as_degrees") var recoil_cam_yaw := deg_to_rad(0.25)
@export_range(0, 90, 0.1, "radians_as_degrees") var recoil_cam_roll := 0.0
@export var recoil_model_kickback := 0.02
@export_range(0, 90, 0.1, "radians_as_degrees") var recoil_model_rise := deg_to_rad(8.0)
