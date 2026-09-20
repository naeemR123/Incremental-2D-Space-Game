extends Resource
class_name UpgradeData


enum ScalingType { ADDITIVE, MULTIPLICATIVE } 

#############################
# -= PROPERTY ASSIGNMENT =- #
#############################

@export var id: String = "e.g. 'fire_rate'" 							# A unique name used by Game_Manager (e.g. fire_rate)
@export var display_name: String = "e.g. 'Turret Satelitte Fire Rate'"	# The name displayed for players
@export var target_category: String = "e.g. 'turret_satellite'"			# Tells the game WHERE to apply this upgrade
@export_multiline var description: String = "What this upgrade does..."

@export_category("Economy")
@export var base_cost: int = 1
@export var cost_multiplier: float = 1.00

@export_category("Effect")
@export var base_value: float	# !!! Exported value in Inspector doesn't do anything : Auto-syncs with defense's base stat
@export var val_up_per_level: float
@export var scaling_type: ScalingType = ScalingType.ADDITIVE	# Determines whether base_value is increased using a formula that adds or multiplies

# State variables (Not exported; dynamic during gameplay)
var current_level: int = 1




#################
# - Functions - #
#################


func get_current_cost() -> int:
	return int(base_cost * pow(cost_multiplier, current_level - 1))


func get_current_value(level: float = current_level) -> float:
	
	# Uses matching formula to selected scaling_type then uses val_up_per_level as the value increase
	match scaling_type:
		
		ScalingType.ADDITIVE:
			return base_value + (val_up_per_level * (level - 1))
		ScalingType.MULTIPLICATIVE:
			return base_value * pow(val_up_per_level, level - 1)
		
		# If no acceptable scaling_type selected, pushes warning and returns base_value
		_:
			push_warning("Unknown scaling_type on UpgradeData: %s" % id)
			return base_value


func level_up() -> void:
	current_level += 1


func reset() -> void:
	current_level = 1
	
