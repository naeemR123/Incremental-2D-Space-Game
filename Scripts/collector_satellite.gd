extends Area2D


@onready var game := Game_Manager


@onready var collector_range : CollisionShape2D = $Range
@onready var collection_zone : Area2D = $CollectionZone
@onready var range_indicator: Line2D = $RangeIndicator
@onready var preview_range_indicator: Line2D = $PreviewRangeIndicator

@export_group("Range Preview")
@export var preview_blink_duration : float = 1.0
@export var preview_blink_min_alpha : float = 0.0
@export var preview_blink_max_alpha : float = 0.50

var preview_blink_tween : Tween

var my_id : String
var my_range : float = 100.0
var my_collection_speed : float = 80
var my_gravity_strength : float = 0.5
var my_rand_rotation : float = randf_range(-2,2)

func initialize(data: SatelliteData) -> void:
	my_id = data.id


func _ready() -> void:
	
	collection_zone.area_entered.connect(_on_collection_area_entered)	# Connects the Area2D signals via code
	collector_range.shape = collector_range.shape.duplicate()
	
	game.stats_changed.connect(update_satellite_stats)
	update_satellite_stats()


func update_satellite_stats():
	my_collection_speed = game.active_stats[my_id][StatIDs.SAT_COLLECTION_SPEED]
	my_gravity_strength = game.active_stats[my_id][StatIDs.SAT_GRAVITY_STRENGTH]
	my_range = game.active_stats[my_id][StatIDs.RANGE]
	collector_range.shape.radius = my_range
	range_indicator.points = _build_range_circle(my_range)


func _process(delta: float) -> void:
	rotation += my_rand_rotation * delta


func _build_range_circle(radius: float, segments: int = 48) -> PackedVector2Array:
	var points = PackedVector2Array()
	for i in segments:
		var angle = TAU * i/segments
		points.append(Vector2(cos(angle),sin(angle)) * radius)
	return points


func set_range_visible(can_see: bool) -> void:
	range_indicator.visible = can_see


func set_preview_range_visible(can_see: bool, preview_radius: float = 0.0) -> void:
	preview_range_indicator.visible = can_see
	
	if can_see:
		preview_range_indicator.points = _build_range_circle(preview_radius)
		preview_blink_tween = create_tween()
		preview_blink_tween.set_loops()
		preview_blink_tween.tween_property(preview_range_indicator, "modulate:a", preview_blink_min_alpha, preview_blink_duration)
		preview_blink_tween.tween_property(preview_range_indicator, "modulate:a", preview_blink_max_alpha, preview_blink_duration)



func _physics_process(delta: float) -> void:
	var caught_resources = get_overlapping_areas()
	var current_frame = Engine.get_physics_frames()
	
	for resource in caught_resources:
		
		if "speed" in resource and "direction" in resource:
			
			# Adds slight variation between resources - prevents overlapping when released
			var target_pos = global_position
			if "swarm_offset" in resource:
				target_pos += resource.swarm_offset
			
			var distance = global_position.distance_to(resource.global_position)
			
			if resource.claim_frame != current_frame or distance < resource.claim_distance:
				resource.claimed_by = self
				resource.claim_frame = current_frame
				resource.claim_distance = distance
			
			if self != resource.claimed_by:
				continue
			
			
			# Calculate the direction towards the satellite
			var current_velocity = resource.direction * resource.speed
			var pull_direction = (target_pos - resource.global_position).normalized()
			var desired_velocity = pull_direction * my_collection_speed
			
			# Smoothly moves the vector, even through 0- naturally reversing it.
			var new_velocity = current_velocity.lerp(desired_velocity, my_gravity_strength * delta)
			
			# Smoothly increase or decrease its speed to match the satellite's pull
			resource.speed = new_velocity.length()
			
			if resource.speed > 0.01: # CRITICAL Prevents divide by 0 error
				# Smoothly bends the resource's current flying direction toward the satellite
				resource.direction = new_velocity.normalized()



# Mask is set to 4, meaning 'area' is guaranteed to be a Resource
func _on_collection_area_entered(resource: Area2D) -> void: 
	game.add_resource(resource.value)
	resource.despawn()
