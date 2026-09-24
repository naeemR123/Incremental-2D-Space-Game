extends Button

@onready var save: SaveManager = SaveManager


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	# Mid-wave saves would let a player bank a wave's resources and replay it
	if WaveManager.wave_active:
		push_warning("Save button: can't save during a wave.")
		return
	save.save_all()
	print("Game saved!")
