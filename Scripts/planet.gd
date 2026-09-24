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
var wave_heal_percent : float:
	get:
		return game.active_stats[StatIDs.PLANET][StatIDs.REGEN_PERCENT]
	set(value):
		game.active_stats[StatIDs.PLANET][StatIDs.REGEN_PERCENT] = value


var shield : float = 20.0



func _ready() -> void:
	# Tells shield bar to update whenever damage is taken
	game.shield_changed.connect(set_shield)
	wave.wave_complete.connect(heal_on_wave_end)
	
	shield_bar.step = 1 # Tells shield bar to move in increments of 1

## Keeps shield bar UI visually up-to-date
func shield_bar_update() -> void:
	shield_bar.max_value = active_max_shield
	shield_bar.value = shield

## Sets current shield/max_shield based on parameter, default = shield
## Called via SaveManager.apply_save_data()
func set_shield(value: float = shield) -> void:
	shield = minf(value, active_max_shield)
	shield_bar_update() # Tells UI to update

## Increases shield by amount
func heal(amount: float) -> void:
	shield = minf(shield + amount, active_max_shield)
	shield_bar_update() # Tells UI to update
	print_rich(" [color=green] [GAME] [/color] Planet healed for '%.1f'. Shield is now '%.1f'" % [amount, shield])

## Increases shield by percentage of max_shield
func heal_on_wave_end(percentage: float = wave_heal_percent) -> void:
	var amount = active_max_shield * percentage
	shield = minf(shield + amount, active_max_shield)
	shield_bar_update() # Tells UI to update
	print_rich(" [color=green] [GAME] [/color] Planet healed on wave end for '%.1f': percentage of %.1f%%. Shield is now '%.1f'" % [amount, percentage*100, shield])

## Syncs shield with current max shield
func sync_shield_to_max() -> void:
	shield = active_max_shield
	shield_bar_update()
