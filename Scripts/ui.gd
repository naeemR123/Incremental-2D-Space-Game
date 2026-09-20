extends CanvasLayer

@onready var game := Game_Manager



@onready var label: Label = $Stats
@onready var planet_shield: Label = $PlanetShield
@onready var game_over_screen: Control = $GameOverScreen
@onready var retry_button: Button = $GameOverScreen/VBoxContainer/RetryButton


func _ready() -> void:
	game.resources_changed.connect(update_ui)
	game.shield_changed.connect(update_shield_ui)
	game.game_over.connect(game_over_event)
	
	retry_button.pressed.connect(_on_retry_button_pressed)
	
	game_over_screen.visible = false
	update_ui()
	update_shield_ui()


func update_ui():
	label.text = "Resources: " + str(game.resources)


func update_shield_ui():
	var current_shield = game.active_stats["global"]["planet_shield"]
	planet_shield.text = "shield:\n-" + str(current_shield) + " -"


func _on_retry_button_pressed():
	game.game_reset()
	# Reload the current active scene to wipe existing asteroids/resources from the field
	get_tree().reload_current_scene()


func game_over_event():
	game_over_screen.visible = true
