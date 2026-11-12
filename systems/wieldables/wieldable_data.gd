class_name WieldableData
extends ItemData

enum SecondaryAction {
	NONE,
	AIM,
	ABORT,
}

@export_group("Scenes")
@export var controller_scene: PackedScene
@export var first_person_scene: PackedScene
@export var third_person_scene: PackedScene

@export_group("Positioning and aiming")
@export var secondary_action := SecondaryAction.NONE
@export var first_person_position := Vector3.ZERO
@export var first_person_aim_position := Vector3.ZERO
@export var aim_speed := 4.0
@export var aim_fov_multilier := 1.0

@export_group("State durations")
@export var equip_time := 0.5
@export var unequip_time := 0.5

@export_group("Vertical lag")
@export var vertical_lag_amount := 0.0

@export_group("Audio")
@export var equip_sound: AudioStream
@export var unequip_sound: AudioStream
@export var idle_sound: AudioStream
