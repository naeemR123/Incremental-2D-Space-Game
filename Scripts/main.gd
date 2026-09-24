@tool
extends Node2D


@onready var game := Game_Manager
@onready var wave := WaveManager
@onready var save := SaveManager
@onready var asteroid_spawner : Marker2D = $AsteroidSpawner
@onready var planet := get_tree().get_first_node_in_group("Planet")


@export_category("Debug")

## If enabled, forces new game save
@export var new_game: bool = false

@export_group("Waves")

@export var custom_wave: bool = false:
	set(value):
		custom_wave = value
		notify_property_list_changed()
@export var wave_number: int = 1

@export var custom_boss_wave : bool = false:
	set(value):
		custom_boss_wave = value
		notify_property_list_changed()
@export var bwave_number : int = 3

@export_group("Stats")

@export var extra_resources: bool = false:
	set(value):
		extra_resources = value
		notify_property_list_changed()
@export var extra_amount: int = 500

@export var custom_shield: bool = false:
	set(value):
		custom_shield = value
		notify_property_list_changed()
@export var shield_amount: int = 100

@export_group("Asteroids")
## Specifically toggles debug messages appearing in [code]Output[/code] that are related to the [code]damage number[/code] effect when hitting asteroids
@export var damage_number_toggle : bool = false

@export var custom_asteroid_speed : bool = false:
	set(value):
		custom_asteroid_speed = value
		notify_property_list_changed()
@export var custom_asteroid_speed_value : float = 200
@export_group("")

@export_category("Gameplay")
## Player will spawn with this amount on Wave 1
@export var starting_resources : int = 15



func _ready() -> void:
	
	# [CRITICAL] : DO NOT REMOVE FROM START OF FUNCTION
	if Engine.is_editor_hint(): return

	game.reset_game.connect(func(): new_game = true)
	
	# Checks if save file exists and loads if so
	# If new game is selected, then skips to new game branch
	var sd : SaveData = save.load_game()
	if sd and (not new_game or not OS.is_debug_build()):
		# Save Game Branch
		print(" -- [MAIN] Game Save Found")

		save.apply_save_data(sd)	
	else:
		# New Game Branch
		print(" -- [MAIN] New Game Starting")
		
		StatsManager.increment(CounterIDs.RUNS_STARTED)
		print(" | INCREMENTED RUNS STARTED STAT | ")

		# Starting resources for new player
		game.add_resource(starting_resources)
		planet.sync_shield_to_max()	# Pulls value set for max shield in active_stats
		new_game = false
	
	if OS.is_debug_build(): debug_setup()	# DO NOT REMOVE FROM END OF FUNCTION


# [Strictly for DEBUGGING] Sets properties to be HIDDEN in Inspector
# -
# Rebuilds property dictionary fresh every time it is run, 
# so no need to add else statement for default effect.
func _validate_property(property: Dictionary) -> void:
	
	if property.name == "wave_number" and not custom_wave:
		property.usage = PROPERTY_USAGE_NO_EDITOR
		
	if property.name == "bwave_number" and not custom_boss_wave:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	
	if property.name == "extra_amount" and not extra_resources:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	
	if property.name == "shield_amount" and not custom_shield:
		property.usage = PROPERTY_USAGE_NO_EDITOR

	if property.name == "custom_asteroid_speed_value" and not custom_asteroid_speed:
		property.usage = PROPERTY_USAGE_NO_EDITOR


func debug_setup() -> void:
	if custom_wave:
		wave.current_wave = wave_number
		print_rich("[color=yellow][b][DEBUG][/b][/color] Custom Wave Debug: ENABLED | Wave set to: %d" % wave.current_wave)
	
	# Sets next boss wave to exported debug value
	if custom_boss_wave:
		wave.next_boss_wave = bwave_number
		print_rich("[color=yellow][b][DEBUG][/b][/color] Boss Wave Debug: ENABLED | Boss Wave set to: Wave %d" % wave.next_boss_wave)
	
	if extra_resources:
		game.add_resource(extra_amount)
		print_rich("[color=yellow][b][DEBUG][/b][/color] Extra Resources Debug: ENABLED | Added %d resources" % extra_amount)
	
	if custom_shield:
		Game_Manager.active_stats[StatIDs.PLANET][StatIDs.MAX_SHIELD] = shield_amount
		planet.sync_shield_to_max()
		print_rich("[color=yellow][b][DEBUG][/b][/color] Custom Shield Debug: ENABLED \
		| Max Planet Shield now set to %d" % [Game_Manager.active_stats[StatIDs.PLANET][StatIDs.MAX_SHIELD]])
	
	if custom_asteroid_speed:
		asteroid_spawner.custom_asteroid_speed = true
		asteroid_spawner.custom_asteroid_speed_value = custom_asteroid_speed_value
		print_rich("[color=yellow][b][DEBUG][/b][/color] Asteroid Speed Debug: ENABLED | Asteroid Speed set to: %.1f" % custom_asteroid_speed_value)
	
	if damage_number_toggle:
		asteroid_spawner.damage_number_toggle = true
		print_rich("[color=yellow][b][DEBUG][/b][/color] Output Damage Message Toggle: ENABLED")
	else:
		asteroid_spawner.damage_number_toggle = false
