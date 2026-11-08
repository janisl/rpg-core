class_name HealthAttribute
extends BaseAttribute

signal damage_taken(hit_info: HitInfo)
signal died()

@export var impact_sound: AudioStream
@export var hurt_sound: AudioStream
@export var death_sound: AudioStream
@export var free_on_death: Array[NodePath]
@export var spawn_on_death: Array[PackedScene]

var is_alive := true


func _ready() -> void:
	super()
	value_reached_zero.connect(_handle_death)


func take_damage(hit_info: HitInfo) -> void:
	if not is_alive:
		return

	subtract(hit_info.actual_damage)

	AudioManager.play_sound_3d(impact_sound, get_parent().global_position)
	if is_alive:
		AudioManager.play_sound_3d(hurt_sound, get_parent().global_position)

	damage_taken.emit(hit_info)


func heal(amount: float) -> void:
	if not is_alive:
		return

	var actual_heal := maxf(0.0, amount)
	add(actual_heal)


func _handle_death() -> void:
	if not is_alive:
		return

	is_alive = false

	var parent_position: Vector3 = get_parent().global_position
	var parent_rotation: Vector3 = get_parent().global_rotation

	AudioManager.play_sound_3d(death_sound, parent_position)

	for scene in spawn_on_death:
		if scene:
			var spawned_object := scene.instantiate()
			get_tree().current_scene.add_child(spawned_object)
			spawned_object.global_position = parent_position
			spawned_object.global_rotation = parent_rotation

	for nodepath in free_on_death:
		if get_node(nodepath):
			get_node(nodepath).queue_free()

	died.emit()


func save_state() -> Dictionary:
	var state := super()
	state[&"is_alive"] = is_alive
	return state


func load_state(state: Dictionary) -> void:
	super(state)
	is_alive = state.get(&"is_alive", false)
