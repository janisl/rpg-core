class_name StaminaAttribute
extends BaseAttribute

@export var stamina_regen_speed := 2.0
@export var run_exhaustion_speed := 3.0
@export var jump_exhaustion := 5.0
@export var regenerate_after := 2.0
@export var auto_regenerate := true

@export_group("Floor Slope Exhaustion Settings")
@export var use_floor_slope_for_run_exhaustion := true
@export var uphill_run_exhaustion_max_speed := 6.0
@export var downhill_run_exhaustion_max_speed := 2.0
@export var step_slope_multiplier := 4.0

var _is_regenerating : bool
var _player : Player
var _last_y : float

@onready var regen_timer: Timer = $RegenTimer


func _ready() -> void:
	super()
	_player = get_parent()

	regen_timer.wait_time = regenerate_after


func _process(delta: float) -> void:
	if _is_regenerating:
		add(stamina_regen_speed * delta)
		if value >= max_value:
			_is_regenerating = false

	if _player.is_sprinting and _player.velocity.length() > _player.ground_movement.default_speed and _player.velocity.length() > 0.1:
		regen_timer.stop()
		_is_regenerating = false
		var exhaustion := _run_exhaustion()
		subtract(exhaustion * delta)
	_last_y = _player.global_position.y
	
	if !_is_regenerating and regen_timer.is_stopped() and value < max_value and !_player.is_sprinting:
		regen_timer.start()


func _on_regen_timer_timeout() -> void:
	_is_regenerating = value < max_value


func  _run_exhaustion() -> float:
	if !use_floor_slope_for_run_exhaustion:
		return run_exhaustion_speed

	var floor_normal := _player.get_floor_normal()
	var movement_direction := _player.velocity.normalized()
	var slope_factor := movement_direction.dot(floor_normal)

	if is_zero_approx(slope_factor):
		if !is_equal_approx(_player.global_position.y, _last_y):
			slope_factor = (_last_y - _player.global_position.y) * step_slope_multiplier
			slope_factor = clampf(slope_factor, -1.0, 1.0)
		else:
			return run_exhaustion_speed

	if slope_factor < 0.0001:
		var uphill_run_exhaustion := lerpf(run_exhaustion_speed, uphill_run_exhaustion_max_speed, abs(slope_factor))
		return uphill_run_exhaustion
	else:
		var downhill_run_exhaustion := lerpf(run_exhaustion_speed, downhill_run_exhaustion_max_speed, slope_factor)
		return downhill_run_exhaustion
