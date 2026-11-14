@warning_ignore("missing_tool")
class_name InteractableButton
extends DynamicObject

signal object_state_updated(interaction_text: String)
signal pressed

@export_group("Button Settings")
@export var press_sound: AudioStream
@export var press_cooldown_time := 1.0
@export var has_been_used_hint: String

@export_group("Interaction Settings")
@export var allows_repeated_interaction := true
@export var usable_interaction_text := "INTERACT Press"
@export var unusable_interaction_text := "INTERACT Unavailable"
@export var objects_call_interact: Array[NodePath]
@export var objects_call_delay := 0.0

var _has_been_used := false
var _cooldown: float


func _physics_process(delta: float) -> void:
	if _cooldown > 0:
		_cooldown -= delta


func save_state() -> Dictionary:
	var state := super()
	state[&"has_been_used"] = _has_been_used
	state[&"cooldown"] = _cooldown
	return state


func load_state(state: Dictionary) -> void:
	super(state)
	_has_been_used = state.get(&"has_been_used", false)
	_cooldown = state.get(&"cooldown", 0.0)


func interact(player: Player) -> void:
	if _cooldown > 0:
		return

	if !allows_repeated_interaction and _has_been_used:
		if has_been_used_hint:
			EventBus.show_notification.emit(has_been_used_hint)
		return

	pressed.emit()
	AudioManager.play_sound_3d(press_sound, global_position)

	if !allows_repeated_interaction:
		_has_been_used = true
		object_state_updated.emit(unusable_interaction_text)
	else:
		_cooldown = press_cooldown_time

	_call_linked_interact(player)


func _call_linked_interact(player: Player) -> void:
	if !objects_call_interact:
		return
	for nodepath in objects_call_interact:
		await get_tree().create_timer(objects_call_delay).timeout
		if nodepath != null:
			var object := get_node(nodepath)
			object.interact(player)


func _on_damage_taken(_hit_info: HitInfo) -> void:
	interact(LevelManager.current_player)
