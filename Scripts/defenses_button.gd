extends Button

@onready var game := Game_Manager
@export var defense_data: DefenseData



func _ready() -> void:
	pressed.connect(_on_pressed)
	game.resources_changed.connect(update_display)
	update_display()


func _on_pressed() -> void:
	if game.purchase_defenses(defense_data):
		update_display()


func update_display() -> void:
	if not defense_data: return
	
	var cost = defense_data.get_current_cost()
	var owned = defense_data.amount_owned
	
	# Disables button if unaffordable
	disabled = game.resources < cost or owned >= defense_data.max_allowed
	
	text = "%s (Owned: %d)\nCost: %d" % [defense_data.display_name, owned, cost]
