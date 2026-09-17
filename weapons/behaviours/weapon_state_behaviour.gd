class_name WeaponStateBehaviour
extends StateBehaviour

var weapon_controller: WeaponController


func _ready() -> void:
	super()

	weapon_controller = (_find_owner() as Player).weapon_controller
