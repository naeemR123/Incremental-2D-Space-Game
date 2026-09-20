extends Camera2D


@onready var game := Game_Manager



@export_category("Settings")

@export_group("Screen Shake")
@export_range(0, 30, 0.5, "or_greater") var shake_amount : float = 10
@export_range(1, 50, 0.5, "or_greater") var shake_decay : float = 25.0

@export_group("Parallax")
@export_range(0,10,0.5) var mouse_parallax_strength : float = 6.0 # from 1 - 10

@export_group("")

var shake_strength : float = 0.0



func _ready() -> void:
	game.shield_changed.connect(_on_shield_changed)


func _on_shield_changed() -> void:
	shake_strength = shake_amount


func _process(delta: float) -> void:
	var mouse_offset = get_mouse_parallax_offset()
	var shake_offset = Vector2(randf_range(-1,1), randf_range(-1,1)) * shake_strength
	
	offset =  mouse_offset + shake_offset
	
	if shake_strength > 0:
		shake_strength = move_toward(shake_strength, 0, shake_decay * delta)
	

func get_mouse_parallax_offset() -> Vector2:
	
	var viewport_size = get_viewport_rect().size
	var center = viewport_size / 2
	var mouse_pos = get_viewport().get_mouse_position()
	
	var normalized_mouse_offset = (mouse_pos - center)/center
	var parallax_strength = mouse_parallax_strength*5
	
	
	return normalized_mouse_offset * parallax_strength
