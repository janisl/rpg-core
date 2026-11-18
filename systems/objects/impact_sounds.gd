class_name ImpactSounds
extends Node3D

@export var impact_sounds: AudioStreamRandomizer
@export var next_impact_time := 0.3

@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D

var _is_delaying : bool


func _ready() -> void:
	var parent := get_parent()
	assert(parent.is_class("RigidBody3D"), "Error: " + str(parent) + " needs to be RigidBody3D.")
	parent.body_entered.connect(_on_parent_node_collision)

	if audio_stream_player_3d:
		audio_stream_player_3d.stream = impact_sounds


func _on_parent_node_collision(_collided_node: Node3D) -> void:
	var parent := get_parent()
	if parent is RigidBody3D:
		if parent.linear_velocity.length() < 0.5:
			return

	if audio_stream_player_3d and !audio_stream_player_3d.playing and !_is_delaying:
		audio_stream_player_3d.play()
		_impact_time_delay()


func _impact_time_delay() -> void:
	_is_delaying = true
	await get_tree().create_timer(next_impact_time).timeout
	_is_delaying = false
