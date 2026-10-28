class_name SimpleEnemy
extends Enemy


func on_trigger(player: Player) -> void:
	attention_target = player
	state_chart.send_event("chase")
