@tool
class_name LootContainer
extends InteractableContainer

enum InventoryRespawningLogic {
	NONE,
	TIMED_RESPAWN,
}

@export_group("Loot Table Configuration")
@export var loot_table: LootTable

@export_group("Execution Configuration")
@export var inventory_respawning_logic := InventoryRespawningLogic.NONE:
	set(value):
		inventory_respawning_logic = value
		notify_property_list_changed()

@export var time_passes_when_unloaded := true

@export_group("Respawn Timer")
@export_range(0, 30, 1, "suffix:days") var respawn_timer_days := 0.0
@export_range(0, 24, 1, "suffix:hours") var respawn_timer_hours := 0.0
@export_range(0, 60, 1, "suffix:minutes") var respawn_timer_minutes := 1.0
@export_range(0, 60, 1, "suffix:seconds") var respawn_timer_seconds := 0.0

var _timer: Timer
var _end_time: float


func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		return

	_handle_inventory.call_deferred()
	_handle_respawning.call_deferred()


func _validate_property(property: Dictionary) -> void:
	if property.name in [
			"time_passes_when_unloaded",
			"respawn_timer_days",
			"respawn_timer_hours",
			"respawn_timer_minutes",
			"respawn_timer_seconds"] and inventory_respawning_logic != InventoryRespawningLogic.TIMED_RESPAWN:
		property.usage = PROPERTY_USAGE_NO_EDITOR


func save_state() -> Dictionary:
	var state := super()
	if _timer:
		if time_passes_when_unloaded:
			state[&"end_time"] = _end_time
		else:
			SaveUtils.save_timer(state, &"timer", _timer)
	return state


func load_state(state: Dictionary) -> void:
	super(state)
	if _timer:
		if time_passes_when_unloaded:
			_end_time = state.get(&"end_time", 0.0)
			var current_time := Time.get_unix_time_from_system()
			_timer.stop()
			if current_time < _end_time:
				_timer.wait_time = _end_time - current_time
			else:
				_timer.wait_time = 3.0
			_timer.start()
		else:
			SaveUtils.load_timer(state, &"timer", _timer)


func _open(player: Player) -> void:
	super(player)
	if inventory_respawning_logic == InventoryRespawningLogic.TIMED_RESPAWN:
		_pause_timer()


func _close() -> void:
	super()
	if inventory_respawning_logic == InventoryRespawningLogic.TIMED_RESPAWN:
		_unpause_timer()


func _handle_inventory() -> void:
	var lootgen := LootGenerator.new()
	var finalized_items := lootgen.generate(loot_table)
	_populate_the_container(finalized_items)


func _populate_the_container(_items: Array[LootTableEntry]) -> void:
	inventory.clear()
	for item in _items:
		var amount := randi_range(item.quantity_min, item.quantity_max)
		inventory.add_item(item.item, amount)


func _handle_respawning() -> void:
	match inventory_respawning_logic:
		InventoryRespawningLogic.NONE:
			return
		InventoryRespawningLogic.TIMED_RESPAWN:
			if not _timer:
				_set_up_timer()


func _calculate_timer_value() -> float:
	return (
		(respawn_timer_days * 86400.0) +
		(respawn_timer_hours * 3600.0) +
		(respawn_timer_minutes * 60.0) +
		respawn_timer_seconds)


func _set_up_timer() -> void:
	_timer = Timer.new()
	var calculated_respawn_timer := _calculate_timer_value()
	_end_time = Time.get_unix_time_from_system() + calculated_respawn_timer

	add_child(_timer)
	_timer.one_shot = false
	_timer.wait_time = calculated_respawn_timer
	_timer.timeout.connect(_respawn)

	_timer.start()


func _respawn() -> void:
	if !_timer.is_stopped():
		_timer.stop()

	var calculated_respawn_timer := _calculate_timer_value()
	_end_time = Time.get_unix_time_from_system() + calculated_respawn_timer
	_timer.wait_time = calculated_respawn_timer
	_handle_inventory()
	_timer.start()


func _pause_timer() -> void:
	if _timer != null:
		_timer.paused = true


func _unpause_timer() -> void:
	if _timer != null:
		_timer.paused = false
		_end_time = Time.get_unix_time_from_system() + _timer.time_left
