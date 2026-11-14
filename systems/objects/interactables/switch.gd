@warning_ignore("missing_tool")
class_name Switch
extends DynamicObject

signal object_state_updated(interaction_text: String)
signal switched(is_on: bool)

@export var is_on := false
@export var nodes_to_show_when_on: Array[Node]
@export var nodes_to_hide_when_on: Array[Node]

@export_group("Interaction Settings")
@export var interaction_text_when_on := "INTERACT Off"
@export var interaction_text_when_off := "INTERACT On"
@export var objects_call_interact: Array[NodePath]
@export var objects_call_delay := 0.0

@export_group("Animation Settings")
@export var animation_player: AnimationPlayer
@export var anim_when_switched_on: String
@export var anim_when_switched_off: String
@export var animation_speed := 1.0


func _ready() -> void:
	super()

	if is_on:
		_switch_on()
	else:
		_switch_off()


func save_state() -> Dictionary:
	var state := super()
	state[&"is_on"] = is_on
	return state


func load_state(state: Dictionary) -> void:
	super(state)
	is_on = state.get(&"is_on", false)
	_set_visibility_state()


func interact(player: Player) -> void:
	_switch(player)


func _switch(player: Player) -> void:
	if is_on:
		_switch_off()
	else:
		_switch_on()

	_call_interact_on_objects(player)


func _switch_on() -> void:
	if animation_player:
		animation_player.play(anim_when_switched_on, -1, animation_speed)

	is_on = true
	_set_visibility_state()

	object_state_updated.emit(interaction_text_when_on)
	switched.emit(is_on)


func _switch_off() -> void:
	if animation_player:
		animation_player.play(anim_when_switched_off, -1, animation_speed)

	is_on = false
	_set_visibility_state()

	object_state_updated.emit(interaction_text_when_off)
	switched.emit(is_on)


func _set_visibility_state() -> void:
	if is_on:
		for node in nodes_to_show_when_on:
			node.show()

		for node in nodes_to_hide_when_on:
			node.hide()
	else:
		for node in nodes_to_show_when_on:
			node.hide()

		for node in nodes_to_hide_when_on:
			node.show()


func _call_interact_on_objects(player: Player) -> void:
	if !objects_call_interact:
		return
	for nodepath in objects_call_interact:
		await get_tree().create_timer(objects_call_delay).timeout
		if nodepath:
			var object := get_node(nodepath)
			object.interact(player)
