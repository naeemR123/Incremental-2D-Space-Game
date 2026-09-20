class_name ResourceScanner


# Folder-scanner | Used by Game_Mananger and WaveManager



# Static functions keep their inheritance when called ( so not need to write 'Game_Manager.' before register_defense_stats() )

# Scans Resources folder for files (by scanning subfolders using _scan_resource_folder()) then hands it to a registrar 
static func register_folder(path: String, expected_type, registrar: Callable, label: String) -> void:
	var paths := _scan_resource_folder(path)
	
	if paths.is_empty():
		push_warning("[color=red][b][ERROR][/b][/color] No resources found under %s | %s registration aborted" % [path, label])
		return
	
	for file_path in paths:
		var resource = load(file_path)
		if is_instance_of(resource, expected_type):
			registrar.call(resource)
		else:
			push_warning("[color=red][b][ERROR][/b][/color] Unexpected resource type in %s folder: %s" % [label, file_path])
		
	print(" | %s REGISTERED | " % label)

# Scans Folder (and subfolders) for resource files and returns array of every resource
static func _scan_resource_folder(path: String) -> Array[String]:
	var found: Array[String] = []
	
	for file_name in DirAccess.get_files_at(path):
		if file_name.ends_with(".remap"):
			file_name = file_name.trim_suffix(".remap")
		
		if file_name.ends_with(".tres") or file_name.ends_with(".res"):
			found.append(path.path_join(file_name))
		
	for folder_name in DirAccess.get_directories_at(path):
		found.append_array(_scan_resource_folder(path.path_join(folder_name)))
	
	return found
