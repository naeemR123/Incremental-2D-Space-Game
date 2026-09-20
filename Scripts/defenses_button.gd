extends Button

@onready var game := Game_Manager
var defense_data: DefenseData



func _ready() -> void:
	pressed.connect(_on_pressed)
	game.resources_changed.connect(update_display)
	update_display()


func _on_pressed() -> void:
	if game.purchase_defenses(defense_data):
		update_display()
	


func update_display() -> void:
	if not defense_data: return
	
	var is_locked : bool = defense_data.unlock_wave > WaveManager.current_wave
	var cost : int = defense_data.get_current_cost()
	var owned : int = defense_data.amount_owned
	
	if is_locked:
		disabled = true
		text = "Unlocks at wave " + str(defense_data.unlock_wave)
		return
	
	# Disables button if unaffordable
	disabled = game.resources < cost or owned >= defense_data.max_allowed
	
	
	text = "%s (Owned: %d)\nCost: %d" % [defense_data.display_name, owned, cost]
