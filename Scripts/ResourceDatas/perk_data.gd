extends Resource
class_name PerkData


enum PerkEffect { 
	## Indicates this perk will modify an [code]active_stats[/code] value by a certain amount. [code]STAT_MODIFIER[/code] Perks use the [code]@export[/code] values: [code]target_category, stat_id, and value[/code].
	STAT_MODIFIER, 
	## Indicates this perk will unlock a feature or something similar, and will not effect any stat or value. [code]UNLOCK[/code] Perks use the [code]@export[/code] values: [code]unlock_id[/code]. For example, unlocking extra targeting modes for satellites.
	UNLOCK,
	}
enum PerkType { 
	## For use as flat addition: ([code]value[/code]: 25 -> [b]+25[/b])
	FLAT, 
	## For use as fractions: ([code]value[/code]: 0.25 -> [b]+25%[/b])
	PERCENT,
	}

@export var id : String
@export var display_name : String
@export_multiline var description : String = "What this perk does..."

@export_category("Economy")
@export var cost : int

@export_category("Effect")
## Sets [code]PerkEffect[/code] which determines which kind of perk this is.
@export var perk_effect : PerkEffect = PerkEffect.STAT_MODIFIER
@export_group("Parameters : Unlock")
## Only affected by [code]PerkEffect[/code]: [code]UNLOCK[/code].  [br].[br]What to unlock when perk is purchased. Ex: 'threat_indicator'
@export var unlock_id : String 
@export_group("Parameters : Stat_Modifier")
## Only affected by [code]PerkEffect[/code]: [code]STAT_MODIFIER[/code].  [br].[br]Mirror [code]UpgradeData[/code]: which [code]active_stats[/code] categories this affects. Can list multiple targets or "all" to target all categories with a matching [code]stat_id[/code]. [br].[br]Ex: [code]target_categories[/code] = 'planet'
@export var target_categories : Array[String]
## Only affected by [code]PerkEffect[/code]: [code]STAT_MODIFIER[/code].  [br].[br]Specifies which [code]stat[/code] within the specified [code]target_categories[/code] should be altered. [br].[br]Ex: [code]target_categories[/code] = ['planet'], [code]stat_id[/code] = 'shield'
@export var stat_id : String
## Only affected by [code]PerkEffect[/code]: [code]STAT_MODIFIER[/code].  [br].[br]Sets [code]PerkType[/code] which affects how [code]value[/code] treats desired [code]stat[/code].
@export var perk_type : PerkType = PerkType.PERCENT
## Only affected by [code]PerkEffect[/code]: [code]STAT_MODIFIER[/code].  [br].[br]See how the above field ([code]PerkType[/code]) affects this value.[br].[br]One-time [code]value[/code] of effect - no levels or scaling, permanent increase for entire run (until [code]game_reset()[/code]. 
@export var value : float

@export_category("Tree")
@export var prerequisites : Array[PerkData] = []	# Must ALL be purchased before this becomes purchasable
@export var tier : int = 0		# Vertical row hint for future tree layout

var is_purchased : bool = false


# - Functions - 

# Determines if this perk should be unlocked based on if it's prerequisites are
func _prereqs_met() -> bool:
	for perk in prerequisites:
		if not perk.is_purchased:
			return false
	return true

func reset() -> void:
	is_purchased = false

func get_current_cost() -> int:
	return cost

func get_block_reason(resources: int = Game_Manager.resources) -> PurchaseBlock.Reason:
	if is_purchased:
		return PurchaseBlock.Reason.ALREADY_OWNED
	
	if not _prereqs_met():
		return PurchaseBlock.Reason.PREREQS_NOT_MET
	
	if resources < cost:
		return PurchaseBlock.Reason.NOT_ENOUGH_RESOURCES
	
	return PurchaseBlock.Reason.NONE
