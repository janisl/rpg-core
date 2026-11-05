class_name HoldInteraction
extends InteractionComponent

signal is_being_held(time_left: float, delta: float)
signal hold_progress_changed

@export var hold_time := 3.0
@export var buffer_time := 0.1

var show_hold_progress := false
var hold_progress := 0.0

var _player: Player
var _hold_timer: Timer
var _is_holding := false

@onready var parent_node := get_parent()


func _ready() -> void:
	if parent_node.has_signal("object_state_updated"):
		parent_node.object_state_updated.connect(_on_object_state_change)

	_hold_timer = Timer.new()
	add_child(_hold_timer)
	_hold_timer.one_shot = true
	_hold_timer.timeout.connect(_on_hold_complete)


func _physics_process(delta: float) -> void:
	if not _is_holding:
		return

	if not _player.interaction_controller.interactable:
		_stop_holding()
		return

	if not _is_hold_pressed():
		_hold_released()
		_stop_holding()
		return

	show_hold_progress = _hold_timer.time_left  < _hold_timer.wait_time - buffer_time
	is_being_held.emit(_hold_timer.time_left, delta)
	hold_progress = 1 - (_hold_timer.time_left / hold_time)
	hold_progress_changed.emit()


func save_state() -> Dictionary:
	var state := super()
	state[&"interaction_text"] = interaction_text
	return state


func load_state(state: Dictionary) -> void:
	super(state)
	interaction_text = state.get(&"interaction_text", interaction_text)


func interact(player: Player) -> void:
	was_interacted_with.emit()
	_player = player
	if !_is_holding:
		_start_holding()


func _start_holding() -> void:
	_is_holding = true
	_hold_timer.wait_time = hold_time
	hold_progress = 1 - (_hold_timer.time_left / hold_time)
	hold_progress_changed.emit()
	_hold_timer.start()


func _stop_holding() -> void:
	_hold_timer.stop()
	show_hold_progress = false
	_is_holding = false
	hold_progress = 0.0
	hold_progress_changed.emit()


func _on_object_state_change(_interaction_text: String) -> void:
	interaction_text = _interaction_text
	EventBus.interactable_changed.emit()


func _on_hold_complete() -> void:
	_complete()
	_stop_holding()


func _complete() -> void:
	parent_node.interact(_player)


func _hold_released() -> void:
	pass


func _is_hold_pressed() -> bool:
	if input_map_action == "interact":
		return _player.input_controller.interact_pressed
	if input_map_action == "interact2":
		return _player.input_controller.interact2_pressed
	return false
