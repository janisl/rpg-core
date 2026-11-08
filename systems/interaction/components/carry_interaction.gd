class_name CarryInteraction
extends InteractionComponent

signal carry_state_changed(is_being_carried: bool)
signal thrown(impulse: Vector3)

@export var lock_rotation_when_carried := true
@export var carry_distance_offset := 0.0
@export var carry_velocity_multiplier := 10.0
@export var drop_distance := 1.5
@export var enable_manual_rotating := true
@export var is_carryable_while_wielding := false

@export_group("Audio")
@export var audio_stream_player: AudioStreamPlayer3D
@export var pick_up_sound: AudioStream
@export var drop_sound: AudioStream

var carried_by: Player

var _parent_object: RigidBody3D


func _ready() -> void:
	super()

	if !audio_stream_player:
		var players := find_children("", "AudioStreamPlayer3D")
		if len(players):
			audio_stream_player = players[0]

	_parent_object = get_parent() as RigidBody3D
	assert(_parent_object, "Parent must be a RigidBody3D to work.")

	_parent_object.body_entered.connect(_on_body_entered)


func _physics_process(_delta: float) -> void:
	if not carried_by:
		return

	var carry_position := carried_by.carry_controller.get_carry_destination_point(carry_distance_offset)
	_parent_object.set_linear_velocity((carry_position - _parent_object.global_position) * carry_velocity_multiplier)

	if carry_position.distance_to(_parent_object.global_position) >= drop_distance:
		_stop_carrying()


func _exit_tree() -> void:
	if carried_by:
		_stop_carrying()


func save_state() -> Dictionary:
	var state := super()
	SaveUtils.save_ref(state, &"carried_by", carried_by)
	return state


func load_state(state: Dictionary) -> void:
	super(state)
	carried_by = SaveUtils.load_ref(state, &"carried_by")


func interact(player: Player) -> void:
	if carried_by:
		_stop_carrying()
	elif player.wield_controller.is_wielding:
		if is_carryable_while_wielding:
			_start_carrying(player)
		elif not player.wield_controller.is_changing_wieldables:
			player.wield_controller.setup_wieldable_to_auto_equip()
			_start_carrying(player)
	else:
		_start_carrying(player)

	was_interacted_with.emit()


func throw(power: float) -> void:
	var impulse := carried_by.carry_controller.get_look_direction() * power
	_stop_carrying()
	_play_sound(drop_sound)
	_parent_object.apply_central_impulse(impulse)
	thrown.emit(impulse)


func _start_carrying(player: Player) -> void:
	if lock_rotation_when_carried:
		_parent_object.lock_rotation = true
	_parent_object.freeze = false

	player.carry_controller.start_carrying(self)
	player.interaction_controller.add_exception(_parent_object)

	_play_sound(pick_up_sound)

	carried_by = player
	carry_state_changed.emit(true)


func _stop_carrying() -> void:
	if lock_rotation_when_carried:
		_parent_object.lock_rotation = false

	if carried_by and is_instance_valid(carried_by):
		carried_by.carry_controller.stop_carrying()
		carried_by.interaction_controller.remove_exception(_parent_object)
		carried_by.wield_controller.auto_equip_last_wieldable()

	carried_by = null
	carry_state_changed.emit(false)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and carried_by:
		_stop_carrying()


func _play_sound(sound: AudioStream) -> void:
	if audio_stream_player and sound:
		audio_stream_player.stream = sound
		audio_stream_player.play()
