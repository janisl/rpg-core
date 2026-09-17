class_name HealthPickup
extends BasePickup

@export var ammount := 20


func _can_pickup(player: Player) -> bool:
	var health_component := player.get_node_or_null("HealthComponent") as HealthComponent

	return health_component and health_component.current_health < health_component.max_health


func _apply_pickup(player: Player) -> void:
	var health_component := player.get_node_or_null("HealthComponent") as HealthComponent

	if health_component:
		health_component.heal(ammount)
