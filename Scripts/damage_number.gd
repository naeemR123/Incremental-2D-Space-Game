extends Node2D


@onready var label: Label = $Label

@export_range(0, 100, 1) var rise_strength: float = 40
@export_range(0, 1, 0.1) var rise_speed: float = 0.8


func start(damage_amount: float, pos: Vector2) -> void:
	label.text = str(damage_amount)
	global_position = pos
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", position + Vector2(0, -rise_strength), rise_speed)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.finished.connect(queue_free)
