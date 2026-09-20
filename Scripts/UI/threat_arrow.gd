extends Polygon2D



@onready var glow: Sprite2D = $Outline/Glow


@export_category("Tween Settings")
@export var max_color : Color = Color(1, 0.2, 0.2, 1)
@export var min_color : Color = Color(0.7, 0, 0, 0.15)
@export var duration : float = .1
@export var blinks : int = 2
@export_category("Glow")
@export var max_glow_scale : float = 0.8

var blink_tween : Tween


func blink() -> void:
	if blink_tween and blink_tween.is_valid(): blink_tween.kill()
	blink_tween = create_tween()
	blink_tween.set_loops(blinks)
	blink_tween.tween_property(self, "self_modulate", max_color, duration)
	blink_tween.tween_property(self, "self_modulate", min_color, duration)


func update_glow(arrow_scale: Vector2) -> void:
	var new_scale = min(arrow_scale.x, max_glow_scale)
	glow.scale = Vector2(new_scale, new_scale)
