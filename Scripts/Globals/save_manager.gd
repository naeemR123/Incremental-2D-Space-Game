extends Node

@onready var wave := WaveManager
@onready var game := Game_Manager
@onready var stats := StatsManager

const SAVE_FILE_PATH: String = "user://savegame.json"
const SAVE_VERSION: int = 1

# - Functions -


func _ready() -> void:
	wave.wave_start.connect(save_game)
	wave.wave_complete.connect(save_game, CONNECT_DEFERRED)


## Serializes the current game state to a JSON file | Returns true if successful, false otherwise
func save_game() -> bool:
	# Checks if planet node exists
	var planet := get_tree().get_first_node_in_group("Planet")
	if planet == null:
		push_warning("SaveManager: Could not create save. Planet data could not be found.")
		return false

	# --- Populate the SaveData object with the current game state -
	
	# !! ALWAYS VERIFY WITH 'save_data.gd' BEFORE AND AFTER CHANGING !!

	var sd: SaveData = SaveData.new()	# Creates new SaveData object
	
	sd.version = SAVE_VERSION	# Saves current version number
	sd.saved_at = Time.get_datetime_string_from_system()	# Saves system time

	# Saves current and next boss wave
	sd.current_wave = wave.current_wave
	sd.next_boss_wave = wave.next_boss_wave

	sd.resources = game.resources	# Saves current resources

	# Dictionary | Stores upgrade target/id: Ex. "turret_satellite/damage"
	for upgrade in game.all_upgrades:
		sd.upgrade_levels[upgrade.get_save_key()] = upgrade.current_level

	# Dictionary | Stores defense id:amount: Ex. "turret_satellite:5"
	for defense in game.all_defenses:
		sd.defenses_owned[defense.id] = defense.amount_owned
	
	# Array | Stores ONLY perks that are 'is_purchased'
	for perk in game.all_perks:
		if perk.is_purchased: sd.perks_purchased.append(perk.id)

	# Deep duplicates so they are unique copies, not references
	sd.stats_lifetime = stats.lifetime.duplicate(true)
	sd.stats_run = stats.run.duplicate(true)

	sd.planet_shield_current = planet.shield

	# ---

	# SaveData converts into a dictionary, then into JSON string. "\t" sets indentation of text in file.
	var json_string: String = JSON.stringify(sd.save_dict(), "\t")
	var file: FileAccess = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)

	# Checks if file directory exists before running
	if file:	
		file.store_string(json_string)	# Writes JSON file to file location
		file.close()
		return true
	
	# Pushes no save and error message
	push_warning(
		"SaveManager: Could not create save. Save file directory may not exist. Error: %d"
		% FileAccess.get_open_error()
	)
	return false


## Checks if current JSON save file is valid, then loads it's data | Returns null if file is missing or corrupted
func load_game() -> SaveData:
	# Checks if save is missing -- can be normal on first launch so no warning
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		return null

	# Checks if file exists in file path
	var file: FileAccess = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file == null:
		push_warning(
			"SaveManager: could not open save file | Error %d" % FileAccess.get_open_error()
		)
		return null

	# Stores file as JSON string
	var json_string: String = file.get_as_text()
	file.close() # Closes file, no longer reading it

	# Parses JSON string into a dictionary
	var parsed = JSON.parse_string(json_string)

	# Checks if JSON string didn't parse correctly, indicating wrong JSON file
	if parsed == null:
		push_warning(
			"SaveManager: could not parse save file. Save file may not be a valid JSON file"
		)
		return null

	# Checks if root of JSON is not a dictionary, indicating wrong JSON structure
	if not parsed is Dictionary:
		push_warning("SaveManager: save file root is not a Dictionary")
		return null

	# Checks if file version outdated
	# Wrapped with int() since json's parse as floats, avoids narrowing conversion warning
	var file_version: int = int(parsed.get("version", 0))
	if file_version != SAVE_VERSION:
		push_warning(
			"SaveManager: save file version '%d' does not match current version '%d'."
			% [file_version, SAVE_VERSION]
		)
		# TODO: Decide what happens with outdated save file. Right now they return null and don't load any saves.
		return null

	# Creates new data from save_data, then loads dictionary (load_dict()) and returns it
	var save_data: SaveData = SaveData.new()
	save_data.load_dict(parsed)
	return save_data

## Checks if save file exists
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_FILE_PATH)

## Applies loaded SaveData to the live game
## Called via main.gd
func apply_save_data(data: SaveData) -> void:

	for upgrade in game.all_upgrades:
		var key: String = upgrade.get_save_key()
		if data.upgrade_levels.has(key):
			upgrade.current_level = int(data.upgrade_level[key])
			game.recalculate_stat(upgrade.target_category, upgrade.id)
			
	# TODO: FINISH THIS

## Deletes save file from directory
func delete_save() -> void:
	if has_save():
		# DirAccess handles directories and file removal; FileAccess only handles contents
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_FILE_PATH))
		print_rich("[color=red]SaveManager[/color]: Save file Deleted.")
	else:
		push_warning("SaveManager: Attempted save deletion... failed. Save does not exist.")

## Auto-saves game when window closed, as long as a wave isn't active | Called automatically by Godot
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and not wave.wave_active:
		save_game()