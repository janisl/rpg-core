class_name Actor
extends CharacterBody3D


func is_in_swimmable_area() -> bool:
	return not get_tree().get_nodes_in_group("swimmable").all(func(area): return !area.overlaps_body(self))
