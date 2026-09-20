extends Area2D


@onready var timer: Timer = $DespawnTimer

@export var despawn_time : int = 90 # seconds

var speed := randf_range(20,50)					# Sets random speed
var direction : Vector2
var rotation_speed : float = randf_range(-4,4)	# Sets random rotation speed

var swarm_offset : Vector2


func start() -> void:
	
	timer.start(despawn_time)
	
	direction = Vector2(randf_range(-1,1),randf_range(-1,1))		# Sets a random direction
	#print("Resource spawned | Position: ", global_position, " | Direction: ", direction)
	
	swarm_offset = Vector2(randf_range(-5,5),randf_range(-5,5))	# Sets a random offset when clustered
	


func _process(delta: float) -> void:
	# Produces movement and rotation
	global_position += direction * speed * delta
	rotation += rotation_speed * delta


func _on_timer_timeout() -> void:
	print("Resource despawned : Timed out")
	despawn()


func despawn() -> void:
	queue_free()
