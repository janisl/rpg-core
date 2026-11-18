@warning_ignore("missing_tool")
class_name Pressureplate
extends DynamicObject

signal plate_activated
signal plate_deactivated

@export var audio_stream_player_3d: AudioStreamPlayer3D
@export var activation_sound: AudioStream

@export var objects_call_interact: Array[NodePath]
@export var objects_call_delay := 0.0

@export_group("Plate settings")
@export var plate_node: RigidBody3D
@export var weighted_down_plate_position: Vector3

var _is_activated := false
var _player: Player


func _ready() -> void:
	super()
	if not audio_stream_player_3d:
		var players: Array[Node] = find_children("", "AudioStreamPlayer3D")
		if len(players) > 0:
			audio_stream_player_3d = players[0]

	if audio_stream_player_3d:
		audio_stream_player_3d.stream = activation_sound


func _physics_process(_delta: float) -> void:
	if !_is_activated and (plate_node.position - weighted_down_plate_position).length() <= 0.03:
		_weigh_down()
	if _is_activated and (plate_node.position - weighted_down_plate_position).length() > 0.03:
		_weight_lifted()


func save_state() -> Dictionary:
	var state := super()
	state[&"is_activated"] = _is_activated
	state[&"plate_position"] = plate_node.position
	return state


func load_state(state: Dictionary) -> void:
	super(state)
	_is_activated = state.get(&"is_activated", false)
	plate_node.position = state.get(&"plate_position", plate_node.position)


func _on_plate_body_entered(body: Node) -> void:
	if body is Player:
		_player = body
	if body is Actor:
		plate_node.add_constant_central_force(Vector3(0, -100, 0))


func _on_plate_body_exited(body: Node) -> void:
	if body is DynamicObject:
		_weight_lifted()
	if body is Actor:
		plate_node.constant_force = Vector3(0, 0, 0)


func _weigh_down() -> void:
	if audio_stream_player_3d:
		audio_stream_player_3d.play()

	_is_activated = true
	plate_activated.emit()

	for nodepath in objects_call_interact:
		await get_tree().create_timer(objects_call_delay).timeout
		if nodepath != null:
			var object := get_node(nodepath)
			object.interact(_player)


func _weight_lifted() -> void:
	_is_activated = false
	plate_deactivated.emit()
