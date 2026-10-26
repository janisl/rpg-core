class_name SimpleEnemy
extends Enemy

@onready var state_chart: StateChart = $StateChart
@onready var health_attribute: HealthAttribute = $HealthAttribute


func _ready() -> void:
	super()

	attention_target = get_tree().get_first_node_in_group("player")

	health_attribute.died.connect(_on_died)


func on_triggered() -> void:
	state_chart.send_event("onChase")


func on_trigger(_player: Player) -> void:
	state_chart.send_event("onChase")


func _on_died() -> void:
	queue_free()
