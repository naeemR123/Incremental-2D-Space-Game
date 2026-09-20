extends Node





# This Dictionary holds the CURRENT value of ALL upgrade stats including defenses, planet, and cursor
# Defense categories get added dynamically via register_defense_stats()
var active_stats: Dictionary = {
	"global": {
			"slow_down_amount": 1.00,
			"planet_shield": 10.0,
	},
}


var resources :int = 0
var planet_destroyed : bool = false
var owned_defenses: Array[String] = []
var all_upgrades : Array[UpgradeData] = []
var max_planet_shield: float = 10.0

# Signals
signal stats_changed()
signal resources_changed()
signal shield_changed()
signal game_over()


#################
# - Functions - #
#################


func _ready() -> void:
	register_all_defenses()
	register_all_upgrades()


# Scans the Defenses folder and registers stats for every DefenseData it finds
func register_all_defenses() -> void:
	
	# Routes acces to Defenses Resource folder, and returns if there is no folder
	var dir = DirAccess.open("res://Scripts/Resources/Defenses/")
	if dir == null:
		push_error("Could not open Defenses resource folder")
		return
	
	dir.list_dir_begin() # Start iterating over folder contents
	var file_name = dir.get_next()
	
	# Loops while there are non-blank files
	while file_name != "":
		# Only processes .tres files, skipping other file types
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			# Creates a file path with the specific resource file
			var path = "res://Scripts/Resources/Defenses/" + file_name
			var resource = load(path)	# Loads that path
			
			# Safety check: makes sure it is a DefenseData Resource
			if resource is DefenseData:
				register_defense_stats(resource)	# Upon success, runs function to register it
			else:
				push_warning("Unexpected resource type in Defenses folder: " + path)
			
		file_name = dir.get_next()
		
	dir.list_dir_end()	# CRITICAL : always needs to be called when done iterating


# Checks 'default_stats' for resource.id , if not found, duplicates it under it's id
func register_defense_stats(defense: DefenseData) -> void:
	# Safe for multiple calls : won't overwrite if entry exists
	if not active_stats.has(defense.id):
		# Duplicates to store an independant copy, instead of referencing the original
		active_stats[defense.id] = defense.default_stats.duplicate()


# Scans the Upgrades folder and registers stats for every UpgradeData it finds
# Almost identical to register_all_defenses()
func register_all_upgrades() -> void:
	
	var dir = DirAccess.open("res://Scripts/Resources/Upgrades/")
	if dir == null:
		push_error("Could not open Upgrades resource folder")
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var path = "res://Scripts/Resources/Upgrades/" + file_name
			var resource = load(path)
			
			if resource is UpgradeData:
				register_upgrade_array(resource)
			else:
				push_warning("Unexpected resource type in Upgrades folder: " + path)
			
		file_name = dir.get_next()
	
	dir.list_dir_end()	# CRITICAL 


# Checks 'all_upgrades' for resource , if not found, references it
func register_upgrade_array(upgrade: UpgradeData) -> void:
	
	if not all_upgrades.has(upgrade):
		
		all_upgrades.append(upgrade)


func add_resource(amount: int):		# Adds resource to inventory and updates ui
	resources += amount
	resources_changed.emit()


func purchase_defenses(defense: DefenseData) -> bool:		# Purchase function for Defenses

	var cost = defense.get_current_cost()
	
	if resources >= cost and defense.amount_owned < defense.max_allowed:
		resources -= cost
		defense.amount_owned += 1
		defense.is_unlocked = true
		
		owned_defenses.append(defense.id)
		
		# Register stats the first time it is purchased
		register_defense_stats(defense)
		
		var new_defense = defense.defense_scene.instantiate()
		if new_defense.has_method("initialize"):
			new_defense.initialize(defense)
		
		get_tree().current_scene.add_child(new_defense)
		
		resources_changed.emit()
		return true # Purchase successful
	return false # Purchase unsuccessful : not enough resources or max amount owned


func purchase_upgrade(upgrade: UpgradeData) -> bool:		# Purchase function for Upgrades

	var cost = upgrade.get_current_cost()
	
	if resources >= cost:
		resources -= cost
		upgrade.level_up()
		
		# Update the dictionary using the UpgradeData's ID
		if active_stats.has(upgrade.target_category):
			active_stats[upgrade.target_category][upgrade.id] = upgrade.get_current_value()
		else:
			# Pushes if upgrade's target_category doesn't exist - meaning the category was never registered, or it is incorrect
			push_warning("purchase_upgrade: target_category '%s' not found in active_stats. Was it registered correctly?" % upgrade.target_category)
		
		resources_changed.emit()
		stats_changed.emit()
		return true # Purchase successful
	return false # Purchase unsuccessful : not enough resources


func take_damage(damage_val: float):
	if planet_destroyed:
		return
	
	active_stats["global"]["planet_shield"] -= damage_val
	if active_stats["global"]["planet_shield"] < 0:
		active_stats["global"]["planet_shield"] = 0
	
	shield_changed.emit()
	
	if active_stats["global"]["planet_shield"] == 0:
		trigger_game_over()


func trigger_game_over():
	planet_destroyed = true
	game_over.emit()
	get_tree().paused = true


func game_reset():		# Reset function for "Try Again?" Button
	resources = 0
	planet_destroyed = false
	owned_defenses.clear()
	
	active_stats["global"]["slow_down_amount"] = 0.75
	active_stats["global"]["planet_shield"] = max_planet_shield
	
	for upgrade in all_upgrades:
		upgrade.reset()
	
	for key in active_stats.keys():
		if key != "global":
			active_stats.erase(key)
	
	get_tree().paused = false
