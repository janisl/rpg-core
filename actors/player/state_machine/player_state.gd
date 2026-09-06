class_name PlayerState
extends Node

var player: Player

@onready var state_machine: PlayerStateMachine = %StateMachine


func _ready() -> void:
	if state_machine && state_machine is PlayerStateMachine:
		player = state_machine.player
