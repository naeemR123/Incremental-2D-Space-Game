extends Resource
class_name UpgradeData


enum ScalingType { ADDITIVE, MULTIPLICATIVE, SUBTRACTIVE } 

#############################
# -= PROPERTY ASSIGNMENT =- #
#############################

## A unique name used by Game_Manager (e.g. fire_rate)
@export var id: String = "e.g. 'fire_rate'" 
## The name displayed for players
@export var display_name: String = "e.g. 'Turret Satelitte Fire Rate'"
## Tells the game WHERE to apply this upgrade
@export var target_category: String = "e.g. 'turret_satellite'"
@export_multiline var description: String = "What this upgrade does..."

@export_category("Economy")
@export var base_cost: int = 1
@export var max_cost: int = 0 # 0 == no max
@export var cost_multiplier: float = 1.00

@export_category("Effect")
## !!! Exported value in Inspector MAY not do anything : Auto-syncs with target_category's base stat
@export var base_value: float
## 0 == no max
@export var max_value: float
@export var val_per_level: float
## Determines whether base_value is increased using a formula that adds or multiplies
@export var scaling_type: ScalingType = ScalingType.ADDITIVE

# State variable (Not exported; dynamic during gameplay)
var current_level: int = 1


# - Functions - #

## Increments level of upgrade by 1
func level_up() -> void:
	current_level += 1

## Resets level of upgrade to 1
func reset() -> void:
	current_level = 1

## Returns current cost of upgrade based on current cost (or cost specified in parameters)
func get_current_cost(level: int = current_level) -> int:
	
	var current_cost = int(base_cost * pow(cost_multiplier, level - 1))
	
	# If no max_cost set, then it skips
	if max_cost > 0 and max_cost <= current_cost:
		return max_cost
	
	return current_cost

## Returns the current value of upgrade based on current level (or level specified in parameters)
func get_current_value(level: int = current_level) -> float:
	
	# Uses matching formula to selected scaling_type then uses val_up_per_level as the value increase
	match scaling_type:
		
		ScalingType.ADDITIVE:
			
			var current_value = base_value + (val_per_level * (level - 1))
			if max_value > 0 and max_value <= current_value:
				return max_value
			return current_value
		
		ScalingType.MULTIPLICATIVE:
			
			var current_value = base_value * pow(val_per_level, level - 1)
			if max_value > 0 and max_value <= current_value:
				return max_value
			return current_value
		
		ScalingType.SUBTRACTIVE:
			
			var current_value = base_value - (val_per_level * (level - 1))
			if max_value > 0 and max_value >= current_value:
				return max_value
			return current_value
		
		# If no acceptable scaling_type selected, pushes warning and returns base_value
		_:
			push_warning("Unknown scaling_type on UpgradeData: %s" % id)
			return base_value

## Returns block reason for purchase, if there is one. Derived from PurchaseBlockIDs.
func get_block_reason(resources: int = Game_Manager.resources) -> PurchaseBlock.Reason:
	var cost = get_current_cost()
	if max_cost > 0 and cost >= max_cost:
		#print_rich(" [color=green][b][GAME][/b][/color] Purchase_upgrade: UNSUCCESSFUL | Max cost reached: target_category '%s', with current cost of %d, next cost of %d, and max cost of %d " % [target_category, cost, get_current_cost(current_level+1), max_value])
		return PurchaseBlock.Reason.MAX_COST
	
	if max_value > 0:
		var current = get_current_value()
		var is_decreasing = scaling_type == ScalingType.SUBTRACTIVE
		var capped = (is_decreasing and current <= max_value) or (not is_decreasing and current >= max_value)
		if capped:
			#print_rich(" [color=green][b][GAME][/b][/color] Puchase_upgrade: UNSUCCESSFUL | Max Upgrade Value reached: target_category '%s', with current value of %.1f, next value of %.1f, and max value of %.1f " % [target_category, get_current_value(current_level+1), current_level, max_value])
			return PurchaseBlock.Reason.MAX_VALUE
	
	if resources < cost:
		#print_rich(" [color=green][b][GAME][/b][/color] Upgrade Purchase [u]UNSUCCESSFUL[/u] | Not Enough Resources- %s at level %d for cost: %d resources" % [id, current_level, get_current_cost()])
		return PurchaseBlock.Reason.NOT_ENOUGH_RESOURCES
	
	return PurchaseBlock.Reason.NONE

## Returns unique save/load key pair: target_category/upgrade.id
func get_save_key() -> String:
	return "%s/%s" % [target_category, id]
