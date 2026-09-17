extends Node


const SAVE_FILE_PATH: String = "user://savegame.json"
const SAVE_VERSION: int = 1



func _ready() -> void:
	save_game() # For testing | Remove in production


func save_game() -> bool:
	
	var save_data: SaveData = SaveData.new()
	save_data.version = SAVE_VERSION
	save_data.current_wave = WaveManager.current_wave
	
	var json_string: String = JSON.stringify(save_data.save_dict(), "\t")
	var file: FileAccess = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	
	if file:
		file.store_string(json_string)
		file.close()
		return true
	return false


func load_game() -> bool:
	
	var file: FileAccess = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	
	if file:
		
		