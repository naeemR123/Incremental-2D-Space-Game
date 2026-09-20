@tool
extends Node2D


@onready var game := Game_Manager
@onready var wave := WaveManager
@onready var asteroid_spawner: Marker2D = $AsteroidSpawner


@export_category("Debug")
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

@export_group("Global Stats")

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

@export var damage_number_toggle : bool = false

@export var custom_asteroid_speed : bool = false:
	set(value):
		custom_asteroid_speed = value
		notify_property_list_changed()
@export var custom_asteroid_speed_value : float = 200

@export_group("")

func _ready() -> void:
	
	# [CRITICAL] : DO NOT REMOVE FROM TOP OF FUNCTION
	if Engine.is_editor_hint():
		return
	
	
	if custom_wave:
		wave.current_wave = wave_number
		print("[DEBUG] Custom Wave Debug: ENABLED | Wave set to: %d" % wave.current_wave)
	
	# Sets next boss wave to exported debug value
	if custom_boss_wave:
		wave.next_boss_wave = bwave_number
		print("[DEBUG] Boss Wave Debug: ENABLED | Boss Wave set to: Wave %d" % wave.next_boss_wave)
	else:
		# Prints Default Boss Wave value at game start
		print("[DEBUG] Boss Wave Debug: DISABLED | Boss Wave Randomly set to: Wave %d" % wave.next_boss_wave)
	
	if extra_resources:
		game.add_resource(extra_amount)
		print("[DEBUG] Extra Resources Debug: ENABLED | Added %d resources" % extra_amount)
	
	if custom_shield:
		game.active_stats["global"]["planet_shield"] = shield_amount
		game.max_planet_shield = shield_amount
		print("[DEBUG] Custom Shield Debug: ENABLED | Added %d shield , Set max_planet_shield to %d" % [shield_amount, game.max_planet_shield])
	
	if custom_asteroid_speed:
		asteroid_spawner.custom_asteroid_speed = true
		asteroid_spawner.custom_asteroid_speed_value = custom_asteroid_speed_value
		print("[DEBUG] Asteroid Speed Debug: ENABLED | Asteroid Speed set to: %.1f" % custom_asteroid_speed_value)
	
	if damage_number_toggle:
		asteroid_spawner.damage_number_toggle = true
		print("[DEBUG] Output Damage Message Toggle: ENABLED")
	else:
		asteroid_spawner.damage_number_toggle = false

	
	
	
	game.add_resource(15)


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
