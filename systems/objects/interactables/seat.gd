@warning_ignore("missing_tool")
class_name Seat
extends DynamicObject

enum PlacementOnLeave {
	ORIGINAL,
	DISPLACEMENT,
	TRANSFORM,
	AUTO,
}

signal object_state_updated(interaction_text: String)

@export_group("Sittable Behaviour")
@export var placement_on_leave := PlacementOnLeave.ORIGINAL
@export var eject_on_fall := false
@export_range(0, 180, 0.1, "radians_as_degrees") var eject_angle := PI / 4.0

@export_group("Vision")
@export var sit_marker_displacement := 0.9
@export_range(0, 180, 0.1, "radians_as_degrees") var horizontal_look_angle := deg_to_rad(120)
@export_range(0, 180, 0.1, "radians_as_degrees") var vertical_look_angle := PI / 2.0

@export_group("Animation")
@export var tween_duration := 0.8
@export var rotation_tween_duration := 0.4
@export var animation_on_enter: String
@export var animation_on_leave: String

@export_group("Audio")
@export var audio_stream_player_3d: AudioStreamPlayer3D
@export var sit_sound: AudioStream
@export var stand_sound: AudioStream
@export var sit_pitch := 1.0
@export var stand_pitch := 1.0

@export_group("Nodes")
@export var sit_position_node_path: NodePath
@export var look_marker_node_path: NodePath
@export var leave_node_path: NodePath
@export var animation_player_node_path: NodePath

@export_group("Interaction")
@export var interaction_text_when_on := "INTERACT Stand Up"
@export var interaction_text_when_off := "INTERACT Sit"

var sit_position_node: Node3D
var look_marker_node: Node3D
var animation_player: AnimationPlayer


func _ready() -> void:
	super()

	if !audio_stream_player_3d:
		var players := find_children("", "AudioStreamPlayer3D")
		if len(players) > 0:
			audio_stream_player_3d = players[0]

	sit_position_node = get_node_or_null(sit_position_node_path)
	assert(sit_position_node, "Sit position node not found. Ensure the path is correct.")
	_displace_sit_marker()

	look_marker_node = get_node_or_null(look_marker_node_path)

	animation_player = get_node_or_null(animation_player_node_path)


func save_state() -> Dictionary:
	var state := super()
	#state[&"has_been_turned"] = has_been_turned
	return state


func load_state(state: Dictionary) -> void:
	super(state)
	#has_been_turned = state.get(&"has_been_turned", false)


func interact(player: Player) -> void:
	if player.sitting_handler.current_seat:
		if player.sitting_handler.current_seat == self:
			player.sitting_handler.stand_requested()
			_stand_up()
		else:
			var previous_seat := player.sitting_handler.current_seat
			previous_seat._stand_up()
			player.sitting_handler.seat_move_requested(self)
			_sit_down()
	else:
		player.sitting_handler.sit_requested(self)
		_sit_down()


func _displace_sit_marker() -> void:
	var adjusted_transform := sit_position_node.transform
	adjusted_transform.origin.y -= sit_marker_displacement
	sit_position_node.transform = adjusted_transform


func _sit_down() -> void:
	_play_sound(sit_sound, sit_pitch)

	if animation_player:
		animation_player.play(animation_on_enter)

	object_state_updated.emit(interaction_text_when_on)


func _stand_up() -> void:
	_play_sound(stand_sound, stand_pitch)

	if animation_player:
		animation_player.play(animation_on_leave)

	object_state_updated.emit(interaction_text_when_off)


func _play_sound(sound: AudioStream, pitch: float) -> void:
	if audio_stream_player_3d and sound:
		audio_stream_player_3d.stream = sound
		audio_stream_player_3d.pitch_scale = pitch
		audio_stream_player_3d.play()
