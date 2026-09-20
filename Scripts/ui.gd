extends CanvasLayer


@onready var game := Game_Manager
@onready var wave := WaveManager


# Constants
const DEFENSE_BUTTON = preload("res://Scenes/defenses_button.tscn")
const UPGRADE_BUTTON = preload("res://Scenes/upgrade_button.tscn")

# Labels
@onready var rlabel: Label = $ResourceLabel
@onready var wlabel: Label = $WaveLabel
@onready var bwave_label: Label = $ShopContainer/BossWaveLabel
@onready var planet_shield: Label = $PlanetShield

# Buttons
@onready var start_wave_button: Button = $ShopContainer/StartWaveButton
@onready var retry_button: Button = $GameOverScreen/VBoxContainer/RetryButton
@onready var restart_button: Button = $RestartButton

# Control Nodes
@onready var game_over_screen: Control = $GameOverScreen
@onready var shop_container: Control = $ShopContainer

# Shop Lists
@onready var defenses_list: VBoxContainer = $ShopContainer/DefensesPanel/ScrollContainer/VBoxContainer/DefensesList
@onready var upgrades_list: VBoxContainer = $ShopContainer/UpgradesPanel/ScrollContainer/VBoxContainer/UpgradesList



func _ready() -> void:
	game.resources_changed.connect(_update_r_ui)				# signals from Game_Manager
	game.shield_changed.connect(_update_shield_ui)			# ^
	game.game_over.connect(game_over_event)					# ^
	
	wave.wave_complete.connect(_shop_ui)						# signal from WaveManager
	
	retry_button.pressed.connect(_on_retry_button_pressed)	# signal from button in ui.tscn
	start_wave_button.pressed.connect(_on_start_wave_button_pressed)
	restart_button.pressed.connect(_on_restart_button_pressed)
	
	# Deferred so these read final values; waits for sibling's _ready() debug settings
	# Refresh ui with current stats upon loading
	_update_r_ui.call_deferred()
	_update_shield_ui.call_deferred()
	_shop_ui.call_deferred()

# Refreshes resource display ui
func _update_r_ui() -> void:
	rlabel.text = "Resources: " + str(game.resources)


# Refreshes Planet shield display ui
func _update_shield_ui() -> void:
	
	# Gets shield value from active_stats Array in Game_Manager
	var current_shield = game.active_stats["global"]["planet_shield"]
	planet_shield.text = "Shield: " + str(current_shield)


# Runs reset function in Game_Manager
func _on_retry_button_pressed() -> void:
	game.game_reset()
	# Reload the current active scene to wipe existing asteroids/resources from the field
	get_tree().reload_current_scene()


func _on_restart_button_pressed() -> void:
	print(" [DEBUG] Game Manually Reset via 'Restart Game' Button ")
	game.game_reset()
	# Reload the current active scene to wipe existing asteroids/resources from the field
	get_tree().reload_current_scene()


func _on_start_wave_button_pressed() -> void:
	wave.start_wave()
	_shop_ui()
	


# Displays "Game Over" screen | Called from Game_Manager
func game_over_event() -> void:
	game_over_screen.visible = true


# Displays and handles shop screen ui
func _shop_ui() -> void:
	
	
	# Displays Shop and UI info based on if the wave is active
	if wave.wave_active:
		shop_container.hide()
		wlabel.text = "Wave: " + str(wave.current_wave)
	else:
		shop_container.show()
		wlabel.text = "Next Wave: " + str(wave.current_wave)
		
		# Displays next boss wave if current wave is within 5 waves
		if wave.current_wave + 5 >= wave.next_boss_wave:
			bwave_label.text = "Upcoming Boss: Wave " + str(wave.next_boss_wave)
		else:
			bwave_label.text = ""
		
		# Deletes any existing buttons in the Shop lists
		for child in defenses_list.get_children():
			child.queue_free()
		
		for child in upgrades_list.get_children():
			child.queue_free()
		
		# Populates buttons in Defenses list in Shop with all available Defenses
		for defense in game.all_defenses:
			var button = DEFENSE_BUTTON.instantiate()
			button.defense_data = defense
			defenses_list.add_child(button)
		
		# Populates buttons in Upgrades list in Shop with all available Upgrades
		for upgrade in game.all_upgrades:
			var button = UPGRADE_BUTTON.instantiate()
			button.upgrade_data = upgrade
			upgrades_list.add_child(button)
			
		
		
		
