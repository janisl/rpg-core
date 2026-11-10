class_name ConsumableItem
extends ItemData

@export_group("Consumable settings")
@export var consumable_effects : Array[ConsumableEffect]
@export var success_sound: AudioStream
@export var success_message: String
@export var failure_sound: AudioStream
@export var failure_message: String


func use(target: Actor, item_stack: ItemStack) -> bool:
	var did_use := false
	for effect in consumable_effects:
		if effect.use(target, item_stack):
			did_use = true

	if did_use:
		AudioManager.play_ui_sound(success_sound)
		if success_message:
			EventBus.show_notification.emit(tr(success_message))
		return true
	else:
		AudioManager.play_ui_sound(failure_sound)
		if failure_message:
			EventBus.show_notification.emit(tr(failure_message))
		return false
