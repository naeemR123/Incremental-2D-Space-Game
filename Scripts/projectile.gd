extends Area2D

@onready var sprite: Sprite2D = $Sprite2D

# Despawning
@onready var screen_size : Vector2 = get_viewport_rect().size
var despawn_margin : float = 500.0
var despawn_dist : float 
var despawn_dist_min : float

var origin : Vector2

var speed : float = 300.0
var direction: Vector2
var damage : float


func start(start_pos: Vector2, target_pos: Vector2, damage_stat: float, speed_stat: float = 300.0, color: Color = Color(1.0, 0.9, 0.5)) -> void:
	damage = damage_stat
	speed = speed_stat
	
	origin = start_pos
	
	global_position = start_pos
	direction = (target_pos - start_pos).normalized()
	rotation = direction.angle()	# Points the projectile in the direction it is flying
	
	# Sets despawn distance
	despawn_dist = start_pos.distance_to(target_pos) + despawn_margin
	# Sets minimum despawn distance : half screen size + margin
	despawn_dist_min = screen_size.x*2/3 + despawn_margin
	
	sprite.modulate = color
	#print("[DEBUG] Projectile fired")


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	
	# Checks how far projectile has traveled and despawns when reaches specified distance
	if origin.distance_to(global_position) > maxf(despawn_dist, despawn_dist_min):
		print("Projectile despawned : Too far off screen")
		_despawn()


# If hits asteroid, then applies damage and despawns
func _on_area_entered(asteroid: Area2D) -> void:
	# Destorys asteroid, then destroys self
	asteroid.take_damage(damage)
	_despawn()


func _despawn() -> void:
	queue_free()
