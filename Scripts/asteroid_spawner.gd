extends Marker2D


const ASTEROID_SCENE : PackedScene = preload("uid://dy1a5mdt6iqir")

@onready var wave := WaveManager


@onready var spawntimer: Timer = $SpawnCooldown
@onready var planet : Area2D = get_tree().get_first_node_in_group("Planet")

@export_category("Spawn Adjustments")
## Pixels
@export var radius: float = 2120 # pixels
## Degrees. Randomized offset per spawn along the radius. Ex: 7 = ±7 degrees around the chosen spawn position
@export var angle_jitter: float = 7 # degrees
## Pixels. Randomized offset per spawn off the radius. Ex: 50 = ±50 pixels off the radius
@export var radial_jitter: float = 90 # pixels

var custom_asteroid_speed : bool
var custom_asteroid_speed_value : float
var damage_number_toggle : bool



func _ready() -> void:
	wave.timer_interval.connect(timer_info)		# connects from WaveManager
	spawntimer.timeout.connect(spawn_next)		# connects timer's timeout

## Recieves spawn interval from WaveManager and starts timer
func timer_info(interval : float) -> void:
	await get_tree().create_timer(2.0).timeout	# Controls initial wave start time
	
	spawn_next()	# Spawns asteroids
	spawntimer.start(interval)	# Starts timer with wave-based spawnrate

## Spawns that random asteroid type if eligible
func spawn_next() -> void:
	# Recieves a random asteroid type based on wave + asteroid type criteria
	var type := wave.get_next_asteroid()
	if type == null:	# Will recieve null if max asteroids have been spawned, stops spawning if so
		spawntimer.stop()
		return
	
	var allowed : int = wave.register_spawns(type.get_group_size(wave.current_wave))
	if allowed <= 0:
		spawntimer.stop()
		return
	
	var angle = randf() * TAU
	var speed_variance = randf_range(-type.speed_variance, type.speed_variance)
	for i in allowed:
		spawn_asteroid(type, speed_variance, angle)

## Spawns asteroid(s) in a random location off screen, then 
## passes asteroid type along and runs its start function
func spawn_asteroid(asteroid_type: AsteroidData, speed_variance: float = 0, angle: float = -1.0) -> void:
	
	# Safety net : If no scene loaded then aborts with warning
	if ASTEROID_SCENE == null: 
		push_warning("Cannot spawn Asteroid: No scene loaded (from: asteroid_spawner/spawn_asteroid)")
		return
	
	# If no angle assigned, creates its own
	if angle < 0:
		angle = randf() * TAU
	
	# Random offset to determined spawn, for group spawning behavior
	var ang_jitter : float = angle + deg_to_rad(randf_range(-angle_jitter, angle_jitter))
	var rad_jitter : float = radius + randf_range(-radial_jitter, radial_jitter)
	var spawn_position : Vector2 = planet.global_position + Vector2.from_angle(ang_jitter) * rad_jitter
	
	# Instance the asteroid scene
	var asteroid = ASTEROID_SCENE.instantiate()
	
	# CRITICAL : Add to the main scene, NOT the Marker2D spawner.
	# This prevents the asteroid from inheriting the spawner's transform.
	get_tree().current_scene.add_child(asteroid)
	
	print("Asteroid spawned")
	
	var speed_mult : float = wave.speed_multiplier()
	var health_mult : float = wave.health_multiplier()
	var damage_mult : float = wave.damage_multiplier()
	
	# Run asteroid's start function, passing important parameter values
	asteroid.start(asteroid_type, planet, spawn_position, speed_variance,\
	 speed_mult, health_mult, damage_mult,\
	 custom_asteroid_speed, custom_asteroid_speed_value, damage_number_toggle, )
	
