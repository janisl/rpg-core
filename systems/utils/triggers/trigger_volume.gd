class_name TriggerVolume
extends Area3D

signal activated(player: Player)
signal deactivated(player: Player)

@export var trigger_once := false
@export var trigger_on_exit := false
@export var delay := 0.0

var has_triggered := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if trigger_once and has_triggered:
		return

	if body is not Player:
		return

	has_triggered = true
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout

	_activate_targets(body)


func _on_body_exited(body: Node3D) -> void:
	if not trigger_on_exit:
		return

	if body is not Player:
		return

	_deactivate_targets(body)


func _activate_targets(player: Player) -> void:
	activated.emit(player)


func _deactivate_targets(player: Player) -> void:
	deactivated.emit(player)
