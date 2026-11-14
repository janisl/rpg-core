@warning_ignore("missing_tool")
class_name Switch
extends DynamicObject

signal object_state_updated(interaction_text: String)
signal switched(is_on: bool)

@export_group("Switch Settings")
@export var is_on := false
@export var nodes_to_show_when_on: Array[Node]
@export var nodes_to_hide_when_on: Array[Node]
@export var needs_item_to_operate := false
@export var required_item: ItemData
@export var item_hint: String

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

@export_group("Audio")
@export var audio_stream_player_3d: AudioStreamPlayer3D
@export var switch_sound: AudioStream

var _is_holding_item := false


func _ready() -> void:
	super()

	if !audio_stream_player_3d:
		var players := find_children("", "AudioStreamPlayer3D")
		if len(players) > 0:
			audio_stream_player_3d = players[0]

	if audio_stream_player_3d:
		audio_stream_player_3d.stream = switch_sound

	if is_on:
		_switch_on()
	else:
		_switch_off()


func save_state() -> Dictionary:
	var state := super()
	state[&"is_on"] = is_on
	state[&"is_holding_item"] = _is_holding_item
	return state


func load_state(state: Dictionary) -> void:
	super(state)
	is_on = state.get(&"is_on", false)
	_is_holding_item = state.get(&"is_holding_item", false)
	_set_visibility_state()


func interact(player: Player) -> void:
	if needs_item_to_operate:
		if _is_holding_item:
			player.inventory.add_item(required_item)
			_is_holding_item = false
		else:
			if not _check_for_item(player):
				return
			_is_holding_item = true

	_switch(player)


func _switch(player: Player) -> void:
	if audio_stream_player_3d:
		audio_stream_player_3d.play()

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


func _on_damage_taken(_hit_info: HitInfo) -> void:
	interact(LevelManager.current_player)


func _check_for_item(player: Player) -> bool:
	if player.inventory.remove_item(required_item):
		return true

	if item_hint:
		EventBus.show_notification.emit(item_hint)
	return false
