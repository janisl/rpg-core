class_name SimpleEnemy
extends Enemy


func on_trigger(player: Player) -> void:
	set_sight_target(player.global_position)
