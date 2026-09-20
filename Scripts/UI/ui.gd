extends CanvasLayer


@onready var game := Game_Manager
@onready var wave := WaveManager


# Constants
const CATEGORY_NAMES := {	# Display titles for non-defense upgrade categories
	"planet": "Planet",
	"tractor_beam": "Tractor Beam",
}
const SHOP_ACC_ROW = preload("uid://br8qdqqge6hgr")

# Nodes
@onready var planet := get_tree().get_first_node_in_group("Planet")
@onready var camera := get_tree().current_scene.get_node("Camera")

# Labels
@onready var resource_label: Label = $ResourceLabel
@onready var wave_label: Label = $WaveLabel
@onready var bwave_label: Label = $BossWaveLabel
@onready var planet_shield: Label = $PlanetShield
@onready var remaining_asteroids: Label = $RemainingAsteroids

# Buttons
@onready var retry_button: Button = $GameOverScreen/VBoxContainer/RetryButton
@onready var hide_button: Button = $ShopPanel/HideShopButton
@onready var start_wave_button: Button = $StartWaveButton
@onready var restart_button: Button = $RestartButton

# Control Nodes
@onready var game_over_screen: Control = $GameOverScreen
@onready var shop_panel: PanelContainer = $ShopPanel
@onready var mouse_dot: Node2D = $ShopPanel/MouseDot

# Shop Lists
@onready var satellites_list: VBoxContainer = $ShopPanel/VBoxContainer/ShopTabs/Satellites/VBoxContainer
@onready var drones_list: VBoxContainer = $ShopPanel/VBoxContainer/ShopTabs/Drones/VBoxContainer
@onready var planet_list: VBoxContainer = $ShopPanel/VBoxContainer/ShopTabs/Planet/VBoxContainer
@onready var perks_list: VBoxContainer = $ShopPanel/VBoxContainer/ShopTabs/Perks/VBoxContainer

@export var shop_slide_duration : float = 2
@export var shop_hidden_margin : int = 1

var shop_origin : Vector2 = Vector2(0,0)
var shop_hidden_pos : Vector2

var manually_hidden : bool = false
var shop_tween : Tween



func _ready() -> void:
	game.resources_changed.connect(_update_r_ui)	# signals from Game_Manager
	game.shield_changed.connect(_update_shield_ui)	# ^
	game.game_over.connect(game_over_event)			# ^
	
	wave.wave_complete.connect(wave_tracker)		# signal from WaveManager
	
	# Signals from buttons in ui.tscn
	retry_button.pressed.connect(_on_retry_button_pressed)	
	start_wave_button.pressed.connect(_on_start_wave_button_pressed)
	restart_button.pressed.connect(_on_restart_button_pressed)
	hide_button.pressed.connect(_on_hide_button_pressed)
	
	# Viewport size and ratio signal
	get_viewport().size_changed.connect(_on_screen_resize)
	_on_screen_resize()
	
	_populate_shop_panel()
	
	# Deferred so these read final values; waits for sibling's _ready() debug settings
	# Refresh ui with current stats upon loading
	_update_r_ui.call_deferred()
	_update_shield_ui.call_deferred()
	wave_tracker.call_deferred()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Shop"):
		_on_hide_button_pressed()
	if Input.is_action_just_pressed("ZoomReset"):
		_on_screen_resize()

# Runs reset function in Game_Manager
func _on_retry_button_pressed() -> void:
	game.game_reset()
	# Reload the current active scene to wipe existing asteroids/resources from the field
	get_tree().reload_current_scene()
	
# [DEBUGGING] Restart and reloads game
func _on_restart_button_pressed() -> void:
	print_rich(" [color=yellow][b][DEBUG][/b][/color] Game Manually Reset via 'Restart Game' Button ")
	game.game_reset()
	get_tree().reload_current_scene()

# Starts next wave and hides shop
func _on_start_wave_button_pressed() -> void:
	wave.start_wave()
	wave_tracker()

# Gets the new screen size + ratio and adjusts shop UI | Updates on screen resize
func _on_screen_resize() -> void:
	var canvas_size : Vector2 = shop_panel.get_parent_area_size()
	var should_show = not wave.wave_active and not manually_hidden	# Toggle criteria
	
	# Readjusts the coordinates of the shop's origin
	shop_origin = Vector2(shop_panel.anchor_left * canvas_size.x,0)
	# Readjusts the coordinates where the shop would be fully off-screen
	shop_hidden_pos = shop_origin - Vector2((shop_panel.anchor_right - shop_panel.anchor_left) * canvas_size.x + shop_hidden_margin, 0)
	
	if shop_tween:
		shop_tween.kill()
	shop_panel.position = shop_origin if should_show else shop_hidden_pos

# Shifts the shop off-screen and centers planet
func _on_hide_button_pressed() -> void:
	manually_hidden = not manually_hidden
	hide_button.text = "Show\nShop" if manually_hidden else "Hide\nShop"
	#prints(get_viewport().size, shop_panel.size.x, shop_hidden_pos.x)
	_update_shop_visuals()

# Creates ShopAccordionRow under specified list | Called via _populate_shop_panel()
func _add_row(list: VBoxContainer, data) -> void:
	var row = SHOP_ACC_ROW.instantiate()
	list.add_child(row)
	
	if data is DefenseData:
		row.setup_defense(data)

# Refreshes resource display ui
func _update_r_ui() -> void:
	resource_label.text = "Resources: " + NumberFormat.compact(game.resources)

# Refreshes Planet shield display ui
func _update_shield_ui() -> void:
	# Gets shield value from active_stats Array in Game_Manager
	planet_shield.text = "Shield: " + NumberFormat.compact(planet.shield)

# Populates the entire shop panel with defenses and upgrades | Called via _ready()
func _populate_shop_panel() -> void:
	for defense in game.all_defenses:
		var list = satellites_list if defense is SatelliteData else drones_list
		_add_row(list, defense)
	
	# Splits non-defense upgrades by category so each gets one accoridon row
	var upgrades_by_category : Dictionary = {}
	for upgrade in game.all_upgrades:
		if not game.NON_DEFENSE_DEFAULTS.has(upgrade.target_category):
			continue
		if not upgrades_by_category.has(upgrade.target_category):
			upgrades_by_category[upgrade.target_category] = []
		upgrades_by_category[upgrade.target_category].append(upgrade)
	
	# Iterates the const, so categories are declared in NON_DEFENSE_DEFAULTS order
	for category in game.NON_DEFENSE_DEFAULTS:
		if not upgrades_by_category.has(category):
			continue
		var row = SHOP_ACC_ROW.instantiate()
		planet_list.add_child(row)
		row.setup_upgrade_group(CATEGORY_NAMES.get(category, category), upgrades_by_category[category])
	
	var perks_by_tier : Dictionary = {}
	for p in game.all_perks:
		if not perks_by_tier.has(p.tier):
			perks_by_tier[p.tier] = []
		perks_by_tier[p.tier].append(p)
	
	var tiers = perks_by_tier.keys()
	tiers.sort()
	for tier in tiers:
		var row = SHOP_ACC_ROW.instantiate()
		perks_list.add_child(row)
		row.setup_perk_tier(tier, perks_by_tier[tier])

# Displays and handles shop screen ui
func _update_shop_visuals() -> void:
	var wave_inactive = not wave.wave_active
	var should_show = wave_inactive and not manually_hidden	# Toggle criteria
	
	# Toggle: Shifts the shop off-screen and centers planet
	shop_slide(should_show)
	camera.set_shop(should_show)
	start_wave_button.visible = wave_inactive
	mouse_dot.show_dot(wave_inactive)
	
	# Displays next boss wave if current wave is within 5 waves
	if wave_inactive and wave.current_wave + 4 >= wave.next_boss_wave:
		bwave_label.show()
		bwave_label.text = "Upcoming Boss: Wave " + str(wave.next_boss_wave)
	else:
		bwave_label.hide()

# Tweens the shop to hide/show it | Called via _update_shop_visuals()
func shop_slide(should_show: bool) -> void:
	var target = shop_origin if should_show else shop_hidden_pos
	
	if shop_tween:
		shop_tween.kill()
	
	shop_tween = create_tween()
	shop_tween.set_ease(Tween.EASE_IN_OUT)
	shop_tween.set_trans(Tween.TRANS_QUINT)
	shop_tween.tween_property(shop_panel, "position", target, shop_slide_duration)

# Toggles shop UI if there is no wave
func wave_tracker() -> void:
	if wave.wave_active:	# Displays Shop and UI info based on if the wave is active
		hide_button.hide()
		manually_hidden = false
		wave_label.text = "Wave: " + str(wave.current_wave)
		#remaining_asteroids.text = "Asteroids Left: " + str(wave.)
	else:
		hide_button.show()
		wave_label.text = "Next Wave: " + str(wave.current_wave)
	
	_update_shop_visuals()

# Displays "Game Over" screen | Called from Game_Manager
func game_over_event() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	game_over_screen.visible = true
