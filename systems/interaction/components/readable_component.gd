class_name ReadableComponent
extends InteractionComponent

const READABLE_UI = preload("uid://n4j8kr8krxek")

signal has_been_read

@export_group("Readable Settings")
@export var interact_sound: AudioStream
@export var readable_title: String
@export_multiline var readable_content: String
@export var rich_text: bool


func interact(_player: Player) -> void:
	AudioManager.play_sound_3d(interact_sound, global_position)

	open()


func open() -> void:
	var screen: ReadableUI = UserInterface.show_in_game_screen(READABLE_UI)
	screen.set_content(readable_title, readable_content, rich_text)
	has_been_read.emit()
