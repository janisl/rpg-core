@warning_ignore("missing_tool")
class_name Switch
extends DynamicObject

signal object_state_updated(interaction_text: String)

@export var is_on := false

@export_group("Interaction Settings")
@export var interaction_text_when_on := "INTERACT Off"
@export var interaction_text_when_off := "INTERACT On"

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


func interact(player: Player) -> void:
	_switch(player)


func _switch(player: Player) -> void:
	if is_on:
		_switch_off()
	else:
		_switch_on()


func _switch_on() -> void:
	if animation_player:
		animation_player.play(anim_when_switched_on, -1, animation_speed)

	is_on = true
	object_state_updated.emit(interaction_text_when_on)


func _switch_off() -> void:
	if animation_player:
		animation_player.play(anim_when_switched_off, -1, animation_speed)

	is_on = false
	object_state_updated.emit(interaction_text_when_off)
