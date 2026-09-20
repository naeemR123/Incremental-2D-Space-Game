extends Marker2D


@onready var wave := WaveManager

@onready var spawntimer: Timer = $SpawnCooldown
@onready var planet : Area2D = get_tree().get_first_node_in_group("Planet")


@export_category("Spawn Adjustments")
@export var margin: float = 50 # How far offscreen to spawn


var custom_asteroid_speed : bool
var custom_asteroid_speed_value : float
var damage_number_toggle : bool

var asteroid_scene: PackedScene = preload("uid://dy1a5mdt6iqir")


func _ready() -> void:
	wave.timer_interval.connect(timer_info)		# connects from WaveManager


# Recieves spawn interval from WaveManager and starts timer
func timer_info(interval : float) -> void:
	await get_tree().create_timer(3.0).timeout
	spawn_asteroid(wave.get_next_asteroid())
	spawntimer.start(interval)


# Runs get_next_asteroid() from WaveManager, then spawns that random type if eligible
func _on_spawn_cooldown_timeout() -> void:
	
	# Recieves a random asteroid type based on wave + asteroid type criteria
	var type = WaveManager.get_next_asteroid()
	
	# Will recieve null if max asteroids have been spawned, stops spawning if so
	if type == null:
		spawntimer.stop()
		return
	
	spawn_asteroid(type)


# Spawns asteroid in a random location off screen, then 
# passes asteroid type along and runs its start function
func spawn_asteroid(asteroid_type: AsteroidData) -> void:
	
	# Safety net : If no scene loaded then aborts with warning
	if asteroid_scene == null: 
		push_warning("Cannot spawn Asteroid: No scene loaded (from: asteroid_spawner/spawn_asteroid)")
		return
	
	# Gets size of screen
	var viewport_size = get_viewport_rect().size
	
	# Chooses random screen edge (0 = top, 1 = bottom, 2 = left, 3 = right)
	var edge : int = randi() % 4 # <- chooses random number between 0 and 3
	var spawn_position : Vector2
	
	# Matches randomly chosen number to screen edge with spawn margin
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
	
	# Instance the asteroid scene
	var asteroid = asteroid_scene.instantiate()
	
	# CRITICAL : Add to the main scene, NOT the Marker2D spawner.
	# This prevents the asteroid from inheriting the spawner's transform.
	get_tree().current_scene.add_child(asteroid)
	
	print("Asteroid spawned")
	
	var speed_multiplier : float = 0.1 * wave.current_wave
	
	# Run asteroid's start function, passing important parameter values
	asteroid.start(asteroid_type, planet, spawn_position, custom_asteroid_speed, custom_asteroid_speed_value, speed_multiplier, damage_number_toggle)
	
