class_name InteractionRayCast
extends RayCast3D

signal interactable_seen(interactable)
signal interactable_unseen()

var _interactable = null:
	set = _set_interactable


func _process(_delta: float) -> void:
	_update_interactable()


func _set_interactable(value) -> void:
	_interactable = value
	if _interactable == null:
		interactable_unseen.emit()
	else:
		interactable_seen.emit(_interactable)


func _update_interactable() -> void:
	if is_colliding():
		var collider = get_collider()
		if collider == _interactable:
			return
		_interactable = collider
	else:
		_interactable = null
