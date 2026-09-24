extends SerializableData
class_name SaveData

# @export is used to set the storage usage flag (PROPERTY_USAGE_STORAGE) for each property.
# This allows the save_dict() function to identify which properties should be included in the saved data.
@export var version: int = 1

@export var resources: int = 0

@export var current_wave: int = 1
@export var next_boss_wave: int = 15

@export var planet_shield_current: float = 0.0

@export var upgrade_levels: Dictionary = { }
@export var defenses_owned: Dictionary = { }
@export var perks_purchased: Array = []

@export var stats_run: Dictionary = { }

@export var saved_at: String = Time.get_datetime_string_from_system()