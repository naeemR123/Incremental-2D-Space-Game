extends Resource
class_name DefenseData



#############################
# -= PROPERTY ASSIGNMENT =- #
#############################


@export var id: String 					# A unique name used by Game_Manager (e.g. turret_satellite)
@export var display_name : String			# The name displayed for players (e.g. Turret)
@export_multiline var description : String = "What does this defense do..."

@export_category("Spawning")
@export var defense_scene : PackedScene	# The actual scene to instance (e.g. turret.tscn)
@export var max_allowed : int  = 10000		# Max amount player can purchase. Leave at 10,000 if unlimited

@export_category("Economy")
@export var base_cost : int
@export var cost_multiplier : float = 1.5

@export_category("Stats")
@export var default_stats : Dictionary = {}


# State variables (Dynamic: saved during gameplay)
var is_unlocked: bool = false
var amount_owned: int = 0



#################
# - Functions - #
#################


func get_current_cost() -> int:
	return int(base_cost * pow(cost_multiplier, amount_owned))
