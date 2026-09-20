extends Area2D


@onready var game := Game_Manager

@onready var shield_bar : ProgressBar = $ProgressBar


func _ready() -> void:
	
	game.shield_changed.connect(_update_shield_ui)
	shield_bar.step = 1
	
	_update_shield_ui.call_deferred()

func _update_shield_ui() -> void:
	
	#print("[DEBUG] update_shield function fired.")
	
	# Gets shield value from active_stats Array in Game_Manager
	var current_shield = game.active_stats["global"]["planet_shield"]
	shield_bar.min_value = 0
	shield_bar.max_value = game.max_planet_shield
	shield_bar.value = current_shield
	
	#print("[DEBUG] current_shield reads: %d, shield_bar.value reads: %d" % [current_shield, shield_bar.value])
