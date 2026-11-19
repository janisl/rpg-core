@tool
extends NpcBTAction
## Plays one of the NPC's [NpcSounds].

## Property name in [NpcSounds], e.g. [code]alerted_sound[/code].
@export var sound: StringName


func _generate_name() -> String:
	return "PlaySound %s" % sound


func _update(_delta: float) -> Status:
	if agent.sounds:
		agent.play_sound(agent.sounds.get(sound))
	return SUCCESS
