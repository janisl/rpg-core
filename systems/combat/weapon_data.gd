class_name WeaponData
extends WieldableData

@export_group("General settings")
@export var weapon_range := 0.0
@export var damage := 0.0
@export_range(0, 100) var accuracy := 100
@export var fire_offset := Vector3(0.1, -0.05, -0.1)
@export var fire_rate := 2.0
@export var is_automatic := false

@export_group("Ammo & reload")
@export var ammo_types: Array[AmmoData]
@export var magazine_size := 1
@export var reload_time := 1.5

@export_group("Hit scan")
@export var pellet_count := 1
@export var spread_angle := 0.0
@export var bullet_tracer_chance := 0.5
@export var decal_scene: PackedScene
@export var impact_scene: PackedScene

@export_group("Projectile")
@export var projectile_speed := 50.0
@export var projectile_scene: PackedScene

@export_group("Recoil")
@export_range(0, 90, 0.1, "radians_as_degrees") var recoil_cam_pitch := deg_to_rad(1.0)
@export_range(0, 90, 0.1, "radians_as_degrees") var recoil_cam_yaw := deg_to_rad(0.25)
@export_range(0, 90, 0.1, "radians_as_degrees") var recoil_cam_roll := 0.0
@export var recoil_model_kickback := 0.02
@export_range(0, 90, 0.1, "radians_as_degrees") var recoil_model_rise := deg_to_rad(8.0)
