extends Area3D
class_name ImpactZone

@export var npc: Npc
@export var damage_on_impact: int
@export var impact_sound: AudioStream


func _ready() -> void:
	set_collision(false)
	body_entered.connect(_outgoing_body_entered)


func set_collision(enabled: bool) -> void:
	monitoring = enabled


func _outgoing_body_entered(node: Node3D) -> void:
	if node == npc:
		return

	var target_health_attribute := node.get_node_or_null("HealthAttribute") as HealthAttribute
	if not target_health_attribute:
		return

	var hit_info := HitInfo.new(damage_on_impact)
	hit_info.source_position = npc.global_position
	hit_info.impact_position = global_position
	hit_info.direction = global_position.direction_to(node.global_position)
	target_health_attribute.take_damage(hit_info)

	AudioManager.play_sound_3d(impact_sound, global_position)
