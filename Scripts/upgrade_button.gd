extends Button

@onready var game := Game_Manager
@export var upgrade_data: UpgradeData



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
	
	var cost = upgrade_data.get_current_cost()
	var level = upgrade_data.current_level
	var next_val = upgrade_data.base_value + (upgrade_data.val_up_per_level * level)
	
	# Disables button if unaffordable
	disabled = game.resources < cost
	
	text = "%s (Lv %d)\nCost: %d | Next: %.2f" % [upgrade_data.display_name, level, cost, next_val]
