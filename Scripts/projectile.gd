extends Area2D


# Despawning
@onready var screen_size : Vector2 = get_viewport_rect().size
var despawn_margin : float = 200

@export var speed : float = 400.0
var direction: Vector2
var damage : float


func start(start_pos: Vector2, target_pos: Vector2, damage_stat: float) -> void:
	damage = damage_stat
	global_position = start_pos
	direction = (target_pos - start_pos).normalized()
	
	
	# Points the projectile in the direction it is flying
	rotation = direction.angle()
	

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	
		# Checks and despawns projectile is off-screen by 'despawn_margin' amount
	if \
	global_position.x < -despawn_margin or \
	global_position.x > screen_size.x + despawn_margin or \
	global_position.y < -despawn_margin or \
	global_position.y > screen_size.y + despawn_margin:
		#print("Projectile despawned : Too far off screen")
		_despawn()


# If hits asteroid, then applies damage and despawns
func _on_area_entered(asteroid: Area2D) -> void:
	# Destorys asteroid, then destroys self
	asteroid.take_damage(damage)
	_despawn()


func _despawn() -> void:
	queue_free()
