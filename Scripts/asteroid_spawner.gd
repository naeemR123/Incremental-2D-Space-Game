extends Marker2D

@export var debug_speed : bool = false
@export var debug_speed_value : float = 200

@export var asteroid_scene: PackedScene
@export var spawn_interval: float = 2.0
@export var margin: float = 50.0 # How far offscreen to spawn

@onready var spawntimer: Timer = $SpawnCooldown
@onready var planet: Area2D = %Planet

func _ready() -> void:
	spawntimer.wait_time = spawn_interval
	spawntimer.start()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_spawn_cooldown_timeout() -> void:
	spawn_asteroid()
	


func spawn_asteroid() -> void:
	if asteroid_scene == null: return
		
	var viewport_size = get_viewport_rect().size
	
	# Chooses random screen edge (0 = top, 1 = bottom, 2 = left, 3 = right)
	var edge = randi() % 4 # <- chooses random number between 0 and 3
	var spawn_position : Vector2

	match edge:
		0: # Top edge
			spawn_position = Vector2(
				randf_range(0, viewport_size.x), 	# x value 
				-margin								# y value
				)
		1: # Bottom edge
			spawn_position = Vector2(
				randf_range(0, viewport_size.x), 	# x value 
				viewport_size.y + margin			# y value
				)
		2: # Left edge
			spawn_position = Vector2(
				-margin, 							# x value 
				randf_range(0, viewport_size.y)		# y value
				)
		3: # Right edge
			spawn_position = Vector2(
				viewport_size.x + margin, 			# x value 
				randf_range(0, viewport_size.y)		# y value
				)
	
	# Instance the asteroid, add it to the scene, and sets position
	var asteroid = asteroid_scene.instantiate()
	
	# CRITICAL FIX: Add to the main scene, NOT the Marker2D spawner.
	# This prevents the asteroid from inheriting the spawner's transform.
	get_tree().current_scene.add_child(asteroid)
	print("Asteroid spawned")
	
	asteroid.start(planet, spawn_position, debug_speed, debug_speed_value, )
	
		
	
	
