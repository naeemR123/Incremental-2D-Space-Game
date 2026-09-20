extends Area2D

@onready var game := Game_Manager

@export var data : AsteroidData

var resource_max : int = 3
var resource_min : int = 1

var damage : float = 3
var current_health: float
var local_time_scale : float = 1.0

var speed : float = randf_range(min_speed,max_speed)
var max_speed : float = 40
var min_speed : float = 15
var direction : Vector2

var rotation_speed : float = randf_range(-0.8,0.8)


@onready var sprite : Sprite2D = $Sprite2D
@onready var resource_scene : PackedScene = preload("res://Scenes/resource.tscn")

var planet: Area2D 

func start(target_planet: Area2D, start_pos: Vector2, debug_speed: bool = false, debug_speed_value: float = 200, speed_multiplier: float = 1, health_multiplier: float = 1) -> void:
	if not data:
		queue_free()
		return
		
	planet = target_planet
	global_position = start_pos
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	
	###################################################################
	#  - Assigns properties based on attached AsteroidData resource - #
	
	if debug_speed == true:
		speed = debug_speed_value
	else: 
		speed = randf_range(data.min_speed, data.max_speed) * speed_multiplier
		
	current_health = data.max_health * health_multiplier
	rotation_speed = randf_range(-0.8, 0.8)
	sprite.texture = data.sprite_texture
	
	scale = Vector2(data.max_health * data.scale_ratio, data.max_health * data.scale_ratio)
	
	# ++ Determines flight path based on assigned AI behavior
	if data.behavior == AsteroidData.BehaviorType.COMET:
		# Comets fly straight past the screen, avoiding the Planet. Picks a random vector moving roughly opposite
		var screen_center = get_viewport_rect().size/2
		var to_center = (screen_center - global_position).normalized()
		direction = to_center.rotated(randf_range(-0.5,0.5)) # Slight angle variation
		
	else:
		# Sets direciton of other Asteroids towards the Planet
		direction = (planet.global_position - global_position).normalized()
	
	#####################################################################
	
	print("Spawned: ", data.name , " at: ", global_position, " | Speed: ", speed)	# Displays current Asteroid's name, pos, and speed


func _physics_process(delta: float) -> void:
	# Produces movement and rotation
	global_position += direction * speed * local_time_scale * delta
	rotation += rotation_speed * local_time_scale * delta


func take_damage(amount: float): 
	current_health -= amount
	# Add hit-flash here
	if current_health <=0:
		die()


func _on_area_entered(body: Area2D) -> void:
	if body != planet:
		return
	else:
		game.take_damage(damage)
		queue_free()
		print("Planet hit")


func die():
	# Randomly chooses an amount based on the min and max values of resources, then spawns that amount
	var randamount = randi_range(data.min_resources, data.max_resources)
	for i in randamount:
		var resource = resource_scene.instantiate()
		resource.global_position = global_position
		get_tree().current_scene.call_deferred("add_child", resource)
		
	queue_free()
