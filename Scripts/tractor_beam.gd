extends Area2D

@onready var game := Game_Manager

@export var pull_speed: float = 150.0
@export var pull_strength: float = 10

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	# Makes the radius of the collision shape 60% of the width of the sprite
	var spriteradius = sprite.texture.get_size()
	collision.shape.radius = ( spriteradius.x / 1.67)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)



func _process(_delta: float) -> void:
	# Tracks tractor beam to mouse lcoation
	global_position = get_global_mouse_position()
	
	# When Left Click is held, sprite at 50% opacity- otherwise 0%
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		sprite.modulate.a = 0.5
	else:
		sprite.modulate.a = 0


func _physics_process(delta: float) -> void:
	var is_clicking : bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	
	# When Left Click is held, enables collisions
	collision.disabled = !is_clicking
	
	if is_clicking:
		collect_resources(delta)
		

func collect_resources(delta: float) -> void:
	
	var caught_resources = get_overlapping_areas()
	
	for resource in caught_resources:
		if !resource.is_in_group("Resource"):
			continue
		if "speed" in resource and "direction" in resource:
			var current_velocity = resource.direction * resource.speed
			
			# Adds slight variation between resources - prevents overlapping when released
			var target_pos = global_position
			if "swarm_offset" in resource:
				target_pos += resource.swarm_offset
				
			# Calculate the direction towards the satellite
			var pull_direction = (target_pos - resource.global_position).normalized()
			var desired_velocity = pull_direction * pull_speed
			
			# Smoothly moves the vector, even through 0- naturally reversing it.
			var new_velocity = current_velocity.lerp(desired_velocity, pull_strength * delta)
			
			# Smoothly increase or decrease its speed to match the satellite's pull
			resource.speed = new_velocity.length()
			
			if resource.speed > 0.01: # CRITICAL Prevents divide by 0 error
				# Smoothly bends the resource's current flying direction toward the satellite
				resource.direction = (new_velocity).normalized()


#  - Controls SLOW-DOWN mechanic for asteroids - #
func _on_area_entered(area: Area2D):
	if area.is_in_group("Asteroids"):
		area.local_time_scale = game.active_stats["global"]["slow_down_amount"]

func _on_area_exited(area: Area2D):
	if area.is_in_group("Asteroids"):
		area.local_time_scale = 1.0
