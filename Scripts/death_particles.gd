extends Node2D



@onready var debris_node: GPUParticles2D = $DebrisParticles
@onready var countdeb_node: GPUParticles2D = $CounterDebrisParticles
@onready var spark_node: GPUParticles2D = $SparkParticles
@onready var chunk_node: GPUParticles2D = $ChunkParticles

@onready var debris_material: ParticleProcessMaterial = debris_node.process_material.duplicate()
@onready var countdeb_material: ParticleProcessMaterial = countdeb_node.process_material.duplicate()
@onready var spark_material: ParticleProcessMaterial = spark_node.process_material.duplicate()
@onready var chunk_material: ParticleProcessMaterial = chunk_node.process_material.duplicate()



func _ready() -> void:
	debris_node.process_material = debris_material
	countdeb_node.process_material = countdeb_material
	spark_node.process_material = spark_material
	chunk_node.process_material = chunk_material


func start(dir: Vector2, pos: Vector2) -> void:
	# Converts direction from Vector2 to Vector3
	var vec3_direction : Vector3 = Vector3(dir.x, dir.y, 0)
	# For Debugging
	#print(" --- vec3 direction reading as: " , vec3_direction)
	countdeb_material.direction = -vec3_direction
	debris_material.direction = vec3_direction
	# For Debugging
	#print(" --- debris_material.direction reading as: " , debris_material.direction)
	spark_material.direction = vec3_direction
	chunk_material.direction = vec3_direction
	
	countdeb_node.global_position = pos
	debris_node.global_position = pos
	spark_node.global_position = pos
	chunk_node.global_position = pos
	
	countdeb_node.emitting = true
	debris_node.emitting = true
	spark_node.emitting = true
	chunk_node.emitting = true
	
	chunk_node.finished.connect(_despawn)


func _despawn() -> void:
	# For Debugging
	#print(" --- particles despawned")
	queue_free()
