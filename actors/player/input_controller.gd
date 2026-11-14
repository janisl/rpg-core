class_name InputController
extends Node

@export_group("Input device settings")
@export_range(0, 10, 0.001, "radians_as_degrees") var mouse_sensitivity := 0.001
@export var joypad_deadzone := 0.25
@export_range(0, 10, 0.001, "radians_as_degrees") var joypad_horizontal_sensitivity := deg_to_rad(2.0)
@export_range(0, 10, 0.001, "radians_as_degrees") var joypad_vertical_sensitivity := deg_to_rad(2.0)
@export var invert_y_axis := false

var move_input := Vector2.ZERO
var look_delta := Vector2.ZERO
var sprint_pressed := false
var jump_pressed := false
var jump_just_pressed := false
var crouch_pressed := false
var crouch_just_pressed := false
var primary_action_pressed := false
var primary_action_just_pressed := false
var secondary_action_pressed := false
var reload_pressed := false
var reload_just_pressed := false
var cycle_ammo_pressed := false
var cycle_ammo_just_pressed := false
var interact_pressed := false
var interact_just_pressed := false
var interact2_pressed := false
var interact2_just_pressed := false

var _is_disabled := false


func _ready() -> void:
	process_physics_priority = 1
	EventBus.in_game_screen_shown.connect(_on_in_game_screen_shown)
	EventBus.in_game_screen_closed.connect(_on_in_game_screen_closed)


func _unhandled_input(event: InputEvent) -> void:
	if _is_disabled:
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var input: Vector2
		input.x = -event.relative.x * mouse_sensitivity
		input.y = -event.relative.y * mouse_sensitivity
		_update_look_delta(input)

	if event is InputEventJoypadMotion:
		var input := Vector2.ZERO

		if event.get_axis() == 2:
			if abs(event.get_axis_value()) > joypad_deadzone:
				input.x = -event.get_axis_value() * joypad_vertical_sensitivity

		if event.get_axis() == 3:
			if abs(event.get_axis_value()) > joypad_deadzone:
				input.y = -event.get_axis_value() * joypad_horizontal_sensitivity

		if input:
			_update_look_delta(input)

	if (event.is_action("move_forward")
			or event.is_action("move_backward")
			or event.is_action("move_left")
			or event.is_action("move_right")):
		move_input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")

	if event.is_action_pressed("sprint"):
		sprint_pressed = true
	if event.is_action_released("sprint"):
		sprint_pressed = false

	if event.is_action_pressed("jump"):
		jump_pressed = true
		jump_just_pressed = true
	if event.is_action_released("jump"):
		jump_pressed = false

	if event.is_action_pressed("crouch"):
		crouch_pressed = true
		crouch_just_pressed = true
	if event.is_action_released("crouch"):
		crouch_pressed = false

	if event.is_action_pressed("primary_action"):
		primary_action_pressed = true
		primary_action_just_pressed = true
	if event.is_action_released("primary_action"):
		primary_action_pressed = false

	if event.is_action_pressed("secondary_action"):
		secondary_action_pressed = true
	if event.is_action_released("secondary_action"):
		secondary_action_pressed = false

	if event.is_action_pressed("reload"):
		reload_pressed = true
		reload_just_pressed = true
	if event.is_action_released("reload"):
		reload_pressed = false

	if event.is_action_pressed("cycle_ammo"):
		cycle_ammo_pressed = true
		cycle_ammo_just_pressed = true
	if event.is_action_released("cycle_ammo"):
		cycle_ammo_pressed = false

	if event.is_action_pressed("interact"):
		interact_pressed = true
		interact_just_pressed = true
	if event.is_action_released("interact"):
		interact_pressed = false

	if event.is_action_pressed("interact2"):
		interact2_pressed = true
		interact2_just_pressed = true
	if event.is_action_released("interact2"):
		interact2_pressed = false


func _physics_process(_delta: float) -> void:
	_clear_just_pressed()


func consume_look_delta() -> Vector2:
	var result := look_delta
	look_delta = Vector2.ZERO
	return result


func _update_look_delta(input: Vector2) -> void:
	if invert_y_axis:
		input.y *= -1

	look_delta += input


func _on_in_game_screen_shown(_screen: Control) -> void:
	_is_disabled = true
	_clear()


func _on_in_game_screen_closed(_screen: Control) -> void:
	_is_disabled = false


func _clear() -> void:
	move_input = Vector2.ZERO
	look_delta = Vector2.ZERO
	_clear_pressed()
	_clear_just_pressed()


func _clear_pressed() -> void:
	sprint_pressed = false
	jump_pressed = false
	crouch_pressed = false
	primary_action_pressed = false
	secondary_action_pressed = false
	reload_pressed = false
	cycle_ammo_pressed = false
	interact_pressed = false
	interact2_pressed = false


func _clear_just_pressed() -> void:
	jump_just_pressed = false
	crouch_just_pressed = false
	primary_action_just_pressed = false
	reload_just_pressed = false
	cycle_ammo_just_pressed = false
	interact_just_pressed = false
	interact2_just_pressed = false
