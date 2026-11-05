class_name InteractableTurnwheel
extends DynamicObject

@export var audio_stream_player: AudioStreamPlayer3D

@export var rotation_axis := Vector3(0, 0, 1)
@export_range(-360, 360, 0.001, "radians_as_degrees") var rotation_speed := PI
@export var nodes_to_trigger: Array[Node]
@export var hold_audio_stream: AudioStream

var has_been_turned := false


func _ready() -> void:
	super()
	self.add_to_group("interactable")

	if !audio_stream_player:
		var players := find_children("", "AudioStreamPlayer3D")
		if len(players) > 0:
			audio_stream_player = players[0]

	if audio_stream_player:
		audio_stream_player.stream = hold_audio_stream

	for node in find_children("", "InteractionComponent", true):
		if node and node.has_signal("is_being_held"):
			node.is_being_held.connect(_is_being_turned)


func save_state() -> Dictionary:
	var state := super()
	state[&"has_been_turned"] = has_been_turned
	return state


func load_state(state: Dictionary) -> void:
	super(state)
	has_been_turned = state.get(&"has_been_turned", false)


func interact(_player: Player) -> void:
	if audio_stream_player:
		audio_stream_player.stop()
	has_been_turned = !has_been_turned
	for node in nodes_to_trigger:
		node.interact(null)


func _is_being_turned(_time_remaining: float, delta: float) -> void:
	if audio_stream_player and !audio_stream_player.playing:
		audio_stream_player.play()

	if has_been_turned:
		rotate_object_local(rotation_axis * -1, rotation_speed * delta)
	else:
		rotate_object_local(rotation_axis, rotation_speed * delta)
