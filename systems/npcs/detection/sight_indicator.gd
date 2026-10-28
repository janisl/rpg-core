extends DetectionIndicator

var is_investigating := false

@onready var indicator: Sprite3D = $Indicator
@onready var value: Label3D = $Value


func _ready() -> void:
	visible = false


func update(current_value: float, threshold_value: float) -> void:
	var ratio := clampf(current_value / threshold_value, 0.0, 1.0)
	visible = ratio >= 0
	if not is_investigating:
		indicator.modulate = Color(1, 1, 1 - ratio)
		value.text = "%d" % (ratio * 50)
	else:
		indicator.modulate = Color(1, 1 - ratio, 0)
		value.text = "%d" % (ratio * 100)
