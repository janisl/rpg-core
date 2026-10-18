class_name HealthAttribute
extends BaseAttribute

signal damage_taken(hit_info: HitInfo)
signal died()

@export var death_sound: AudioStream

var is_alive := true


func _ready() -> void:
	super()
	value_reached_zero.connect(_handle_death)


func take_damage(hit_info: HitInfo) -> void:
	if not is_alive:
		return

	subtract(hit_info.actual_damage)

	damage_taken.emit(hit_info)


func heal(amount: float) -> void:
	if not is_alive:
		return

	var actual_heal = max(0.0, amount)
	add(actual_heal)


func _handle_death() -> void:
	if not is_alive:
		return

	is_alive = false

	AudioManager.play_sound_3d(death_sound, get_parent().global_position)

	died.emit()
