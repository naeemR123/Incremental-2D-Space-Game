extends HBoxContainer



const REASON_TEXT := {
	PurchaseBlock.Reason.LOCKED: "Locked!",
	PurchaseBlock.Reason.ALREADY_OWNED: "Already Owned!",
	PurchaseBlock.Reason.MAX_OWNED: "Max Amount Owned!",
	PurchaseBlock.Reason.MAX_COST: "Max Cost Reached!",
	PurchaseBlock.Reason.MAX_VALUE: "Max Value Reached!",
	PurchaseBlock.Reason.NOT_ENOUGH_RESOURCES: "Not Enough Resources!",
	PurchaseBlock.Reason.PREREQS_NOT_MET: "Requires: %s",
}


@onready var game := Game_Manager
@onready var orbit_manager := get_tree().current_scene.get_node("OrbitManager")

# - Node References -
@onready var name_label: Label = $Name
@onready var owned_label: Label = $Owned
@onready var value_label: Label = $Value
@onready var cost_label: Label = $Cost
@onready var purchase_button: Button = $Purchase
@onready var bulk_button: Button = $Bulk

# State Variables | Universal storage
var defense_data : DefenseData
var upgrade_data : UpgradeData
var perk_data : PerkData

var previewed_satellite : Node2D


func _ready() -> void:
	# Connects signals and purchase button
	purchase_button.pressed.connect(_on_purchase_pressed)
	bulk_button.pressed.connect(_on_bulk_purchase_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	
	WaveManager.wave_complete.connect(update_display)
	game.resources_changed.connect(update_display)
	game.stats_changed.connect(update_display)

# Stores defense for this purchase line
func setup_defense(data: DefenseData) -> void:
	defense_data = data
	update_display()

# Stores upgrade for this purchase line
func setup_upgrade(data: UpgradeData) -> void:
	upgrade_data = data
	update_display()

# Stores perk for this purchase line
func setup_perk(data: PerkData) -> void:
	perk_data = data
	update_display()

# Refreshes UI
func update_display() -> void:
	if defense_data:
		_update_defense_display()
	elif upgrade_data:
		_update_upgrade_display()
	elif perk_data:
		_update_perk_display()

# Attempts to purchase based on data source
func _on_purchase_pressed() -> void:
	if defense_data:
		game.purchase_defenses(defense_data)
	elif upgrade_data:
		game.purchase_upgrade(upgrade_data)
		
		# Immediately updates range preview when purchased
		_refresh_range_preview(true)
		
	elif perk_data:
		game.purchase_perk(perk_data)

# Attempts to bulk purchase based on data source
func _on_bulk_purchase_pressed() -> void:
	var amount = -1 if Input.is_key_pressed(KEY_SHIFT) else 10
	if defense_data:
		game.purchase_defenses_bulk(defense_data, amount)
	elif upgrade_data:
		game.purchase_upgrade_bulk(upgrade_data, amount)


func _process(_delta: float) -> void:
	# If 'SHIFT' is held, swaps 'x10' for 'MAX' button
	var new_text = "Max" if Input.is_key_pressed(KEY_SHIFT) else "x10"
	if bulk_button.text != new_text:
		bulk_button.text = new_text

# When mouse enters range label, visually displays Satellite's current and next level range
func _on_mouse_entered() -> void:
	_refresh_range_preview(true)

# When mouse exits range label, stops Satellite's range display
func _on_mouse_exited() -> void:
	_refresh_range_preview(false)

# Visually displays Satellite's current and next level range  based on parameters
func _set_satellite_range_visible(can_see: bool, next_range: float = 0.0) -> void:
	# Checks if there is a ring that has range stat 
	for ring in orbit_manager.get_children():
		if ring.my_id != upgrade_data.target_category:
			continue
			
		var all_sats = ring.get_children()	# Stores those satellites
		if not can_see: # If can't see, tells ALL satellites to turn off their range previews (prevents bug)
			for sat in all_sats:
				if sat.has_method("set_preview_range_visible"):
					sat.set_preview_range_visible(false)
				if sat.has_method("set_range_visible"):
					sat.set_range_visible(false)
			previewed_satellite = null
			return
		
		if all_sats.is_empty(): return
		
		# If can see, tells one random satellite to enable range preview  
		if not is_instance_valid(previewed_satellite) or previewed_satellite.get_parent() != ring:
			previewed_satellite = all_sats.pick_random()
		
		if previewed_satellite.has_method("set_range_visible"):
			previewed_satellite.set_range_visible(true)
		if previewed_satellite.has_method("set_preview_range_visible"):
			previewed_satellite.set_preview_range_visible(true, next_range)
		return

# Checks if self is RANGE Upgrade, then refreshes RANGE Preview
func _refresh_range_preview(refresh: bool) -> void:
	if not upgrade_data: return # Crashes without this
	if upgrade_data.id == StatIDs.RANGE:
		var next_range = upgrade_data.get_current_value(upgrade_data.current_level+1)
		_set_satellite_range_visible(refresh, next_range)

# Refreshes the displayed text and values
func _update_defense_display() -> void:
	# Determines if button should be disabled
	var reason = defense_data.get_block_reason()
	var cost: int = defense_data.get_current_cost()
	var owned: int = defense_data.amount_owned
	# Refreshes text and values
	name_label.text = "Buy " + defense_data.display_name
	value_label.visible = false 	# Value label is hidden for defenses (no value)
	owned_label.text = NumberFormat.compact(owned) + " owned"	# Allows defenses owned to display
	owned_label.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_PASS	# Enables mouse hover
	
	if reason == PurchaseBlock.Reason.MAX_OWNED:
		cost_label.text = "MAXED"  
	elif reason == PurchaseBlock.Reason.LOCKED: 
		cost_label.text = "Unlocks Wave %d" % defense_data.unlock_wave 
	else:
		cost_label.text = NumberFormat.compact(cost) + " resources"
	
	purchase_button.tooltip_text = _get_reason_text(reason)
	bulk_button.tooltip_text = purchase_button.tooltip_text
	
	# Disables button if not enough resources or max amount of defenses already owned
	var blocked = reason != PurchaseBlock.Reason.NONE
	purchase_button.disabled = blocked
	bulk_button.disabled = blocked

# Refreshes the displayed text and values
func _update_upgrade_display() -> void:
	var reason = upgrade_data.get_block_reason()
	var cost: int = upgrade_data.get_current_cost()
	var current_val: float = upgrade_data.get_current_value()
	var next_val: float = upgrade_data.get_current_value(upgrade_data.current_level+1)
	# Refreshes text and values
	name_label.text = upgrade_data.display_name
	value_label.text = NumberFormat.compact(current_val) + " -> " + NumberFormat.compact(next_val)
	# Allows desc. to display on mouse hover
	tooltip_text = "Level: %s\n%s" % [NumberFormat.compact(upgrade_data.current_level),upgrade_data.description]
	mouse_filter = Control.MOUSE_FILTER_PASS	# Enables mouse hover
	
	var is_maxed = reason == PurchaseBlock.Reason.MAX_COST or reason == PurchaseBlock.Reason.MAX_VALUE
	cost_label.text = "MAXED" if is_maxed else NumberFormat.compact(cost) + " resources"
	
	# If assigned to Planet tab, applies 'owned' label, otherwise hides
	if upgrade_data.target_category == StatIDs.PLANET:
		owned_label.text = "Level: " + NumberFormat.compact(upgrade_data.current_level)
		owned_label.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
	else:
		owned_label.visible = false
	
	purchase_button.tooltip_text = _get_reason_text(reason)
	bulk_button.tooltip_text = purchase_button.tooltip_text
	
	var blocked: bool = reason != PurchaseBlock.Reason.NONE
	purchase_button.disabled = blocked	# Disables button if not enough resources
	bulk_button.disabled = blocked

# Refreshes the displayed text and values
func _update_perk_display() -> void:
	var reason = perk_data.get_block_reason()
	var cost: int = perk_data.get_current_cost()
	
	if reason == PurchaseBlock.Reason.PREREQS_NOT_MET or reason == PurchaseBlock.Reason.LOCKED:
		visible = false
		return
	
	visible = true
	name_label.text = perk_data.display_name
	value_label.visible = false
	owned_label.visible = false 	# Owned label is hidden for perks (cost label handles it)
	tooltip_text = perk_data.description
	mouse_filter = Control.MOUSE_FILTER_PASS	# Enables mouse hover
	
	var owned = reason == PurchaseBlock.Reason.ALREADY_OWNED
	cost_label.text = "OWNED" if owned else NumberFormat.compact(cost) + " resources"
	cost_label.size_flags_horizontal = Control.SIZE_SHRINK_END | Control.SIZE_EXPAND
	
	purchase_button.tooltip_text = _get_reason_text(reason)
	purchase_button.disabled = reason != PurchaseBlock.Reason.NONE
	
	bulk_button.visible = false

# Pulls reason for PurchaseBlock and lists the String from REASON_TEXT
func _get_reason_text(reason: PurchaseBlock.Reason) -> String:
	var text: String = REASON_TEXT.get(reason, "")
	
	if reason == PurchaseBlock.Reason.PREREQS_NOT_MET and perk_data:
		text = text % _missing_prereq_names()
	
	return text

# Prints prerequisites for PerkDatas as Strings
func _missing_prereq_names() -> String:
	var names: PackedStringArray = []
	for perk in perk_data.prerequisites:
		if not perk.is_purchased:
			names.append(perk.display_name)
	return ", ".join(names)
