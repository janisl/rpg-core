class_name SimpleEnemy
extends Enemy


func on_trigger(player: Player) -> void:
	sight_detection.generate_attention_target(player.global_position)
	notify_alerted()
