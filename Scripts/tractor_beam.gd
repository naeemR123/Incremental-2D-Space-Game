extends Area2D

@onready var game := Game_Manager

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var beam_circle: Sprite2D = $Polygon2D

const SLOW_EFFECT = preload("uid://b1hjfnwgatp5p")

@export var pull_speed: float = 150.0
@export var pull_strength: float = 10

@export_group("Visuals")
@export_range(0, 0.3, 0.01) var anim_speed : float = 0.1
@export_range(0, 5, 0.1) var rotation_speed : float = 0.5
@export_range(0, 5, 0.1) var rotation_offset : float = 1.0

var beam_size : float
var size_offset : float = 50
var current_frame: int = 0

func _ready() -> void:
	# Makes the radius of the collision shape 60% of the width of the sprite
	var sprite_radius = sprite.texture.get_size()
	collision.shape.radius = ( sprite_radius.x / 1.67)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	
	game.stats_changed.connect(update_stats)
	update_stats()


func update_stats() -> void:
	beam_size = game.active_stats[StatIDs.TRACTOR_BEAM][StatIDs.BEAM_SIZE]
	collision.shape.radius = beam_size
	
	var visual_size : float = beam_size * 2.5
	sprite.scale = Vector2.ONE * (visual_size / 128) 
	beam_circle.texture.set("width", visual_size + size_offset)
	beam_circle.texture.set("height", visual_size + size_offset)


func _process(delta: float) -> void:
	# Tracks tractor beam to mouse lcoation
	global_position = get_global_mouse_position()
	sprite.rotation += rotation_speed * delta
	


func _physics_process(delta: float) -> void:
	var is_clicking : bool = Input.is_action_pressed("LeftClick")
	
	
	# When Left Click is held, enables collisions
	collision.disabled = !is_clicking
	if is_clicking:
		collect_resources(delta)
	
	if Input.is_action_just_pressed("LeftClick"):
		_on_mouse_click(delta, true)
		rotation_speed += rotation_offset
	elif Input.is_action_just_released("LeftClick"):
		_on_mouse_click(delta, false)
		rotation_speed -= rotation_offset
		
		


func _on_mouse_click(_delta: float, is_clicking: bool = false) -> void:
	
	var tween = create_tween()
	tween.set_parallel()
	
	if is_clicking:
		tween.tween_property(beam_circle, "modulate:a", 0.2, 0.2)
		sprite.frame = 1
		#print("is_clicking: true | sprite: ", sprite.frame, " | delta: ", delta)
		await get_tree().create_timer(anim_speed).timeout
		sprite.frame = 2
		#print("is_clicking: true | sprite: ", sprite.frame, " | delta: ", delta)
	else:
		tween.tween_property(beam_circle, "modulate:a", 0, 0.2)
		sprite.frame = 3
		#print("is_clicking: false | sprite: ", sprite.frame, " | delta: ", delta)
		await get_tree().create_timer(anim_speed).timeout
		sprite.frame = 0
		#print("is_clicking: false | sprite: ", sprite.frame, " | delta: ", delta)

#  - Controls SLOW-DOWN mechanic for asteroids - #
func _on_area_entered(asteroid: Area2D):
	if asteroid.is_in_group("Asteroids"):
		var slow_strength = game.active_stats[StatIDs.TRACTOR_BEAM][StatIDs.SLOW_STRENGTH]
		asteroid.apply_effect(EffectIDs.TRACTOR_BEAM, SLOW_EFFECT, slow_strength)
		#print("[DEBUG] Asteroid in Tractor Beam | Current Slow Down Value: %.1f" % slow_strength)

func _on_area_exited(asteroid: Area2D):
	if asteroid.is_in_group("Asteroids"):
		asteroid.remove_effect(EffectIDs.TRACTOR_BEAM)


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

		
