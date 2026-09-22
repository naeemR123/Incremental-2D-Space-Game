extends Button

@onready var save: SaveManager = SaveManager


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	save.load_game()
	print("Game loaded!")
	print(WaveManager.current_wave)
