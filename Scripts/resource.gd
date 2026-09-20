extends Area2D


# - Scene Nodes -
@onready var sprite: Sprite2D = $Sprite2D
@onready var light: PointLight2D = $PointLight2D
@onready var planet : Node = get_tree().get_first_node_in_group("Planet")

# - Despawning -
@onready var timer: Timer = $DespawnTimer

@export_category("Despawn")
@export var despawn_time : int = 60 # seconds
@export var despawn_margin : float = 2000.0

@export_group("Despawn Blink")
## Amount of seconds left that triggers blinking
@export var blink_threshold : float = 10.0 # seconds
## How long it transitions
@export var blink_duration : float = 0.50 # seconds
## How transparent the sprite gets during a blink
@export var blink_opacity : float = 0.15
## Time between transitions
@export var blink_interval : float = 3.0

var is_blinking : bool = false
var blink_tween : Tween
# -

# - Properties -
var my_data : ResourceData
var value : int

var speed := randf_range(20,50)					# Sets random speed
var direction : Vector2
var rotation_speed : float = randf_range(-4,4)	# Sets random rotation speed
# -

# - Claiming behavior -
var claimed_by : Node = null
var claim_frame : int = -1
var claim_distance : float = INF
# -

var swarm_offset_val : int = 8
var swarm_offset : Vector2



func initialize(data: ResourceData, pos: Vector2) -> void:
	my_data = data
	value = data.value
	sprite.texture = data.get_random_texture()
	sprite.material.set_shader_parameter("phase_offset", randf())
	
	if data.glow:
		light.enabled = data.glow
		light.color = data.glow_color
	
	global_position = pos
	direction = Vector2(randf_range(-1,1),randf_range(-1,1))		# Sets a random direction
	#print("Resource spawned | Position: ", global_position, " | Direction: ", direction)
	
	# Sets a random offset when clustered
	swarm_offset = Vector2(randf_range(-swarm_offset_val,swarm_offset_val),randf_range(-swarm_offset_val,swarm_offset_val))

	timer.start(despawn_time)


func _process(delta: float) -> void:
	# Produces movement and rotation
	global_position += direction * speed * delta
	rotation += rotation_speed * delta
	
	
	
	if global_position.distance_to(planet.global_position) > despawn_margin:
		print("Resource despawned : Too far off screen")
		despawn()
		return
	
	if not is_blinking and timer.time_left < blink_threshold: _despawn_blink()
	
	if is_blinking and blink_tween.is_valid():
		if timer.time_left > blink_threshold/3:
			blink_tween.set_speed_scale(1.0)
		elif timer.time_left > blink_threshold/10:
			blink_tween.set_speed_scale(3.0)
		else:
			blink_tween.set_speed_scale(5.0)


func _despawn_blink() -> void:
	is_blinking = true
	blink_tween = create_tween()
	blink_tween.set_loops()
	#var duration : float = timer.wait_time/10
	blink_tween.tween_property(sprite, "modulate:a", blink_opacity, blink_duration)
	blink_tween.tween_property(light, "energy", 0.0, blink_duration)
	blink_tween.tween_interval(blink_interval/2)
	blink_tween.tween_property(sprite, "modulate:a", 1.0, blink_duration)
	blink_tween.tween_property(light, "energy", 1.0, blink_duration)
	blink_tween.tween_interval(blink_interval)


func _on_timer_timeout() -> void:
	print("Resource despawned : Timed out")
	despawn()


func despawn() -> void:
	queue_free()
