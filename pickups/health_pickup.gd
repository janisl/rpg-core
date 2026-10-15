class_name HealthPickup
extends BasePickup

@export var ammount := 20


func _can_pickup(player: Player) -> bool:
	var health_attribute := player.get_node_or_null("HealthAttribute") as HealthAttribute

	return health_attribute and health_attribute.value < health_attribute.max_value


func _apply_pickup(player: Player) -> void:
	var health_attribute := player.get_node_or_null("HealthAttribute") as HealthAttribute

	if health_attribute:
		health_attribute.heal(ammount)
