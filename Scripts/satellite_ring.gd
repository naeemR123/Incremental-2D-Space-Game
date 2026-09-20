extends Node2D


@onready var game := Game_Manager


@onready var planet : Area2D = get_tree().get_first_node_in_group("Planet")


@export var rotation_tween_speed : float = 2
@export var position_tween_speed : float = 2


# Properties assigned based on satelitte-type
var my_id : String
var my_orbit_radius : float
var my_orbit_speed : float



# - Functions -

# Runs before added to scene tree (before _ready)
func initialize(data: SatelliteData) -> void:
	my_id = data.id	# Assigns self to a Satellite type
	my_orbit_radius = data.orbit_radius

# Runs after initialize
func _ready() -> void:
	# Safety net for planet to avoid crash
	if planet == null:
		push_warning("No planet body found. ", self, " setup aborted.")
		return
	
	global_position = planet.global_position	# Centers on planet position
	game.stats_changed.connect(update_stats)	# Connected to Game_Manager
	update_stats()	# Assigns satellite orbit stats to property variables


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Rotates the pivot to make the child satellites orbit
	rotation += my_orbit_speed * delta


# Updates stats for properties
func update_stats() -> void:
	my_orbit_speed = game.active_stats[my_id][StatIDs.ORBIT_SPEED]


# Rearranges every satellite attached to this ring
func redistribute() -> void:
	var children = get_children()	# Puts every satellite (child) of this ring into an array
	var count = children.size()		# Asks for the amount of satelittes in that array
	children.sort_custom(func(a, b): return a.position.angle() < b.position.angle())
	
	var tween = create_tween()
	tween.set_parallel()
	
	# Applies the following code to every satellite in array
	#
	# Ex: count == 4 satellites: 
	# (2pi*0/4 ~= 0 degrees) child 0 to 0°, (2pi*1/4 ~= 90 degrees) child 1 to 90°,
	# (2pi*2/4 ~= 180 degrees) child 2 to 180°, (2pi*3/4 ~= 270 degrees) child 3 to 270°
	for i in count:
		
		var satellite = children[i]
		var is_new = satellite.position.is_equal_approx(Vector2.ZERO)
		
		# TAU == 2pi in radians | Dividing by the amount of total satellites divides it into slices
		# Applies orbit distance and angle to the current satellite via tween | .rotated() is to apply based on origin (this node)
		var target_angle = TAU*i/count	# Stores this result in angle
		var current_angle = satellite.position.angle()
		var new_angle = current_angle + angle_difference(current_angle, target_angle)
		
		var target_local_pos = Vector2(my_orbit_radius, 0).rotated(target_angle)
		var target_global_pos = to_global(target_local_pos)
		
		var target_rotation = planet.global_position.direction_to(target_global_pos).angle()
		var target_local_rotation = target_rotation - rotation
		var current_local_rotation = satellite.rotation
		var new_local_rotation = current_local_rotation + angle_difference(current_local_rotation, target_local_rotation)  
		# For Debugging
		#print(satellite.name, " target_rotation (deg): ", rad_to_deg(target_rotation))
		#print(satellite.name, " new_rotation (deg): ", rad_to_deg(new_rotation))
		
		tween.tween_property(satellite,"rotation", new_local_rotation, rotation_tween_speed).set_ease(Tween.EASE_IN_OUT)
		# For Debugging
		#tween.finished.connect(func(): print(satellite.name, " final global_rotation (deg): ", rad_to_deg(satellite.global_rotation)))
		
		if is_new:
			tween.tween_property(satellite, "position", target_local_pos, position_tween_speed).set_ease(Tween.EASE_IN_OUT)
		else:
			tween.tween_method(_set_orbit_position.bind(satellite), current_angle, new_angle, position_tween_speed).set_ease(Tween.EASE_IN_OUT)


func _set_orbit_position(angle: float, satellite: Node2D) -> void:
	if satellite.position != Vector2(my_orbit_radius, 0).rotated(angle):
		var tween = create_tween()
		tween.set_parallel()
		tween.tween_property(satellite, "position", Vector2(my_orbit_radius, 0).rotated(angle), position_tween_speed).set_ease(Tween.EASE_IN_OUT)
	
	
	
