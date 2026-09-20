extends Node



# - Difficulty Scaling Constants -

const SCALING_END_WAVE : float = 100	# Wave number scaling stops at, All multipliers sync | Written as float for logic, actually an int

const MAX_SPEED_SCALE : float = 2.2 	# Max speed mult at scaling end wave
const SPEED_CURVE : float = 0.7			# How fast scaling happens: < 1 = early-game ramp-up, > 1 = late-game ramp-up

const DAMAGE_X2_WAVE : float = 25		# Wave number this stat doubles in value: 13 means at Wave 14 Damage is 200% base value
const HEALTH_X2_WAVE : float = 20		# ^^^ wave values are integers

const INTERVAL_CURVE : float = 0.6		# How fast scaling happens: < 1 = early-game ramp-up, > 1 = late-game ramp-up
const MIN_SPAWN_INTERVAL : float = 0.50	# Lowest amount in seconds between each asteroid spawn
# -


# Holds data for all asteroid resources from "res://Scripts/Resources/Asteroids/"
# Populated via register_all_asteroids()
var all_asteroids : Array[AsteroidData] = []

# Wave Properties
var current_wave : int = 1
var wave_active : bool
var next_boss_wave : int = randi_range(15, 20)
var is_boss_wave : bool = false

var max_spawn_interval : float = 7	# seconds

var max_asteroids : int
var asteroids_spawned : int = 0
var asteroids_alive : int


# Signals
signal timer_interval(interval)		# connects to asteroid_spawner.gd
signal wave_complete()				# connects to ui.gd



func _ready() -> void:
	register_all_asteroids()	# CRITICAL : needs to run on game startup


## Scans the Asteroids folder and registers stats for every AsteroidData it find
func register_all_asteroids() -> void:
	ResourceScanner.register_folder("res://Scripts/Resources/Asteroids/", AsteroidData, register_asteroids_stats, "ASTEROIDS")


## Checks 'all_asteroids' for resource , if not found, adds it
func register_asteroids_stats(asteroid: AsteroidData) -> void:
	# Safe for multiple calls : won't overwrite if entry exists
	if not all_asteroids.has(asteroid):
		# Appends the AsteroidData resource to the array
		all_asteroids.append(asteroid)

## Returns float from 0-1 based on current wave and SCALING_END_WAVE
func wave_progress(wave: int = current_wave) -> float:
	# Interpolates a value between 0-1 based on current wave and specified scaling end wave
	var weight : float = (wave - 1) / (SCALING_END_WAVE - 1)	# Generates 0-1
	return clampf(weight, 0.0, 1.0)

## For determining speed mult, returns float from 1 to MAX_SPEED_SCALE based on ramp set by SPEED_CURVE
func speed_multiplier(wave: int = current_wave) -> float:
	var progress : float = wave_progress(wave)
	var scale_curve : float = pow(progress, SPEED_CURVE)
	return lerpf(1.0, MAX_SPEED_SCALE, scale_curve)

## For determining health mult, returns float: determined by current_wave and HEALTH_X2_WAVE
func health_multiplier(wave: int = current_wave) -> float:
	return pow(2.0, (wave - 1) / HEALTH_X2_WAVE)

## For determining damage mult, returns float: determined by current_wave and DAMAGE_X2_WAVE
func damage_multiplier(wave: int = current_wave) -> float:
	return pow(2.0, (wave - 1) / DAMAGE_X2_WAVE)



## Initiates logic for the next wave
func start_wave() -> void:
	
	print("~ WAVE %d STARTED" % current_wave)
	
	# Resets wave properties to default
	wave_active = true
	is_boss_wave = false
	asteroids_spawned = 0
	asteroids_alive = 0
	
	if next_boss_wave == current_wave:
		boss_wave()
		next_boss_wave = current_wave + randi_range(15, 20)
		return
	
	# Calculates asteroid amound and their spawn interval based on the current wave number
	max_asteroids = clampi(3 + (current_wave * 2), 1, 180)
	var spawn_interval : float = lerpf(max_spawn_interval, MIN_SPAWN_INTERVAL, pow(wave_progress(current_wave), INTERVAL_CURVE))
	# Debug print
	print_rich("[color=orange] [DEBUG] [/color]: Spawn interval set. Current Wave: '%d' | Spawn Interval set to '%.2f' \
	with the Cap being '%.2f'" % [current_wave, spawn_interval, MIN_SPAWN_INTERVAL])
	
	# Sends the spawn timer interval to the asteroid spawner
	timer_interval.emit(spawn_interval)


## Used by the asteroid spawner 
## Runs pick_asteroid_type and returns chosen asteroid type
func get_next_asteroid() -> AsteroidData:
	
	# If the max amount of asteroids has been reached, the function is aborted
	if asteroids_spawned >= max_asteroids:
		return null # Tells spawner (timer) to stop
	
	# Returns BOSS Asteroid if boss wave is active
	if is_boss_wave:
		return get_boss_asteroid(current_wave)
	
	# Returns value back to asteroid spawner
	return pick_asteroid_type(current_wave)

## Searches 'all_asteroids' Array for BOSS Asteroids | Returns Boss Asteroid
func get_boss_asteroid(wave: int) -> AsteroidData:
	
	# Safety check : aborts if there is no asteroids in 'all_asteroids' array
	if all_asteroids.is_empty():
		push_warning("Cannot choose Asteroid to spawn: No Asteroids registered (from: wave_manager.gd/get_boss_asteroid | Array 'all_asteroids' is empty)")
		return null
	
	# Build array and weight variable to get pool of asteroids and their weight
	var eligible : Array[AsteroidData] = []
	var weights : Array[float] = []
	var total_weight : float = 0
	
	# For each available asteroid, checks it is a BOSS and if it CAN spawn this wave 
	for asteroid in all_asteroids:
		if asteroid.min_wave <= wave and asteroid.behavior == AsteroidData.BehaviorType.BOSS:
			
			var asteroid_weight = asteroid.get_spawn_weight(wave)
			# If passes criteria, adds asteroid to the array and 
			# adds it's spawn weight to the weight array and total_weight value
			eligible.append(asteroid)
			weights.append(asteroid_weight)
			
			total_weight += asteroid_weight
	
	# Safety check : aborts if there is no BOSS Asteroid found in 'eligible' array
	if eligible.is_empty():
		push_warning("Cannot find Boss Asteroid to spawn: No Asteroids eligible (from: wave_manager.gd/get_boss_asteroid | Array 'eligible' is empty)")
		return null
	
	# Safety check : aborts if there is no values found in 'weights' array
	if weights.is_empty():
		push_warning("Cannot choose Asteroid to spawn: No weights considered (from: wave_manager.gd/get_boss_asteroid | Array 'weight' is empty)")
		return null
	
	var roll : float = randf_range(0,total_weight) # Randomizes number based on weight
	
	# Subtracts each eligible asteroid's weight by the random number.
	# If the asteroid's weight causes the number to go below or 
	# reaches 0, then THAT asteroid is returned (chosen to be spawned)
	for i in eligible.size():
		roll -= weights[i]
		if roll <= 0:
			return eligible[i]
	
	return eligible.back() # Safety fallback in case of floating point

## Chooses an asteroid to spawn based on minimum wave and spawn weight (chance)
func pick_asteroid_type(wave: int) -> AsteroidData:
	# Safety check : aborts if there is no asteroids in 'all_asteroids' array
	if all_asteroids.is_empty():
		push_warning("Cannot choose Asteroid to spawn: No Asteroids registered (from: wave_manager.gd/pick_asteroid_type | Array 'all_asteroids' is empty)")
		return null
	
	# Build array and weight variable to get pool of asteroids and their weight
	var eligible : Array[AsteroidData] = []
	var weights : Array[float] = []
	var total_weight : float = 0
	
	# For each available asteroid, checks if it CAN spawn this wave and isn't a boss
	for asteroid in all_asteroids:
		if asteroid.min_wave <= wave and asteroid.behavior != AsteroidData.BehaviorType.BOSS:
			
			var asteroid_weight = asteroid.get_spawn_weight(wave)
			# If passes criteria, adds asteroid to the array and 
			# adds it's spawn weight to the weight array and total_weight value
			eligible.append(asteroid)
			weights.append(asteroid_weight)
			
			total_weight += asteroid_weight
	
	# Safety check : aborts if there is no asteroids in 'eligible' array
	if eligible.is_empty():
		push_warning("Cannot choose Asteroid to spawn: No Asteroids eligible (from: wave_manager.gd/pick_asteroid_type | Array 'eligible' is empty)")
		return null
	
	# Safety check : aborts if there is no values in 'weights' array
	if weights.is_empty():
		push_warning("Cannot choose Asteroid to spawn: No weights considered (from: wave_manager.gd/pick_asteroid_type | Array 'weights' is empty)")
		return null
	
	var roll : float = randf_range(0,total_weight) # Randomizes number based on weight
	
	# Subtracts each eligible asteroid's weight by the random number.
	# If the asteroid's weight causes the number to go below or 
	# reaches 0, then THAT asteroid is returned (chosen to be spawned)
	for i in eligible.size():
		roll -= weights[i]
		if roll <= 0:
			return eligible[i]
	
	return eligible.back() # Safety fallback in case of floating point

## Calculates how many asteroids are allowed to spawn
## Called via asteroid_spawner.gd
func register_spawns(count: int) -> int:
	var allowed : int = mini(count, max_asteroids - asteroids_spawned)
	if allowed <= 0:
		return 0
	asteroids_spawned += allowed
	asteroids_alive += allowed
	return allowed

## Tracks how many asteroids are still active
## Ends the wave if conditions are met
func asteroid_death() -> void:
	
	if not wave_active: return
	
	asteroids_alive -= 1
	print(" ~ %d Asteroids Remaining" % (max_asteroids - asteroids_spawned + asteroids_alive))
	
	# If there are no more asteroids alive and all 
	# asteroids have been spawned, then the wave ends
	if asteroids_alive <= 0 and asteroids_spawned >= max_asteroids:
		print("~ WAVE %d ENDED | WAVE %d NEXT" % [current_wave,current_wave+1])
		
		if Game_Manager.planet_destroyed: return
		StatsManager.increment(CounterIDs.WAVES_SURVIVED)
		StatsManager.record_max(CounterIDs.HIGHEST_WAVE, current_wave)
		
		wave_active = false
		current_wave += 1
		wave_complete.emit()

## Initiates boss wave
func boss_wave() -> void:
	is_boss_wave = true
	max_asteroids = 1
	timer_interval.emit(max_spawn_interval)


## Resets Wave info | Called via game_reset() in Game_Manager
func reset() -> void:
	current_wave = 1
	next_boss_wave = randi_range(15, 20)
	wave_active = false
	is_boss_wave = false
	
	print(" | WAVE INFO RESET | ")
