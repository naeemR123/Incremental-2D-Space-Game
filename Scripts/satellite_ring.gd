extends Node2D


@onready var game := Game_Manager


@onready var planet : Area2D = get_tree().get_first_node_in_group("Planet")


# Properties assigned based on satelitte-type
var my_id : String
var my_orbit_radius : float
var my_orbit_speed : float


func initialize(data: SatelliteData) -> void:
	my_id = data.id
	

func _ready() -> void:
	if planet == null:
		push_warning("No planet body found. ", self, " setup aborted.")
		return
	
	global_position = planet.global_position
	game.stats_changed.connect(update_stats)
	update_stats()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	# Rotates the pivot to make the child satellites orbit
	rotation += my_orbit_speed * delta


func update_stats() -> void:
	my_orbit_speed = game.active_stats[my_id][StatIDs.ORBIT_SPEED]
	my_orbit_radius = game.active_stats[my_id][StatIDs.ORBIT_RADIUS]


func redistribute() -> void:
	var children = get_children()
	var count = children.size()
	
	for i in count:
		var angle = TAU * i/count
		children[i].position = Vector2(my_orbit_radius, 0).rotated(angle)
