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

@export_group("Vision")
@export var sit_marker_displacement := 0.9
@export_range(0, 180, 0.1, "radians_as_degrees") var horizontal_look_angle := deg_to_rad(120)
@export_range(0, 180, 0.1, "radians_as_degrees") var vertical_look_angle := PI / 2.0

@export_group("Animation")
@export var tween_duration := 0.8
@export var rotation_tween_duration := 0.4

@export_group("Nodes")
@export var sit_position_node_path: NodePath
@export var look_marker_node_path: NodePath
@export var leave_node_path: NodePath

@export_group("Interaction")
@export var interaction_text_when_on := "INTERACT Stand Up"
@export var interaction_text_when_off := "INTERACT Sit"

var sit_position_node: Node3D
var look_marker_node: Node3D


func _ready() -> void:
	super()

	sit_position_node = get_node_or_null(sit_position_node_path)
	assert(sit_position_node, "Sit position node not found. Ensure the path is correct.")
	_displace_sit_marker()

	look_marker_node = get_node_or_null(look_marker_node_path)
	assert(look_marker_node, "Look marker node not found.")


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


func _sit_down(play_sound: bool = true) -> void:
	object_state_updated.emit(interaction_text_when_on)


func _stand_up(play_sound: bool = true) -> void:
	object_state_updated.emit(interaction_text_when_off)
