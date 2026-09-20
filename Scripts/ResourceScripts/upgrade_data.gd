extends Resource
class_name UpgradeData


#############################
# -= PROPERTY ASSIGNMENT =- #
#############################

@export var id: String = "upgrad_id" 		# A unique name used by Game_Manager (e.g. fire_rate)
@export var display_name: String = "Upgrade Name"	# The name displayed for players
@export var target_category: String			# Tells the game WHERE to apply this upgrade
@export_multiline var description: String = "What this upgrade does..."

@export_category("Economy")
@export var base_cost: int = 10
@export var cost_multiplier: float = 1.15

@export_category("Effect")
@export var base_value: float = 1.0
@export var val_up_per_level: float = 0.2

# State variables (Not exported; dynamic during gameplay)
var current_level: int = 1




#################
# - Functions - #
#################

func get_current_cost() -> int:
	return int(base_cost * pow(cost_multiplier, current_level))
	

func get_current_value() -> float:
	return base_value + (val_up_per_level * (current_level - 1))
	

func level_up() -> void:
	current_level += 1

func reset() -> void:
	current_level = 1
