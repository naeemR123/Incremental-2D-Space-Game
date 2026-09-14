extends Area2D


@onready var game := Game_Manager
@onready var wave := WaveManager

@onready var shield_bar : ProgressBar = $ProgressBar


## Variable always synced with Game_Manager's active_stats
var active_max_shield: float:
	get:
		return game.active_stats[StatIDs.PLANET][StatIDs.MAX_SHIELD]
	set(value):
		game.active_stats[StatIDs.PLANET][StatIDs.MAX_SHIELD] = value

## Value wave-end heals the planet based on percentage of max_shield
var wave_heal_percent : float = 0.1
var shield : float = 20.0



func _ready() -> void:
	# Tells shield bar to update whenever damage is taken
	game.shield_changed.connect(_update_shield)
	wave.wave_complete.connect(heal_on_wave_end)
	
	shield_bar.step = 1 # Tells shield bar to move in increments of 1
	
	# Pulls value set for max shield in active_stats
	shield = active_max_shield
	_update_shield()

# Keeps shield bar UI visually up-to-date
func shield_bar_update() -> void:
	shield_bar.max_value = active_max_shield
	shield_bar.value = shield

# UI & Updates Max shield | Game_Manager handles damage dealth to shield
func _update_shield() -> void:
	# Gets max shield value from active_stats Array in Game_Manager
	shield = minf(shield, active_max_shield)
	shield_bar_update() # Tells UI to update

# Increases shield by amount
func heal(amount: float) -> void:
	shield = minf(shield + amount, active_max_shield)
	shield_bar_update() # Tells UI to update
	print_rich(" [color=green] [GAME] [/color] Planet healed for '%.1f'. Shield is now '%.1f'" % [amount, shield])

# Increases shield by percantage of max_shield
func heal_on_wave_end(percentage: float = wave_heal_percent) -> void:
	var amount = active_max_shield * percentage
	shield = minf(shield + amount, active_max_shield)
	shield_bar_update() # Tells UI to update
	print_rich(" [color=green] [GAME] [/color] Planet healed on wave end for '%.1f': percentage of '%.1f%'. Shield is now '%.1f'" % [amount, percentage*100, shield])

# Syncs shield with current max shield
func sync_shield_to_max() -> void:
	shield = active_max_shield
	shield_bar_update()
