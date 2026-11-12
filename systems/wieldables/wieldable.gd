class_name Wieldable
extends Node3D

signal equip_started
signal unequip_started
signal idle_started
signal primary_action_started
signal reload_started

signal data_changed
signal unequipped

var is_unequipping := false
var aim_fraction := 0.0

var _item_owner: Actor
var _owner_inventory: Inventory
var _item_stack: ItemStack
var _wieldable_data: WieldableData

var _from_position := Vector3.ZERO
var _forward_direction := Vector3.ZERO
var _primary_action_pressed := false
var _primary_action_just_pressed := false
var _secondary_action_pressed := false
var _secondary_action_just_pressed := false
var _reload_pressed := false
var _cycle_ammo_pressed := false

var _equip_timer := 0.0
var _unequip_timer := 0.0

@onready var state_chart: StateChart = $StateChart
@onready var audio: AudioStreamPlayer3D = $Audio


func _physics_process(delta: float) -> void:
	if _wieldable_data.secondary_action == WieldableData.SecondaryAction.AIM:
		_update_aim_fraction(delta)


func initialize(own: Actor, inventory: Inventory, stack: ItemStack) -> void:
	_item_owner = own
	_owner_inventory = inventory
	_item_stack = stack
	_wieldable_data = stack.item


func update(
		from_position: Vector3,
		direction: Vector3,
		primary_action_pressed: bool,
		secondary_action_pressed: bool,
		reload_pressed := false,
		cycle_ammo_pressed := false) -> void:
	_from_position = from_position
	_forward_direction = direction
	_primary_action_just_pressed = primary_action_pressed and not _primary_action_pressed
	_primary_action_pressed = primary_action_pressed
	_secondary_action_just_pressed = secondary_action_pressed and not _secondary_action_pressed
	_secondary_action_pressed = secondary_action_pressed
	_reload_pressed = reload_pressed
	_cycle_ammo_pressed = cycle_ammo_pressed


func unequip() -> void:
	if is_unequipping:
		return

	is_unequipping = true
	state_chart.send_event("onUnequipping")


func save_state() -> Dictionary:
	var state := Dictionary()
	SaveUtils.save_state_chart(state, &"state_chart", state_chart)
	state[&"is_unequipping"] = is_unequipping
	state[&"equip_timer"] = _equip_timer
	state[&"unequip_timer"] = _unequip_timer
	return state


func load_state(state: Dictionary) -> void:
	SaveUtils.load_state_chart(state, &"state_chart", state_chart)
	is_unequipping = state.get(&"is_unequipping", false)
	_equip_timer = state.get(&"equip_timer", 0.0)
	_unequip_timer = state.get(&"unequip_timer", 0.0)


func _emit_primary_action_started() -> void:
	primary_action_started.emit()


func _emit_reload_started() -> void:
	reload_started.emit()


func _emit_data_changed() -> void:
	data_changed.emit()


func _emit_unequipped() -> void:
	unequipped.emit()


func _on_equipping_state_entered() -> void:
	_equip_timer = _wieldable_data.equip_time
	equip_started.emit()
	_play_sound(_wieldable_data.equip_sound)


func _on_equipping_state_physics_processing(delta: float) -> void:
	_equip_timer -= delta
	if _equip_timer <= 0:
		state_chart.send_event("onIdle")


func _on_unequipping_state_entered() -> void:
	_unequip_timer = _wieldable_data.unequip_time
	unequip_started.emit()
	_play_sound(_wieldable_data.unequip_sound)


func _on_unequipping_state_physics_processing(delta: float) -> void:
	_unequip_timer -= delta
	if _unequip_timer <= 0:
		_emit_unequipped()


func _on_idle_state_entered() -> void:
	idle_started.emit()
	_play_sound(_wieldable_data.idle_sound)


func _update_aim_fraction(delta: float) -> void:
	var aim_target := 1.0 if _secondary_action_pressed else 0.0
	aim_fraction = move_toward(aim_fraction, aim_target, _wieldable_data.aim_speed * delta)


func _play_sound(sound: AudioStream) -> void:
	if not sound:
		return
	audio.stream = sound
	audio.global_position = _from_position
	audio.pitch_scale = 1.0
	audio.volume_db = 0.0
	audio.play()
