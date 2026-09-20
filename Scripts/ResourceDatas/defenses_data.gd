extends Resource
class_name DefenseData


#############################
# -= PROPERTY ASSIGNMENT =- #
#############################

@export var id: String 					# A unique name used by Game_Manager (e.g. turret_satellite)
@export var display_name : String			# The name displayed for players (e.g. Turret)
@export_multiline var description : String = "What does this defense do..."

@export_category("Spawning")
@export var defense_scene : PackedScene		# The actual scene to instance (e.g. turret.tscn)
@export var max_allowed : int  = 10000		# Max amount player can purchase. Leave at 10,000 if unlimited

@export_category("Progression")
@export var unlock_wave : int = 1		# Which wave this defense unlocks for purhcase

@export_category("Economy")
@export var base_cost : int
@export var cost_multiplier : float = 1.5

@export_category("Stats")
@export var default_stats : Dictionary[String, float] = {}		# Populated via Inspector

# State variables (Dynamic: saved during gameplay)
var is_purchased: bool = false
var amount_owned: int = 0


# - Functions - #

func get_current_cost(owned: int = amount_owned) -> int:
	return int(base_cost * pow(cost_multiplier, owned)) 

func reset() -> void:
	is_purchased = false
	amount_owned = 0


func get_block_reason(resources: int = Game_Manager.resources, current_wave: int = WaveManager.current_wave) -> PurchaseBlock.Reason:
	if unlock_wave > current_wave:
		#print_rich(" [color=green][b][GAME][/b][/color] Purchase_defense: UNSUCCESSFUL | Unlock Wave not reached: '%s' unlock wave: " % [display_name, unlock_wave])
		return PurchaseBlock.Reason.LOCKED
	if amount_owned >= max_allowed:
		#print_rich(" [color=green][b][GAME][/b][/color] Puchase_defense: UNSUCCESSFUL | Max owned reached: '%s', max owned allowed: %d, currently own: %d" % [display_name, max_allowed, amount_owned])
		return PurchaseBlock.Reason.MAX_OWNED
	if resources < get_current_cost():
		#print_rich(" [color=green][b][GAME][/b][/color] Defense Purchase [u]UNSUCCESSFUL[/u] | Not Enought Resources: %s" % id)
		return PurchaseBlock.Reason.NOT_ENOUGH_RESOURCES
	return PurchaseBlock.Reason.NONE
