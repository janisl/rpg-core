class_name WeaponStateBehaviour
extends StateBehaviour

var weapon: Weapon


func _ready() -> void:
	weapon = _find_owner() as Weapon

	super()
