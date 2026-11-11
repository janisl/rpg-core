class_name SimpleEnemy
extends Enemy


func on_trigger(player: Player) -> void:
	notify_alerted(sight_detection.generate_attention_target.bind(player.global_position))
