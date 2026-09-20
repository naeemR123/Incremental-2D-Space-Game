extends Node2D



@onready var debris_node: GPUParticles2D = $DebrisParticles

@onready var debris_material: ParticleProcessMaterial = debris_node.process_material.duplicate()


func _ready() -> void:
	debris_node.process_material = debris_material


func start(dir: Vector2, pos: Vector2) -> void:
	# Converts direction from Vector2 to Vector3
	var vec3_direction : Vector3 = Vector3(dir.x, dir.y, 0)
	
	debris_material.direction = vec3_direction
	debris_node.global_position = pos
	debris_node.emitting = true
	debris_node.finished.connect(_despawn)


func _despawn() -> void:
	# For Debugging
	#print(" --- particles despawned")
	queue_free()
