extends Resource
class_name SerializableData



## Copies every @export var into a Dictionary for JSON serialization | Called via SaveManager
func save_dict() -> Dictionary:
	var data: Dictionary = { }
	for property in get_property_list():
		# Check if the property is marked for storage and is a script variable, then adds it to the data dictionary
		# Usage is a bitmask, so we use a bitwise AND operation ( & ) to check if the flag is identical. If true, it is >1 (true). If false, it equals 0 (false).
		if (
			property.usage & PROPERTY_USAGE_STORAGE
			and property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE
		):
			data[property.name] = get(property.name) # Add the property name and its current value to the data dictionary

	return data


## Restores state from a parsed save Dictionary. Unknown keys warn rather than fail silently | Called via SaveManager.load_game()
func load_dict(data: Dictionary) -> void:
	for key in data.keys():
		# Check if the key from the dictionary corresponds to a property of the class.
		# If it does, set the property to the value from the dictionary.
		# If it does not, log a warning message indicating that the class object has no property with that name- protects against renaming in the future.
		if key in self:
			set(key, data[key])
		else:
			push_warning(
				"[ERROR] Data '%s' has no property named '%s' -- file may be from an older version"
				% [get_script().get_global_name(), key]
			)
