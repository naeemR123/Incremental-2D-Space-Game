extends Node


@onready var wave := WaveManager
@onready var game := Game_Manager
@onready var stats := StatsManager


const SAVE_FILE_PATH: String = "user://savegame.json"
const SAVE_VERSION: int = 1

const PROFILE_FILE_PATH: String = "user://profile.json"
const PROFILE_VERSION: int = 1


var profile_save_blocked: bool = false



# - Functions -


func _ready() -> void: 
	load_profile()	# Attempts to load user profile
	
	# Connects wave signals to trigger auto-saving
	wave.wave_start.connect(save_all)
	wave.wave_complete.connect(save_all, CONNECT_DEFERRED)

## Saves game and profile data
## Called via save_button, _notification(), signal:wave_start, signal:wave_complete
func save_all() -> void:
	save_game()
	save_profile()

## Serializes the current game state to a JSON file | Returns true if successful, false otherwise
## Called via save_all()
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

	# Deep duplicate so they are unique copies, not references
	sd.stats_run = stats.run.duplicate(true)

	sd.planet_shield_current = planet.shield

	# ---

	return _write_json(SAVE_FILE_PATH, sd.save_dict())

## Checks if current JSON save file is valid, then loads it's data | Returns null if file is missing or corrupted
func load_game() -> SaveData:
	
	var json_dict: Dictionary = _read_json(SAVE_FILE_PATH, SAVE_VERSION)
	if json_dict.is_empty(): return null	# Errors return empty Dictionaries

	# Creates new data from save_data, then loads dictionary (load_dict()) and returns it
	var save_data: SaveData = SaveData.new()
	save_data.load_dict(json_dict)
	return save_data

## Applies loaded SaveData to the live game
## Called via main.gd
func apply_save_data(data: SaveData) -> void:

	print(" -- [SAVE] GAME SAVE Loading... -- ")
	
	# Checks if planet node exists
	var planet := get_tree().get_first_node_in_group("Planet")
	if planet == null:
		print(" -- [SAVE] GAME SAVE ABORTED -- ")
		push_warning("SaveManager: Could not load save. Planet data could not be found.")
		return

	# print(" -- [SAVE] Upgrades Loading...")

	# Applies stored upgrade levels to GameManager
	for upgrade in game.all_upgrades:
		var key: String = upgrade.get_save_key()
		if data.upgrade_levels.has(key):
			upgrade.current_level = int(data.upgrade_levels[key])
			game.recalculate_stat(upgrade.target_category, upgrade.id)
	
	# print(" -- [SAVE] Perks Loading...")

	# Applies stored perks to GameManager
	for perk in game.all_perks:
		if perk.id in data.perks_purchased:
			game.apply_perk_effects(perk)
	
	# print(" -- [SAVE] Resources Loading...")
	game.resources = data.resources	# Directly sets resources to avoid StatsManager increment
	# print(" -- [SAVE] Wave Loading...")
	wave.current_wave = data.current_wave
	# print(" -- [SAVE] Boss Wave Loading...")
	wave.next_boss_wave = data.next_boss_wave

	# print(" -- [SAVE] Game Stats Loading...")

	# Sets StatsManager stats (unique, not referenced)
	stats.run = data.stats_run.duplicate(true)

	# print(" -- [SAVE] Defenses Loading...")

	# Spawns defenses based on amount owned in data
	for defense in game.all_defenses:
		var count: int = int(data.defenses_owned.get(defense.id, 0))
		for i in count:
			# spawn_defense() handles registration
			game.spawn_defense(defense)
		defense.is_purchased = count > 0	# Conditional true
		defense.amount_owned = count
	
	# print(" -- [SAVE] Planet Shield Loading...")
	
	# [CRITICAL] Must be applied last to avoid clamping pre-upgrades
	planet.set_shield(data.planet_shield_current)
	
	# print(" -- [SAVE] UI updating...")

	# Updates UI game wide
	game.resources_changed.emit()
	game.stats_changed.emit()

	print(" -- [SAVE] GAME SAVE Loaded! -- ")

## Checks if save file exists | Returns true if exists, false otherwise
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_FILE_PATH)

## Deletes save file from directory
func delete_save() -> void:
	if has_save():
		# DirAccess handles directories and file removal; FileAccess only handles contents
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_FILE_PATH))
		print_rich("[color=red]SaveManager[/color]: Save file Deleted.")
	else:
		push_warning("SaveManager: Attempted save deletion... failed. Save does not exist.")


## Serializes the player's lifetime stats to a JSON file | Returns true if successful, false otherwise
func save_profile() -> bool:
	if profile_save_blocked: return false

	var profile: ProfileData = ProfileData.new()
	profile.version = PROFILE_VERSION
	profile.stats_lifetime = stats.lifetime.duplicate(true)
	return _write_json(PROFILE_FILE_PATH, profile.save_dict())
	
## Checks if current JSON profile is valid, then loads its lifetime stats into StatsManager
## If the file is missing, nothing loads (first launch). If it exists but is unreadable, it's backed up first
## Called via _ready()
func load_profile() -> void:

	var json_dict: Dictionary = _read_json(PROFILE_FILE_PATH, PROFILE_VERSION)
	if json_dict.is_empty():	# Errors return empty Dictionaries

		# File exists but couldn't be loaded (corrupted, wrong version, etc.)
		# Rename it out of the way instead of letting the next save_profile() overwrite it,
		# so lifetime stats can still be recovered by hand
		if FileAccess.file_exists(PROFILE_FILE_PATH):
			# Unix timestamp in the name so multiple backups never overwrite each other
			var unix: int = int(Time.get_unix_time_from_system())
			var backup_path: String = "user://profile_backup_%d.json" % unix
			
			# Copies profile over to a backup file to protect the original data
			var err := DirAccess.rename_absolute(
				ProjectSettings.globalize_path(PROFILE_FILE_PATH),
				ProjectSettings.globalize_path(backup_path)
			)
			# If the backup failed, block profile saving for this session
			# so the damaged original isn't overwritten by fresh (empty) lifetime stats
			if err != OK:
				profile_save_blocked = true
				push_warning("SaveManager: profile could not be loaded, and backup failed (Error %d). Profile saving disabled this session to protect the file." % err)
			else:
				push_warning("SaveManager: profile could not be loaded; file may be damaged. Backed up to profile_backup_%d.json" % unix)

		return	# Nothing to load; stats.lifetime keeps its default values

	print(" -- [SAVE] PROFILE Found. Loading... -- ")

	# Profile is valid: convert the raw Dictionary into ProfileData, then hand its stats to StatsManager
	var profile: ProfileData = ProfileData.new()
	profile.load_dict(json_dict)
	stats.lifetime = profile.stats_lifetime

## Writes a Dictionary to a JSON file at the given path | Returns true if successful, false otherwise
func _write_json(path: String, data: Dictionary) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)

	if file == null:	# Checks if file opening was successful
		# Pushes no save and error message
		push_warning(
			"SaveManager: Could not write file. File '%s' directory may not exist. Error: %d"
			% [path, FileAccess.get_open_error()]
		)
		return false
	
	file.store_string(JSON.stringify(data, "\t"))	# Writes JSON file to file location
	file.close()
	return true

## Reads and validates a JSON file at the given path against the expected version
## Returns the parsed Dictionary | Returns empty Dictionary if file is missing, corrupted, or outdated
func _read_json(path: String, version: int) -> Dictionary:
	
	var empty_dict: Dictionary = {}	# Acts as return 'null'

	# Checks if save is missing -- may be normal for first launch so no warning
	if not FileAccess.file_exists(path):
		return empty_dict

	# Checks if file exists in file path
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning(
			"SaveManager: Load aborted. could not open file '%s' | Error %d" % [path, FileAccess.get_open_error()]
		)
		return empty_dict

	var json_string: String = file.get_as_text()	# Stores file as string
	file.close()									# Closes file: no longer reading it
	var parsed = JSON.parse_string(json_string)		# Parses string, turning it into a dictionary

	# Checks if JSON string didn't parse correctly, indicating wrong JSON file
	if parsed == null:
		push_warning(
			"SaveManager: Load aborted. could not parse file '%s'. File may not be a valid JSON file" % path
		)
		return empty_dict

	# Checks if root of JSON is not a dictionary, indicating wrong JSON structure
	if not parsed is Dictionary:
		push_warning("SaveManager: Load aborted. '%s' File root is not a Dictionary" % path)
		return empty_dict

	# Checks if file version outdated
	# Wrapped with int() since json's parse as floats, avoids narrowing conversion warning
	var file_version: int = int(parsed.get("version", 0))
	if file_version != version:
		push_warning(
			"SaveManager: Load aborted. File '%s' version '%d' does not match current version '%d'."
			% [path, file_version, version]
		)
		# TODO: Decide what happens with outdated save file. Right now they return {} and don't load any saves.
		return empty_dict
	
	return parsed

## Auto-saves game when window closed, as long as a wave isn't active | Called automatically by Godot
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and not wave.wave_active:
		save_all()
