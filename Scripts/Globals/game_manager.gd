extends Node



#  = Arrays - Dictionaries = #

# Game Start Defaults
const NON_DEFENSE_DEFAULTS := {
	"planet": {"shield": 20.0, "regen_percent": 0.1,},
	"tractor_beam": {"slow_strength": 0.0, "beam_size": 50.0,},
	"global": {"drop_amount": 1.0,},
}

# Holds the CURRENT value of ALL upgradable stats game-wide : populated via register_defense_stats()
var active_stats: Dictionary = {}
var owned_defenses: Array[String] = []			# Stores all active defenses : populated via purchase_defenses()
var all_defenses : Array[DefenseData] = []		# Stores all defenses : populated via register_all_defenses()
var all_upgrades : Array[UpgradeData] = []		# Stores all upgrades : populated via register_all_defenses()
var all_perks : Array[PerkData] = []			# Stores all perks : populated via register_all_perks()
var all_resource_types : Array[ResourceData] = []	# Stores all resource types : populated via register_resource_types()
var unlocked_features : Array[String] = []			# Stores all unlocked features : populated via purchase_perks()

# { category: { stat_id: summed-flat-bonus/combined-multiplier } }
var perk_flat : Dictionary = {}					# Stores active FLAT perk-types : populated via purchase_perk()
var perk_mult : Dictionary = {}					# Stores active PERCENT perk-types : populated via purchase_perk()

# =

# Universal Game Properties
var resources : int = 0
var planet_destroyed : bool = false

# Signals
signal stats_changed()
signal resources_changed()
signal shield_changed()
signal planet_hit(damage: float)
signal game_over()
signal feature_unlocked(unlock_id: String)
signal reset_unlocks()


#################
# - Functions - #
#################


func _ready() -> void:
	_reset_non_defense_stats()  # CRITICAL : ORDER MATTERS: needs to run 1st on game startup
	register_all_defenses()		# CRITICAL : ^ Defenses after category reset
	register_all_upgrades()		# CRITICAL : 	^ Upgrades after defenses
	register_all_perks()		# CRITICAL : 		^ Perks after upgrades
	register_currency()			# CRITICAL : 			^ Resources after upgrades
	
	StatsManager.increment(CounterIDs.RUNS_STARTED)
	print(" | INCREMENTED RUNS STARTED STAT | ")

## Adds resource to inventory and updates ui
func add_resource(amount: int) -> void:
	StatsManager.increment(CounterIDs.RESOURCES_EARNED, amount)
	resources += amount
	resources_changed.emit()

## Processes damage done to Planet, destroys if 0
func take_damage(damage_val: float) -> void:
	
	# Safety net : Can't take damage if destroyed
	if planet_destroyed: return
	
	# Reduces shield based on damage value
	var planet = get_tree().get_first_node_in_group("Planet")
	
	if planet == null: 
		push_warning(" [GAME] Could not run take_damage() due to planet == null | Game_Manager ")
		return
	
	StatsManager.increment(CounterIDs.PLANET_DAMAGE_TAKEN, damage_val)
	planet.shield -= damage_val # Deals damage
	
	# Safety correction
	if planet.shield <= 0: planet.shield = 0
	
	# Tells UI to refresh
	planet_hit.emit(damage_val)
	shield_changed.emit()
	
	print_rich(" [color=green][b][GAME][/b][/color] Planet hit for %.1f damage | \
	Current Shield: %.1f" % [damage_val,planet.shield])
	
	# If shield is 0, run game over function
	if planet.shield == 0:
		trigger_game_over()

## Scans the Defenses resource folder and registers stats for every DefenseData it finds
func register_all_defenses() -> void:
	ResourceScanner.register_folder("res://Scripts/Resources/Defenses/", DefenseData, register_defense_stats, "DEFENSES")

## Scans the Upgrades resource folder and registers stats for every UpgradeData it finds
func register_all_upgrades() -> void:
	ResourceScanner.register_folder("res://Scripts/Resources/Upgrades/", UpgradeData, register_upgrade_array, "UPGRADES")

## Scans the Perks resource folder and registers stats for every PerkData it finds
func register_all_perks() -> void:
	ResourceScanner.register_folder("res://Scripts/Resources/Perks/", PerkData, register_perk_stats, "PERKS")

## Scans the ResourceTypes resource folder and registers stats for every ResourceData it finds
func register_currency() -> void:
	ResourceScanner.register_folder("res://Scripts/Resources/ResourceTypes/", ResourceData, register_resource_types, "RESOURCE TYPES")

## Checks arrays for ResourceType, if not found, adds it
## Called by register_resources()
func register_resource_types(res: ResourceData) -> void:
	if all_resource_types.has(res): return
	all_resource_types.append(res)

## Checks arrays for defense , if not found, adds or duplicates it under it's id
## Called by register_all_defenses()
func register_defense_stats(defense: DefenseData) -> void:
	
	# Safe for multiple calls : won't write if entry exists
	if not active_stats.has(defense.id):
		# Duplicates to store an independent copy, instead of referencing the original
		active_stats[defense.id] = defense.default_stats.duplicate()
		
	# Safe for multiple calls : won't write if entry exists
	if not all_defenses.has(defense):
		all_defenses.append(defense)

## Checks 'all_upgrades' for resource , if not found, references it
## Called by register_all_upgrades()
func register_upgrade_array(upgrade: UpgradeData) -> void:
	
	# Safe for multiple calls : won't overwrite if entry exists
	if not all_upgrades.has(upgrade):
		
		# Syncs base_value with the defense's actual base stat, so the two can't be different
		if active_stats.has(upgrade.target_category) and active_stats[upgrade.target_category].has(upgrade.id):
			upgrade.base_value = active_stats[upgrade.target_category][upgrade.id]
		else:
			push_warning("[color=red][b][ERROR][/b][/color] register_upgrade_array: target_category '%s' or id '%s' not found in active_stats. \
			Check the UpgradeData's fields" % [upgrade.target_category, upgrade.id])
		# References original data in Array
		all_upgrades.append(upgrade)

## Registers perk and its stats to all_perks array
## Called by register_all_perks()
func register_perk_stats(perk: PerkData) -> void:
	# Safety Check : aborts if already registered
	if all_perks.has(perk): return
	
	# Safety Check : aborts if UNLOCK perk without "unlock_id"
	if perk.perk_effect == PerkData.PerkEffect.UNLOCK:
		if perk.unlock_id == "":
			push_warning("[color=red][b][GAME ERROR][/b][/color] register_perk_stats: '%s' has no unlock_id set. unlock_id = '%s'" % [perk.id, perk.unlock_id])
			return 
		all_perks.append(perk)
		return
	
	# Per-target diagnostic : reports each bad entry individually. Not meant to return.
	for target in perk.target_categories:
		if target == StatIDs.ALL:
			continue
		# Safety Check : aborts if target category not found in active_stats
		if not active_stats.has(target):
			push_warning("[color=red][b][ERROR][/b][/color] Perk not registered correctly | \
			active_stats does not contain '%s' perk's target_category: '%s'" % [perk.id, target])
		# Safety Check : aborts if stat_id not found for chosen target_category in active_stats
		elif not active_stats[target].has(perk.stat_id):
			push_warning("[color=red][b][GAME ERROR][/b][/color] register_perk_stats: Could not find perk's '%s' stat_id '%s' target_category in '%s' | \
			Check the PerkData's fields" % [perk.id, perk.stat_id, target])
	
	# Safety Check : aborts if no target_categories were resolved
	if _resolve_perk_categories(perk).is_empty():
		push_warning("[color=red][b][GAME ERROR][/b][/color] register_perk_stats: Perk '%s' did not resolve any target_categories for stat_id '%s' | \
		Check the PerkData's fields" % [perk.id, perk.stat_id])
		return
	
	# Appends STAT_MODIFIER perk if it passes all safety checks
	all_perks.append(perk)

## Returns a stat's value BEFORE any Perks and the upgrade curve if one exists, defaults otherwise
func get_base_stat(category: String, stat_id: String) -> float:
	for upgrade in all_upgrades:
		if upgrade.target_category == category and upgrade.id == stat_id:
			return upgrade.get_current_value()
	
	if NON_DEFENSE_DEFAULTS.has(category):
		return NON_DEFENSE_DEFAULTS[category].get(stat_id, 0.0)
	
	for defense in all_defenses:
		if defense.id == category:
			return defense.default_stats.get(stat_id, 0.0)
	
	push_warning("get_base_stat: no source found for '%s' / '%s'" % [category, stat_id])
	return 0.0

## Recomputes one stat from its base + every perk after, then writes the result to the stat. | Called via _apply_perk_effects() 
func recalculate_stat(category: String, stat_id: String) -> void:
	var flat: float = perk_flat.get(category, {}).get(stat_id, 0.0)
	var mult: float = perk_mult.get(category, {}).get(stat_id, 1.0)
	
	active_stats[category][stat_id] = (get_base_stat(category, stat_id) + flat) * mult

## Returns Array of validated upgrades to apply to active_stats | Called via purchase_perk(), _apply_perk_effects()
func _resolve_perk_categories(perk: PerkData) -> Array[String]:
	var categories : Array[String] = []
	
	# Goes through every entry in perk's target_categories
	for target in perk.target_categories:
		
		# If a category is ALL, then adds applicable categories with stat to list
		if target == StatIDs.ALL:
			for category in active_stats:
				if NON_DEFENSE_DEFAULTS.has(category):	# Skips over non-defense stats 
					continue
				_try_add_category(categories, category, perk.stat_id)
				
		# If category is not ALL, checks if category is in active_stats then tries to add to list
		elif active_stats.has(target):
			_try_add_category(categories, target, perk.stat_id)
	
	return categories

## Adds it to upgrade list if it carries the stat if no duplicates | Called via _resolve_perk_categories()
func _try_add_category(categories: Array[String], category: String, stat_id: String) -> void:
	if not active_stats[category].has(stat_id):
		return
	if categories.has(category):
		return
	categories.append(category)

## Applies Max Shield upgrade and applies the different to current shield | Called via purchase_upgrade() & _apply_perk_effects()
func _apply_shield_gain(before: float) -> void:
	var gained : float = active_stats[StatIDs.PLANET][StatIDs.MAX_SHIELD] - before
	if is_zero_approx(gained): return
	
	# Heals the shield increase difference
	var planet = get_tree().get_first_node_in_group("Planet")
	if planet:
		planet.heal(gained)
	shield_changed.emit()

## Returns if feature has been unlocked by an UNLOCK perk | Called via threat_arrow_manager.gd: _refresh_unlock_status()
func is_feature_unlocked(unlock_id: String) -> bool:
	return unlocked_features.has(unlock_id)

## Purchase function for Defenses
func purchase_defenses(defense: DefenseData) -> bool:
	
	if defense.get_block_reason() != PurchaseBlock.Reason.NONE:
		return false
	
	# Defines current cost of defense based on its criteria
	var cost = defense.get_current_cost()
	
	# Attempts to spawn defense, denies purchase if can't
	var spawn : bool = spawn_defense(defense)
	if not spawn:
		# Warning handled by spawn_defense()
		return false
	
	StatsManager.increment(CounterIDs.DEFENSES_PURCHASED)
	StatsManager.increment(CounterIDs.RESOURCES_SPENT, cost)
	
	resources -= cost
	defense.amount_owned += 1
	defense.is_purchased = true
	
	# Tells UI to refresh
	resources_changed.emit()
	
	print_rich(" [color=green][b][GAME][/b][/color] Defense Purchase Successful | Purchased %s" % defense.id)
	return true # Purchase successful

## Purchase function for Upgrades
func purchase_upgrade(upgrade: UpgradeData) -> bool:
	
	if upgrade.get_block_reason() != PurchaseBlock.Reason.NONE:
		return false
	
	var is_shield_upgrade : bool = upgrade.target_category == StatIDs.PLANET and upgrade.id == StatIDs.MAX_SHIELD
	var shield_before : float = active_stats[StatIDs.PLANET][StatIDs.MAX_SHIELD] if is_shield_upgrade else 0.0
	
	# Safety check : Only upgrades if it is a valid registered category and property
	if not active_stats.has(upgrade.target_category):
		# Pushes if upgrade's target_category doesn't exist - meaning the category was never registered, or it is incorrect
		push_warning("Purchase_upgrade: target_category '%s' not found in active_stats. Was it registered correctly?" % upgrade.target_category)
		return false # Purchase unsuccessful : target_category not found in active_stats
	
	# Defines current cost value of upgrade
	var cost : int = upgrade.get_current_cost()
	
	StatsManager.increment(CounterIDs.UPGRADES_PURCHASED)
	StatsManager.increment(CounterIDs.RESOURCES_SPENT, cost)
	
	resources -= cost
	upgrade.level_up()
	recalculate_stat(upgrade.target_category, upgrade.id)
	
	if is_shield_upgrade: _apply_shield_gain(shield_before)
	# Tells UI to refresh
	resources_changed.emit()
	stats_changed.emit()
	
	return true # Purchase successful

## Purchase function for Perks
func purchase_perk(perk: PerkData) -> bool:
	
	if perk.get_block_reason() != PurchaseBlock.Reason.NONE:
		return false
	
	# Compiles perk target_categories and stat_id
	var categories : Array[String] = []
	
	# Safety check : Only upgrades if it is a valid registered category and property
	if perk.perk_effect == PerkData.PerkEffect.STAT_MODIFIER:
		categories = _resolve_perk_categories(perk)
		if categories.is_empty():
			push_warning("[color=red][b][GAME ERROR][/b][/color] purchase_perk: '%s' resolved to no categories for stat '%s'" % [perk.id, perk.stat_id])
			return false
	
	var cost : int = perk.get_current_cost()
	
	StatsManager.increment(CounterIDs.PERKS_PURCHASED)
	StatsManager.increment(CounterIDs.RESOURCES_SPENT, cost)
	
	resources -= cost
	apply_perk_effects(perk)
	
	resources_changed.emit()
	stats_changed.emit()
	
	print_rich(" [color=green][b][GAME][/b][/color] Perk Purchase SUCCESSFUL | Purchased '%s'" % perk.id)
	return true

## Unlocks perk and applies its effect
## Called via purchase_perk(), SaveManager.apply_save_data()
func apply_perk_effects(perk: PerkData) -> void:
	perk.is_purchased = true
	
	if perk.perk_effect == PerkData.PerkEffect.UNLOCK:
		if not unlocked_features.has(perk.unlock_id):
			unlocked_features.append(perk.unlock_id)
			feature_unlocked.emit(perk.unlock_id)
	else:
		var is_shield_perk := perk.stat_id == StatIDs.MAX_SHIELD
		var shield_before : float = active_stats[StatIDs.PLANET][StatIDs.MAX_SHIELD] if is_shield_perk else 0.0
		
		# Compiles perk target_categories and stat_id
		var categories : Array[String] = _resolve_perk_categories(perk)
		if categories.is_empty():
			push_warning("[color=red][b][GAME ERROR][/b][/color] _apply_perk_effects: '%s' resolved to no categories for stat '%s'" % [perk.id, perk.stat_id])
			return
		
		for cat in categories:
			var stat := perk.stat_id
			match perk.perk_type:
				PerkData.PerkType.FLAT:
					if not perk_flat.has(cat): perk_flat[cat] = {}
					perk_flat[cat][stat] = perk_flat[cat].get(stat, 0.0) + perk.value
				
				PerkData.PerkType.PERCENT:
					if not perk_mult.has(cat): perk_mult[cat] = {}
					perk_mult[cat][stat] = perk_mult[cat].get(stat,1.0) * (1.0 + perk.value)
					
			recalculate_stat(cat, stat)
			
		# Heals the shield increase difference
		if is_shield_perk: _apply_shield_gain(shield_before)

## Spawns defense into game, registers it, and returns bool
## Called via purchase_defenses(), SaveManager.apply_save_data()
func spawn_defense(defense: DefenseData) -> bool:
	# Loads or makes an orbit ring
	var ring = load_orbit_ring(defense)
	if ring == null:	# Safety check
		push_warning(" [color=green][b][GAME][/b][/color] Defense Spawn Unsuccessful | Ring Generation Failed , \
		'correct_ring' returns null value | Attempted to Spawn %s" % defense.id)
		return false
	# -
	
	# Adds defense.id to 'owned_defenses' Array
	owned_defenses.append(defense.id)
	
	# Register stats the first time it is purchased
	register_defense_stats(defense)
	
	# Instantiates the Defense and runs its initialize function
	var new_defense = defense.defense_scene.instantiate()
	if new_defense.has_method("initialize"):
		new_defense.initialize(defense)
	
	# Adds Defense to scene tree under dedicated Orbit Ring
	ring.add_child(new_defense)
	ring.redistribute()

	return true

# Bulks purchases defenses | Defaults at 10x
func purchase_defenses_bulk(defense: DefenseData, amount: int = 10) -> int:
	
	var bought : int = 0
	var target : int = amount if amount > 0 else 9999
	
	while bought < target:
		if defense.amount_owned >= defense.max_allowed:	# Safety Check
			break
		if not purchase_defenses(defense):	# Breaks if purchase returns as false
			break
		bought += 1
	
	return bought

# Bulks purchases upgrades | Defaults at 10x
func purchase_upgrade_bulk(upgrade: UpgradeData, amount: int = 10) -> int:
	
	var bought : int = 0
	var target : int = amount if amount > 0 else 9999
	
	while bought < target:
		if not purchase_upgrade(upgrade):	# Already runs internal safety check
			break
		bought += 1
	
	return bought

# Loads a pre-existing orbit ring, or makes a new one if needed | Called via purchase_defenses()
func load_orbit_ring(defense: DefenseData) -> Node2D:
	
	var existing_rings = get_tree().current_scene.get_node("OrbitManager").get_children() # Creates array of OrbitManager's children
	var duplicate_ring : bool = false
	var correct_ring : Node2D = null	# If nothing assigns it will push error
	
	# If the id matches the incoming defense's id, then the generation 
	# of a new ring is aborted and assigns that ring as the correct_ring
	for ring in existing_rings: # Checks each existing ring's id
		if ring.my_id == defense.id: 
			duplicate_ring = true
			correct_ring = ring
			break
	# Creates new ring if it doesn't already exist
	if not duplicate_ring: 
		correct_ring = _orbit_ring_generator(defense)
	
	return correct_ring

# Loads and returns a newly generated Orbit Ring attached to the OrbitManager | Called via load_orbit_ring()
func _orbit_ring_generator(defense) -> Node2D:
	var ring_scene = load("uid://d3a75aybwxj44")
	var new_ring = ring_scene.instantiate()
	if new_ring.has_method("initialize"):
		new_ring.initialize(defense)
		get_tree().current_scene.get_node("OrbitManager").add_child(new_ring)
		return new_ring
	push_error("[ERROR] Could not run 'initialize' on new orbit_ring -- \
	function does not exist in node | Origin: Game_Manager/func purchase_defenses")
	new_ring.queue_free()
	return null

# Rebuilds each non-defense category to its default | Called via _ready() and game_reset()
func _reset_non_defense_stats() -> void:
	for category in NON_DEFENSE_DEFAULTS:
		active_stats[category] = NON_DEFENSE_DEFAULTS[category].duplicate()

# Game over function
func trigger_game_over() -> void:
	print(" ~ GAME OVER ~ ")
	planet_destroyed = true
	game_over.emit()			# Tells UI to display 'Game Over' screen
	get_tree().paused = true	# Pauses game
	print(" | GAME PAUSED | ")

# Reset function | Connected to "Try Again?" Button on 'Game Over' screen
func game_reset() -> void:
	print(" ~ RESETTING GAME... ~ ")
	
	# Resets values and properties
	resources = 0
	planet_destroyed = false
	print(" | GAME STATE VARIABLES RESET | ")
	
	# Resets active_stats
	active_stats.clear()
	print(" | ACTIVE_STATS ARRAY CLEARED | ")
	_reset_non_defense_stats()
	print(" | NON-DEFENSE ACTIVE_STATS RESET | ")
	
	# Resets WaveManager
	WaveManager.reset() 	# Resets Wave to 1
	print(" | WAVE MANAGER RESET | ")
	
	StatsManager.reset_run()
	print(" | STATS MANAGER RESET | ")
	
	
	# Runs reset() for all current perks,defenses, and upgrades: sets level to 1
	for perk in all_perks:
		perk.reset()
	print(" | PERKS RESET | ")
	for upgrade in all_upgrades:
		upgrade.reset()
	print(" | UPGRADE LEVELS RESET | ")
	for defense in all_defenses:
		defense.reset()
	print(" | DEFENSE LEVELS RESET | ")
	
	# Rebuilds stat library arrays
	all_defenses.clear()
	print(" | ALL_DEFENSES ARRAY CLEARED | ")
	owned_defenses.clear()
	print(" | OWNED_DEFENSES ARRAY CLEARED | ")
	all_upgrades.clear()
	print(" | ALL_UPGRADES ARRAY CLEARED | ")
	all_perks.clear()
	print(" | ALL_PERKS ARRAY CLEARED | ")
	all_resource_types.clear()
	print(" | ALL_RESOURCE_TYPES ARRAY CLEARED | ")
	perk_flat.clear()
	print(" | PERKS_FLAT ARRAY CLEARED | ")
	perk_mult.clear()
	print(" | PERKS_MULT ARRAY CLEARED | ")
	# Resets all unlocked features
	unlocked_features.clear()
	reset_unlocks.emit()
	print(" | UNLOCKED_FEATURES RESET | ")
	register_all_defenses()
	register_all_upgrades()
	register_all_perks()
	register_currency()
	
	# Updates UI
	resources_changed.emit()
	stats_changed.emit()
	
	get_tree().paused = false	# Unpauses game
	print(" | GAME UNPAUSED | ")
	
	print(" ~ GAME RESET COMPLETE ~ ")
