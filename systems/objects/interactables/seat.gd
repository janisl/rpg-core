@warning_ignore("missing_tool")
class_name Seat
extends DynamicObject

enum PlacementOnLeave {
	ORIGINAL,
	DISPLACEMENT,
	TRANSFORM,
	AUTO,
}

enum SitAreaBehaviour {
	NONE,
	MANUAL,
	AUTO,
}

signal object_state_updated(interaction_text: String)

@export_group("Sittable Behaviour")
@export var placement_on_leave := PlacementOnLeave.ORIGINAL
@export var eject_on_fall := false
@export_range(0, 180, 0.1, "radians_as_degrees") var eject_angle := PI / 4.0
@export var sit_area_behaviour := SitAreaBehaviour.NONE
@export var disable_on_jump := true
@export var disable_on_crouch := true

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
@export var interact_cooldown_duration := 0.4

var sit_position_node: Node3D
var look_marker_node: Node3D
var animation_player: AnimationPlayer

var _is_occupied := false
var _interact_cooldown := 0.0

@onready var basic_interaction: BasicInteraction = $BasicInteraction


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

	match sit_area_behaviour:
		SitAreaBehaviour.NONE:
			basic_interaction.is_disabled = false
		SitAreaBehaviour.MANUAL:
			basic_interaction.is_disabled = true
		SitAreaBehaviour.AUTO:
			basic_interaction.is_disabled = true


func save_state() -> Dictionary:
	var state := super()
	SaveUtils.save_animation_player(state, &"animation_player", animation_player)
	state[&"is_occupied"] = _is_occupied
	return state


func load_state(state: Dictionary) -> void:
	super(state)
	SaveUtils.load_animation_player(state, &"animation_player", animation_player)
	_is_occupied = state.get(&"is_occupied", false)


func interact(player: Player) -> void:
	var current_time := Time.get_ticks_msec() / 1000.0
	if current_time < _interact_cooldown:
		return
	_interact_cooldown = current_time + interact_cooldown_duration

	if !_is_occupied and _is_fallen():
		EventBus.show_notification.emit("I can't sit there!")
		return

	if disable_on_crouch == true:
		if player.is_crouching:
			EventBus.show_notification.emit("I should stand up first")
			return

	if disable_on_jump == true:
		if not player.is_on_floor():
			EventBus.show_notification.emit("I should land first")
			return

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

	_is_occupied = true


func _stand_up() -> void:
	_play_sound(stand_sound, stand_pitch)

	if animation_player:
		animation_player.play(animation_on_leave)

	object_state_updated.emit(interaction_text_when_off)

	_is_occupied = false


func _play_sound(sound: AudioStream, pitch: float) -> void:
	if audio_stream_player_3d and sound:
		audio_stream_player_3d.stream = sound
		audio_stream_player_3d.pitch_scale = pitch
		audio_stream_player_3d.play()


func _is_fallen() -> bool:
	var current_rotation := global_transform.basis.get_euler()
	var pitch_angle := absf(current_rotation.x)
	var roll_angle := absf(current_rotation.z)
	return pitch_angle > eject_angle or roll_angle > eject_angle


func _on_sit_area_body_entered(body: Node3D) -> void:
	var player := body as Player
	if not player:
		return

	match sit_area_behaviour:
		SitAreaBehaviour.MANUAL:
			basic_interaction.is_disabled = false

		SitAreaBehaviour.AUTO:
			if not player.sitting_handler.current_seat:
				interact(player)
				basic_interaction.is_disabled = false

		SitAreaBehaviour.NONE:
			basic_interaction.is_disabled = false
	EventBus.interactable_changed.emit()


func _on_sit_area_body_exited(body: Node3D) -> void:
	var player := body as Player
	if not player:
		return

	if player.sitting_handler.current_seat == self:
		basic_interaction.is_disabled = false
	else:
		basic_interaction.is_disabled = true
	EventBus.interactable_changed.emit()
