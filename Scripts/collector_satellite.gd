extends Node2D


@onready var game := Game_Manager


@onready var satellite: Area2D = $Satellite
@onready var collection_zone: Area2D = $Satellite/CollectionZone
@onready var planet: Area2D = %Planet


var my_id : String
var my_orbit_radius : float = 150
var my_range : float = 100.0
var my_orbit_speed : float = 0.5
var my_collection_speed : float = 100
var my_collection_strength : float = 5

func initialize(data: SatelliteData):
	my_id = data.id
	my_orbit_radius = randf_range(data.orbit_radius - 20, data.orbit_radius + 20)
	
	# Randomizes starting angle so they don't all spawn at the exact same spot
	rotation = randf_range(0, TAU)		# TAU is 360 degrees in radians
	

func _ready() -> void:
	if planet == null:
		push_warning("No planet body found. ", self, " setup aborted.")
		return
	global_position = planet.global_position
	satellite.position.x = my_orbit_radius
	
	# Connects the Area2D signals via code
	collection_zone.area_entered.connect(_on_collection_area_entered)
	
	game.stats_changed.connect(update_satellite_stats)
	update_satellite_stats()


func update_satellite_stats():
	my_collection_speed = game.active_stats[my_id][StatIDs.SAT_COLLECTION_SPEED]
	my_collection_strength = game.active_stats[my_id][StatIDs.SAT_COLLECTION_STRENGTH]
	my_orbit_speed = game.active_stats[my_id][StatIDs.ORBIT_SPEED]
	my_range = game.active_stats[my_id][StatIDs.RANGE]

func _process(delta: float) -> void:
	
	# Rotates the pivot to make the satellite orbit
	rotation += my_orbit_speed * delta


func _physics_process(delta: float) -> void:
	var caught_resources = satellite.get_overlapping_areas()
	
	for resource in caught_resources:
		
		if "speed" in resource and "direction" in resource:
			
			var current_velocity = resource.direction * resource.speed
			
			# Adds slight variation between resources - prevents overlapping when released
			var target_pos = satellite.global_position
			if "swarm_offset" in resource:
				target_pos += resource.swarm_offset
			
			# Calculate the direction towards the satellite
			var pull_direction = (target_pos - resource.global_position).normalized()
			var desired_velocity = pull_direction * my_collection_speed
			
			# Smoothly moves the vector, even through 0- naturally reversing it.
			var new_velocity = current_velocity.lerp(desired_velocity, my_collection_strength * delta)
			
			# Smoothly increase or decrease its speed to match the satellite's pull
			resource.speed = new_velocity.length()
			
			if resource.speed > 0.01: # CRITICAL Prevents divide by 0 error
				# Smoothly bends the resource's current flying direction toward the satellite
				resource.direction = new_velocity.normalized()



# Mask is set to 4, meaning 'area' is guaranteed to be a Resource
func _on_collection_area_entered(area: Area2D) -> void: 
	game.add_resource(1)
	area.queue_free()
