extends Node2D


@export var bar_height : float = 5
@export var bar_width : float = 30
@export var bar_pos_y : float = 36
@export var bar_background : Color = Color(0.159, 0.106, 0.46, 1.0)
@export var bar_fill_full : Color = Color(1.0, 0.0, 0.0, 1.0)
@export var bar_fill_empty : Color = Color(1.0, 0.0, 0.0, 1.0)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	
	# Scans all asteroids
	for a in get_tree().get_nodes_in_group("Asteroids"):
		
		# Skips asteroids that are freed, full HP, or bosses
		if a.is_dead or a.health >= a.max_health or a.data.behavior == AsteroidData.BehaviorType.BOSS: continue
		#print(get_tree().get_nodes_in_group("Asteroids").size())
		
		# Records asteroid health
		var max_health : float = a.max_health
		var current_health : float = a.health
		
		# Calculates properties of bar based on position and scale of asteroid
		var size : Vector2 = Vector2(bar_width,bar_height)
		var y_offset : float = bar_pos_y * a.scale.y
		var center : Vector2 = to_local(a.global_position)
		var top_left_position : Vector2 = center + Vector2(-bar_width/2, y_offset)
		
		# Tracks progression of health bar
		var frac : float = current_health / max_health
		var fill_color : Color = bar_fill_empty.lerp(bar_fill_full, frac)
		
		# Generates health bar: background, fill, then outline
		draw_rect(Rect2(top_left_position, size), bar_background)
		draw_rect(Rect2(top_left_position, Vector2(bar_width * frac, bar_height)), fill_color)
		draw_rect(Rect2(top_left_position, size), Color.BLACK, false, 1)
		
