class_name FirstPersonWieldable
extends Node3D

@export var animation_player: AnimationPlayer
@export var muzzle_flash: MuzzleFlash

var _player: Player
var _wieldable: Wieldable


func initialize(player: Player, wieldable: Wieldable) -> void:
	_player = player
	_wieldable = wieldable

	_connect_signals()


func _connect_signals() -> void:
	_wieldable.weapon_idle.connect(_on_weapon_idle)
	_wieldable.weapon_fired.connect(_on_weapon_fired)
	_wieldable.weapon_reload_started.connect(_on_reload_started)


func _on_weapon_idle() -> void:
	if animation_player:
		animation_player.play("idle")


func _on_weapon_fired() -> void:
	if animation_player:
		animation_player.play("fire")

	if muzzle_flash:
		muzzle_flash.flash()


func _on_reload_started() -> void:
	if animation_player:
		animation_player.play("reload")
