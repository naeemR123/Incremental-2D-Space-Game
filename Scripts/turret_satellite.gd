extends Node2D

@onready var game := Game_Manager


const PROJECTILE_SCENE = preload("uid://dp2nh1twswdbk")


@onready var sensor : Area2D = $Range
@onready var turret_range : CollisionShape2D = $Range/CollisionShape2D
@onready var muzzle : Marker2D = $Muzzle
@onready var firerate : Timer = $Firerate
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var range_indicator: Line2D = $RangeIndicator
@onready var preview_range_indicator: Line2D = $PreviewRangeIndicator

@export_group("Range Preview")
@export var preview_blink_duration : float = 1.0
@export var preview_blink_min_alpha : float = 0.0
@export var preview_blink_max_alpha : float = 0.50

var preview_blink_tween : Tween

# - Stat Properties -
var my_id : String
var my_damage : float = 1.5
var my_proj_speed : float = 300.0
var my_range : float = 250
var my_turn_speed : float = 10
var my_firerate : float = 2.4
var my_projectile_color : Color = Color(2.0, 2.0, 0.5)
# -

var can_shoot : bool = true


func initialize(data: SatelliteData):	# Runs right after instantiation, driven by GameManager
	my_id = data.id
	my_turn_speed = data.turn_speed
	my_projectile_color = data.projectile_color

func _ready() -> void:		# Runs after initialize()
	turret_range.shape = turret_range.shape.duplicate()
	
	firerate.timeout.connect(_on_firerate_timeout)
	game.stats_changed.connect(update_satellite_stats)
	update_satellite_stats()
	
	# Randomizes animation speed of sprite
	sprite.sprite_frames.set_animation_speed("default", randf_range(7,9))


func update_satellite_stats():
	my_firerate = game.active_stats[my_id][StatIDs.FIRE_RATE]
	my_damage = game.active_stats[my_id][StatIDs.DAMAGE]
	my_proj_speed = game.active_stats[my_id][StatIDs.PROJ_SPEED]
	my_range = game.active_stats[my_id][StatIDs.RANGE]
	turret_range.shape.radius = my_range
	range_indicator.points = _build_range_circle(my_range)


func _process(delta: float) -> void:
	# Sets the nearest asteroid as the target
	var target = get_nearest_asteroid()
	if target != null:
		# Makes the turret visually face the target
		var target_angle = global_position.direction_to(target.global_position).angle()
		global_rotation = lerp_angle(global_rotation, target_angle, my_turn_speed * delta)
		
		if can_shoot:
			#print("[DEBUG] Turret Satellite can_shoot: true")
			shoot(target)
			firerate.start(my_firerate)

# Builds an Array of points that create a circle | Called via update_satellite_stats()
func _build_range_circle(radius: float, segments: int = 48) -> PackedVector2Array:
	var points = PackedVector2Array()
	for i in segments:
		var angle = TAU * i/segments
		points.append(Vector2(cos(angle),sin(angle)) * radius)
	return points

# Sets preview range_indicator's visibility
func set_range_visible(can_see: bool) -> void:
	range_indicator.visible = can_see


func set_preview_range_visible(can_see: bool, preview_radius: float = 0.0) -> void:
	preview_range_indicator.visible = can_see
	
	if can_see:
		preview_range_indicator.points = _build_range_circle(preview_radius)
		preview_blink_tween = create_tween()
		preview_blink_tween.set_loops()
		preview_blink_tween.tween_property(preview_range_indicator, "modulate:a", preview_blink_min_alpha, preview_blink_duration)
		preview_blink_tween.tween_property(preview_range_indicator, "modulate:a", preview_blink_max_alpha, preview_blink_duration)


func _on_firerate_timeout() -> void:
	can_shoot = true


func get_nearest_asteroid() -> Area2D:
	
	# Grab all areas currently inside the Range's collision circle
	var asteroids_in_range = sensor.get_overlapping_areas()
	if asteroids_in_range.is_empty(): 
		return null
	
	var nearest_asteroid: Area2D = null
	var shortest_distance: float = INF  # INF stands for infinity
	
	# Loops through asteroids and finds which one is closest to the turret
	for asteroid in asteroids_in_range:
		var distance = global_position.distance_to(asteroid.global_position)
		if distance < shortest_distance:
			shortest_distance = distance
			nearest_asteroid = asteroid
	
	return nearest_asteroid


func shoot(target: Area2D) -> void:
	if PROJECTILE_SCENE == null: 
		print("[ERROR] No Projectile Scene loaded in Turret Satellite")
		return
	
	var proj = PROJECTILE_SCENE.instantiate()
	# CRITICAL Adds projectiles to the main scene so they don't inherit the turret's rotation
	get_tree().current_scene.add_child(proj)
	
	# Initialize the projectile
	proj.start(muzzle.global_position, target.global_position, my_damage, my_proj_speed, my_projectile_color)
	can_shoot = false
	#print("[DEBUG] Turret Satellite can_shoot: false")
