class_name ThirdPersonWieldable
extends Node3D

@export var animation_player: AnimationPlayer
@export var muzzle_flash: MuzzleFlash

var _player: Player
var _wieldable: Wieldable


func initialize(player: Player, wieldable: Wieldable, mesh_layer: int) -> void:
	_player = player
	_wieldable = wieldable

	_apply_mesh_layer(mesh_layer)
	_connect_signals()


func _apply_mesh_layer(mesh_layer: int) -> void:
	var all_mesh_instances := find_children("*", "MeshInstance3D")
	for mesh_instance in all_mesh_instances:
		mesh_instance.layers = mesh_layer


func _connect_signals() -> void:
	_wieldable.idle_started.connect(_on_idle_started)
	_wieldable.primary_action_started.connect(_on_primary_action_started)
	_wieldable.reload_started.connect(_on_reload_started)


func _on_idle_started() -> void:
	if animation_player:
		animation_player.play("idle")


func _on_primary_action_started() -> void:
	if animation_player:
		animation_player.play("fire")

	if muzzle_flash:
		muzzle_flash.flash()


func _on_reload_started() -> void:
	if animation_player:
		animation_player.play("reload")
