extends Area2D


# - Autoloads -
@onready var game := Game_Manager
@onready var wave := WaveManager

# - Scene Nodes -
@onready var sprite : Sprite2D = $Sprite2D

# - Preloads -
const RESOURCE_SCENE = preload("uid://b8itoghsjeal8")
const DAMAGE_NUMBER = preload("uid://c7hnus72cghp0")
const DEATH_PARTICLES = preload("uid://f7ms6af6m58t")
const HIT_PARTICLES = preload("uid://y4r8isaruwon")


# - Debugging -
var damage_msgs : bool = false
# -

# - Properties -
# For Status Effect application
const DATA = "data"
const MAGNITUDE = "magnitude"
const REMAINING = "remaining"
const TICK_CLOCK = "tick_clock"

# Logs the origin of the effect and its properties
# source_key -> { DATA: StatusEffectData, MAGNITUDE: float, REMAINING: float, TICK_CLOCK: float }
var status_effects : Dictionary = {}
# Logs the effect and how much resistance
# effect : value (i.e. {"slow": 0.25} means 25% resistance to slowness)
var resistances : Dictionary = {}

var hit_flash_tween : Tween


# - Properties -
var planet : Area2D 			# Assigned at start()
var data : AsteroidData		# ^
var damage : float = 3
var max_health : float
var health : float
var is_dead : bool = false	# Prevents double death bug

# - Sprite Animation -
var anim_sprite : bool = false 		# If comet, animates sprite
var frame_count : int = 8			# Total frames of animation
var frame_interval : float = 0.1	# Time between frame change

# - Drops -
var is_golden : bool = false

var resource_min : int = 1
var resource_max : int = 3
var drop_weight : Dictionary[ResourceData.ResourceType, float] = {}

# - World Properties -
var rotation_speed : float = 0	# Random rotation : Purely visual
var direction : Vector2			
var speed : float 

# - Despawning -
@export var despawn_margin : float = 200.0
var despawn_dist : float
# -


var frame_clock : float


# Runs immediately after entering the scene tree | Called from asteroid_spawner.gd
# Sets up asteroid with all necessary data and properties
func start(asteroid_type : AsteroidData, target_planet: Area2D, start_pos: Vector2, speed_variance: float,\
 speed_multiplier: float = 1.0, health_multiplier: float = 1.0, damage_multiplier: float = 1.0,\
 debug_speed: bool = false, debug_speed_value: float = 200.0, damage_message_toggle: bool = false) -> void:
	
	# Assigns variable to chosen asteroid type
	data = asteroid_type	# CRITICAL : Needs to be at top.
	
	# Safety Net : If no asteroid_type was given, aborts.
	if not data:
		despawn()
		push_warning("No AsteroidData loaded. Asteroid aborted.")
		return
	
	# GOLDEN ASTEROID LOGIC
	if randf() < data.golden_spawn_chance: is_golden = true
	
	# Assigns variable to Planet, and position to determined spawn position
	planet = target_planet
	global_position = start_pos
	despawn_dist = start_pos.distance_to(planet.global_position) + despawn_margin
	
	# Adds Asteroid to 'Asteroids' group
	add_to_group("Asteroids")
	
	# Connects Planet collision signal, if not already connected
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	
	
	###################################################################
	#  - Assigns properties based on attached AsteroidData resource - #
	
	if damage_message_toggle:
		damage_msgs = damage_message_toggle
	
	# SPEED
	if debug_speed == true:		# If debug mode on, sets debug speed
		speed = debug_speed_value
	else: 
		# Assigns speed based on set speed × variance and wave's speed multiplier
		speed = data.max_speed * (1.0 + speed_variance) * speed_multiplier
		if speed < 5 or speed > 1000:
			push_warning(" [WARNING] Asteroid '%s' as type '%s' spawned at implausible speed: %.1f" % [self, data.name, speed])
	
	# HEALTH
	max_health = data.max_health * health_multiplier
	health = max_health
	
	# DAMAGE
	damage = data.damage * damage_multiplier
	
	
	# - For Debugging
	print_rich("	[color=yellow][DEBUG][/color] Asteroid type: '%s' spawned with:
	Health %.2f | (base %.1f × %.2f)
	Speed: %.2f | (base %.1f ±%.0f%% × %.2f)
	Damage: %.2f | (base %.1f × %.2f)" % 
	[data.name, 
	health, data.max_health, health_multiplier, 
	speed, data.max_speed, data.speed_variance*100, speed_multiplier, 
	damage, data.damage, damage_multiplier])
	# -
	
	# GOLDEN ASTEROID LOGIC
	if is_golden:
		resource_min = data.golden_min_resources
		resource_max = data.golden_max_resources
		drop_weight = data.golden_drop_weights.duplicate()
		sprite.set_instance_shader_parameter("tint_strength", data.golden_tint_strength)
		
	# DROP RESOURCES
	else:
		resource_min = data.min_resources
		resource_max = data.max_resources
		drop_weight = data.drop_weights.duplicate()
		sprite.set_instance_shader_parameter("tint_strength", 0.0)
	
	# GOLDEN SHADER DEBUG
	print_rich("[color=gold] [GOLD] [/color] %s | mat: %d | local: %s | readback: '%s'" % [
		data.name,
		sprite.material.get_instance_id(),
		sprite.material.resource_local_to_scene,
		sprite.get_instance_shader_parameter("tint_strength"),
	])
	
	# RESISTANCES
	resistances =  data.resistances.duplicate()
	
	# Sets scale based on health and asteroid type's scale ratio
	scale = Vector2(data.scale_ratio, data.scale_ratio)
	
	# Determines flight path | Comet vs. Other Asteroids
	if data.behavior == AsteroidData.BehaviorType.COMET:
		# Comets fly straight past the screen, wihtout regard for the Planet
		# Picks a random vector moving roughly opposite
		var planet_pos = planet.global_position
		var to_center = (planet_pos - global_position).normalized()
		
		# Sets random direction to fly past screen
		direction = to_center.rotated(deg_to_rad(randf_range(-9,9))) # Slight angle variation
		rotation = direction.angle()	# Faces towards the direction it is going
		
		# Sets up sprite node for animation with comet sprite 
		# (HARDCODED, NEEDS REWORK LATER!)
		sprite.texture = data.get_random_texture()
		sprite.hframes = 8
		sprite.vframes = 1
		sprite.scale = Vector2.ONE * 1.5
		sprite.offset = Vector2(-17, 0)
		anim_sprite = true
		
	else:
		# Sets direciton towards the Planet
		rotation_speed = randf_range(-0.8, 0.8)	# Random rotation
		direction = (planet.global_position - global_position).normalized()
		sprite.texture = data.get_random_texture()
		sprite.scale = Vector2.ONE * data.sprite_scale
	



	# Displays current Asteroid's info : name, pos, and speed
	print(" - Spawned: ", data.name , " at: ", global_position, " | Golden: ", is_golden,
	"\nSpeed: ", speed, " | Scale: ", scale, "\n | Sprite Size: ", sprite.texture.get_size(), " | Health: ", health)
	
	#																	#
	#####################################################################


func _physics_process(delta: float) -> void:
	if is_dead: return
	
	_tick_effects(delta)	# ticks status effects
	
	# Applies Slowness effect if there is one
	var scaled_delta = delta * (1.0 - get_modifier(EffectIDs.TIME_SCALE))
	
	# Produces movement and rotation
	global_position += direction * speed * scaled_delta
	rotation += rotation_speed * scaled_delta
	
	# Animates sprite if comet
	if anim_sprite:
		frame_clock += delta
		if frame_clock >= frame_interval:
			frame_clock -= frame_interval
			sprite.frame = (sprite.frame + 1) % frame_count
	
	# Checks and despawns asteroid if off-screen by spawned position and despawn_margin amount
	var current_dist = planet.global_position.distance_to(global_position)
	if despawn_dist < current_dist:
		print(self, " despawned | Too far off screen")
		wave.asteroid_death()
		despawn()

# Counts down effects duration and deals PERIODIC Effects damage
func _tick_effects(delta: float) -> void:
	# .keys() creates a copy, so erasing is safe mid-loop
	for key in status_effects.keys():
		var effect = status_effects[key]	# A reference, not a copy
		
		# Counts down duration | if remaining <= 0 then it is permanent until remove_effect()
		if effect[REMAINING] > 0.0:
			effect[REMAINING] -= delta
			if effect[REMAINING] <= 0.0:
				status_effects.erase(key)
				continue
		
		# Fires periodic damage based on tick_interval (for burn, acid, etc.)
		if effect[DATA].family == StatusEffectsData.EffectsFamily.PERIODIC:
			effect[TICK_CLOCK] += delta
			if effect[TICK_CLOCK] >= effect[DATA].tick_interval:
				effect[TICK_CLOCK] -= effect[DATA].tick_interval
				take_damage(effect[MAGNITUDE], false)

# Applies (stores) status effect in Dictionary with resource values | Calculates local resistance
func apply_effect(source_key: String, effect_data:StatusEffectsData, magnitude: float, duration: float = -1.0) -> void:
	
	var resisted = magnitude * (1.0 - get_resistance(effect_data.id))
	status_effects[source_key] = {
		DATA: effect_data,
		MAGNITUDE: resisted,
		REMAINING: duration,
		TICK_CLOCK: 0.0,
	}

# Removes selected status effect from asteroid
func remove_effect(source_key: String) -> void:
	status_effects.erase(source_key)

# Retrieves resistance value for specified effect
func get_resistance(id: String) -> float:
	return resistances.get(id, 0.0)

# ONLY For MODIFIER effects | Returns a 0-1 reduction fraction; consumer applies (1.0 - result)
func get_modifier(stat_id: String) -> float:
	var strongest : float = 0.0
	for key in status_effects:
		var effect = status_effects[key]
		if effect[DATA].family == StatusEffectsData.EffectsFamily.MODIFIER\
		and effect[DATA].target_stat == stat_id:
			strongest = maxf(strongest, effect[MAGNITUDE])
	
	return strongest

# Processes collision damage to Planet and destroys asteroid
func _on_area_entered(body: Area2D) -> void:
	
	# Safety Net : Aborts if collision is not the Planet or asteroid is freed
	if body != planet or is_dead:
		return
	else:
		StatsManager.increment(CounterIDs.ASTEROIDS_MISSED)
		game.take_damage(damage)	# Runs function in Game_Manager, tracking Planet shield
		wave.asteroid_death()		# Runs function in WaveManager, tracking asteroid death
		despawn()				# Deletes this instance

# Processes damage from Defenses
func take_damage(amount: float, particles: bool = true): 
	
	if is_dead: return
	
	# Increments Stat StatsManager
	StatsManager.increment(CounterIDs.DAMAGE_DEALT, minf(amount, health))
	health = maxf(health - amount, 0.0) 	# Clamps health to 0.0 min
	print(" Asteroid hit! Damage taken: %.1f | Current Health: %.1f" % [amount, health])
	
	# Hit Flash - Visual Effect
	# Kills pre-existing hit-flash before starting a new one
	if hit_flash_tween and hit_flash_tween.is_valid(): hit_flash_tween.kill()
	sprite.modulate = Color(4,4,4)
	hit_flash_tween = create_tween()
	hit_flash_tween.tween_property(sprite, "modulate", Color(1,1,1), 0.1)
	
	# Emits damage number upon hit
	var damage_node = DAMAGE_NUMBER.instantiate()
	get_tree().current_scene.add_child(damage_node)
	damage_node.start(amount, global_position)
	if damage_msgs:
		print("[DEBUG] Damage Number triggered | Displays: %.1f" % amount)
	
	# Emits particles upon hit
	if particles:
		var hit_particles = HIT_PARTICLES.instantiate()
		get_tree().current_scene.call_deferred("add_child", hit_particles)
		hit_particles.call_deferred("start", direction, global_position)
	
	if health <= 0.01:
		die()

# Destroys asteroid (from death by Defenses), dropping
# assigned amount of resources and tells WaveManager
func die():
	_spawn_resources()
	
	# Emits particles upon death
	var particles = DEATH_PARTICLES.instantiate()
	get_tree().current_scene.call_deferred("add_child", particles)
	particles.call_deferred("start", direction, global_position)
	
	StatsManager.increment(CounterIDs.ASTEROIDS_DESTROYED)
	wave.asteroid_death()	# Runs function in WaveManager, tracking asteroid death
	despawn()	# Deletes this instance

# Queues the asteroid to despawn
func despawn() -> void:
	is_dead = true	# Prevents double death bug
	queue_free()

# Randomly chooses an amount based on the min-max drop amount * drop mult, then spawns that amount
func _spawn_resources() -> void:
	
	# Stochastic rounding instead of integer rounding. Increases chance to round up based on drop_mult
	var drop_mult : float = Game_Manager.active_stats[StatIDs.GLOBAL][StatIDs.DROP_AMOUNT]
	var exact : float = randi_range(resource_min, resource_max) * drop_mult 
	var randamount : int = floori(exact)
	if randf() < (exact - randamount):
		randamount += 1
	
	for i in randamount:
		
		if RESOURCE_SCENE == null: 
			push_warning("		asteroid.gd: _spawn_resources(): RESOURCE_SCENE preload is null. Cannot spawn any resources.")
			break
			
		var r_data = _get_next_resource()
		if r_data == null: continue
		
		var r = RESOURCE_SCENE.instantiate()
		get_tree().current_scene.call_deferred("add_child", r)
		r.call_deferred("initialize", r_data, global_position)

# Chooses random resource that is able to spawn this round
func _get_next_resource() -> ResourceData:
	
	if game.all_resource_types.is_empty(): 
		push_warning("asteroid.gd: _get_next_resource: all_resource_types is empty | Cannot spawn any resources")
		return null
	
	# Build array and weight variable to get pool of resources and their weight
	var eligible : Array[ResourceData] = []
	var weights : Array[float] = []
	var total_weight : float = 0.0
	
	# For each available resource, checks unlocks to see if it CAN spawn this
	for resource in game.all_resource_types:
		if resource.unlock_id != "" and not game.is_feature_unlocked(resource.unlock_id):	# Skips if not unlocked and not grey
			continue
		
		# If passes criteria, adds resource to the array
		var resource_weight = drop_weight.get(resource.resource_type, resource.base_weight)
		if resource_weight <= 0.0: continue
		weights.append(resource_weight)
		eligible.append(resource)
		
		
		total_weight += resource_weight	# Adds it's spawn weight to the total_weight value
		
	#print(" 			total weight: ", total_weight)
	if eligible.is_empty(): return null
	var roll : float = randf_range(0,total_weight) # Randomizes number based on weight
	
	# Subtracts each eligible resource's weight by the random number.
	# If the resource's weight causes the number to go below or 
	# reaches 0, then THAT resource is returned (chosen to be spawned)
	for i in eligible.size():
		roll -= weights[i]
		if roll <= 0:
			return eligible[i]
	
	return eligible.back() # Safety fallback in case of floating point
