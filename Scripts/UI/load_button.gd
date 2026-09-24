extends Button

@onready var save: SaveManager = SaveManager


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_on_button_pressed)


## Reloads the last save | Same operation as restarting the wave
func _on_button_pressed() -> void:
	if not save.has_save():
		push_warning("Load button: no save file to load.")
		return
	Game_Manager.restart_wave()
