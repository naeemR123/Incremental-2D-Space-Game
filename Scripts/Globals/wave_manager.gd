extends Node



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


# Scans the Asteroids folder and registers stats for every AsteroidData it find
func register_all_asteroids() -> void:
	
	# Routes access to Asteroids Resource folder, and returns if there is no folder
	var dir = DirAccess.open("res://Scripts/Resources/Asteroids/")
	if dir == null:
		push_error("Could not open Asteroids resource folder")
		return
	
	dir.list_dir_begin() # Start iterating over folder contents
	var file_name = dir.get_next()
	
	# Loops while there are non-blank files
	while file_name != "":
		# Only processes .tres files, skipping other file types
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			# Creates a file path with the specific resource file
			var path = "res://Scripts/Resources/Asteroids/" + file_name
			var resource = load(path)	# Loads that path
			
			# Safety check: makes sure it is a AsteroidData Resource
			if resource is AsteroidData:
				register_asteroids_stats(resource)	# Upon success, runs function to register it
			else:
				push_warning("Unexpected resource type in Asteroids folder: " + path)
			
		file_name = dir.get_next()
		
	dir.list_dir_end()	# CRITICAL : always needs to be called when done iterating


# Checks 'all_asteroids' for resource , if not found, adds it
func register_asteroids_stats(asteroid: AsteroidData) -> void:
	# Safe for multiple calls : won't overwrite if entry exists
	if not all_asteroids.has(asteroid):
		# Appends the AsteroidData resource to the array
		all_asteroids.append(asteroid)


# Chooses an asteroid to spawn based on minimum wave and spawn weight (chance)
func pick_asteroid_type(wave: int) -> AsteroidData:
	# Safety check : aborts if there is no asteroids in 'all_asteroids' array
	if all_asteroids.is_empty():
		push_warning("Cannot choose Asteroid to spawn: No Asteroids registered (from: wave_manager.gd/pick_asteroid_type | Array 'all_asteroids' is empty)")
		asteroid_death()
		return null
	
	# Build array and weight variable to get pool of asteroids and their weight
	var eligible : Array[AsteroidData] = []
	var total_weight : float = 0
	
	# For each available asteroid, checks if it CAN spawn this wave and isn't a boss
	for asteroid in all_asteroids:
		if asteroid.min_wave <= wave and asteroid.behavior != AsteroidData.BehaviorType.BOSS:
			
			# If passes criteria, adds asteroid to the array and 
			# adds it's spawn weight to the total_weight value
			eligible.append(asteroid)
			total_weight += asteroid.spawn_weight
	
	# Safety check : aborts if there is no asteroids in 'eligible' array
	if eligible.is_empty():
		push_warning("Cannot choose Asteroid to spawn: No Asteroids eligible (from: wave_manager.gd/pick_asteroid_type | Array 'eligible' is empty)")
		asteroid_death()
		return null
	
	var roll : float = randf_range(0,total_weight) # Randomizes number based on weight
	
	# Subtracts each eligible asteroid's weight by the random number.
	# If the asteroid's weight causes the number to go below or 
	# reaches 0, then THAT asteroid is returned (chosen to be spawned)
	for asteroid in eligible:
		roll -= asteroid.spawn_weight
		if roll <= 0:
			return asteroid
	
	return eligible.back() # Safety fallback in case of floating point


# Initiates logic for the next wave
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
	
	# Calculates asteroid amound and their spawn interval
	# based on the current wave number
	max_asteroids = 3 + (current_wave * 2)
	var spawn_interval : float = clampf(max_spawn_interval - (0.1 * current_wave),0.4, max_spawn_interval)
	
	# Sends the spawn timer interval to the asteroid spawner
	timer_interval.emit(spawn_interval)


# Used by the asteroid spawner 
# Runs pick_asteroid_type and returns chosen asteroid type
func get_next_asteroid() -> AsteroidData:
	
	# If the max amount of asteroids has been reached, the function is aborted
	if asteroids_spawned >= max_asteroids:
		return null # Tells spawner (timer) to stop
	
	# Keeps track of how many asteroids are produced
	asteroids_spawned += 1
	asteroids_alive += 1
	
	# Returns BOSS Asteroid if boss wave is active
	if is_boss_wave:
		return get_boss_asteroid(current_wave)
	
	# Returns value back to asteroid spawner
	return pick_asteroid_type(current_wave)


# Searches 'all_asteroids' Array for BOSS Asteroids | Returns Boss Asteroid
func get_boss_asteroid(wave: int) -> AsteroidData:
	
	# Safety check : aborts if there is no asteroids in 'all_asteroids' array
	if all_asteroids.is_empty():
		push_warning("Cannot choose Asteroid to spawn: No Asteroids registered (from: wave_manager.gd/get_boss_asteroid | Array 'all_asteroids' is empty)")
		asteroid_death()
		return null
	
	# Build array and weight variable to get pool of asteroids and their weight
	var eligible : Array[AsteroidData] = []
	var total_weight : float = 0
	
	
	# For each available asteroid, checks it is a BOSS and if it CAN spawn this wave 
	for asteroid in all_asteroids:
		if asteroid.min_wave <= wave and asteroid.behavior == AsteroidData.BehaviorType.BOSS:
			
			# If passes criteria, adds asteroid to the array and 
			# adds it's spawn weight to the total_weight value
			eligible.append(asteroid)
			total_weight += asteroid.spawn_weight
	
	# Safety check : aborts if there is no BOSS Asteroid found in 'eligible' array
	if eligible.is_empty():
		push_warning("Cannot find Boss Asteroid to spawn: No Asteroids eligible (from: wave_manager.gd/get_boss_asteroid | Array 'eligible' is empty)")
		asteroid_death()
		return null
	
	var roll : float = randf_range(0,total_weight) # Randomizes number based on weight
	
	# Subtracts each eligible asteroid's weight by the random number.
	# If the asteroid's weight causes the number to go below or 
	# reaches 0, then THAT asteroid is returned (chosen to be spawned)
	for asteroid in eligible:
		roll -= asteroid.spawn_weight
		if roll <= 0:
			return asteroid
	
	return eligible.back() # Safety fallback in case of floating point


# Tracks how many asteroids are still active
# Ends the wave if conditions are met
func asteroid_death() -> void:
	asteroids_alive -= 1
	print(" ~ %d Asteroids Remaining" % (max_asteroids - asteroids_spawned + asteroids_alive))
	
	# If there are no more asteroids alive and all 
	# asteroids have been spawned, then the wave ends
	if asteroids_alive <= 0 and asteroids_spawned == max_asteroids:
		print("~ WAVE %d ENDED | WAVE %d NEXT" % [current_wave,current_wave+1])
		wave_active = false
		current_wave += 1
		wave_complete.emit()


func boss_wave() -> void:
	is_boss_wave = true
	max_asteroids = 1
	timer_interval.emit(max_spawn_interval)


# Resets Wave info | Called via game_reset() in Game_Manager
func reset() -> void:
	current_wave = 1
	next_boss_wave = randi_range(15, 20)
	wave_active = false
	is_boss_wave = false
	
	print(" | WAVE INFO RESET | ")
