@tool
extends NpcBTAction


func _update(_delta: float) -> Status:
	agent.end_search()
	return SUCCESS
