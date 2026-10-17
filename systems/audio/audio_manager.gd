extends Node


func play_sound_3d(sfx: AudioStream, position: Vector3, volume := 0.0) -> void:
	if not sfx:
		return

	var player := AudioStreamPlayer3D.new()
	get_tree().current_scene.add_child(player)
	player.stream = sfx
	player.bus = "Sounds"
	player.global_position = position
	player.volume_db = volume
	player.finished.connect(player.queue_free)
	player.play()
