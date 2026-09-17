extends Resource
class_name SaveData


# @export is used to set the storage usage flag (PROPERTY_USAGE_STORAGE) for each property. 
# This allows the save_dict() function to identify which properties should be included in the saved data.
@export var version: int = 1

@export var resources: int = 0

@export var current_wave: int = 1
@export var next_boss_wave: int = 15

@export var planet_shield_current: float = 0.0

@export var upgrade_levels: Dictionary = {}
@export var defenses_owned: Dictionary = {}
@export var perks_purchased: Array = []

@export var stats_lifetime: Dictionary = {}
@export var stats_run: Dictionary = {}

@export var saved_at: String = Time.get_datetime_string_from_system()


## Copies every @export var into a Dictionary for JSON serialization | Called via SaveManager.save_game()
func save_dict() -> Dictionary:
	var save_data: Dictionary = {}
	for property in get_property_list():
		# Check if the property is marked for storage and is a script variable, then adds it to the save_data dictionary
		# Usage is a bitmask, so we use a bitwise AND operation ( & ) to check if the flag is identical. If true, it is >1 (true). If false, it equals 0 (false).
		if property.usage & PROPERTY_USAGE_STORAGE and property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			save_data[property.name] = get(property.name) # Add the property name and its current value to the save_data dictionary
	
	print(" | SaveData saved | ")
	print(save_data)
	return save_data

## Restores state from a parsed save Dictionary. Unknown keys warn rather than fail silently | Called via SaveManager.load_game()
func load_dict(save_data: Dictionary) -> void:
	for key in save_data.keys():
		# Check if the key from the save_data dictionary corresponds to a property of the SaveData object. 
		# If it does, set the property to the value from the dictionary.
		# If it does not, log a warning message indicating that the SaveData object has no property with that name- protects against renaming in the future.
		if key in self:
			set(key, save_data[key])
		else:
			push_warning("[ERROR] SaveData has no property named '%s' -- save file may be from an older version" % key)
