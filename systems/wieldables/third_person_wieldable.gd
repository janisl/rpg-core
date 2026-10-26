class_name ThirdPersonWieldable
extends Node3D

@export var animation_player: AnimationPlayer
@export var muzzle_flash: MuzzleFlash

var _wieldable: Wieldable


func initialize(wieldable: Wieldable, mesh_layer: int) -> void:
	_wieldable = wieldable

	_apply_mesh_layer(mesh_layer)
	_connect_signals()


func _apply_mesh_layer(mesh_layer: int) -> void:
	var all_visual_instances := find_children("*", "VisualInstance3D")
	for instance in all_visual_instances:
		instance.layers = mesh_layer


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
