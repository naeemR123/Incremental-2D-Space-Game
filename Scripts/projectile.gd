extends Area2D

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


func _on_area_entered(asteroid: Area2D) -> void:
	# Destorys asteroid, then destroys self
	asteroid.take_damage(damage)
	queue_free()
