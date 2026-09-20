extends Button

@onready var game := Game_Manager
var upgrade_data: UpgradeData



func _ready() -> void:
	pressed.connect(_on_pressed)
	game.resources_changed.connect(update_display)
	game.stats_changed.connect(update_display)
	update_display()


func _on_pressed() -> void:
	if game.purchase_upgrade(upgrade_data):
		update_display()


func update_display() -> void:
	if not upgrade_data: return
	
	var cost : int = upgrade_data.get_current_cost()
	var level : int = upgrade_data.current_level
	var current_val : float = upgrade_data.get_current_value()
	var next_val : float = upgrade_data.get_current_value(upgrade_data.current_level + 1)
	
	# Disables button if unaffordable
	disabled = game.resources < cost
	
	text = "%s (Lv %d)\nCost: %d | Current: %.1f | Next: %.1f" % [upgrade_data.display_name, level, cost, current_val, next_val]
