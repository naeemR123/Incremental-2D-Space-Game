extends Node2D


@onready var wave := WaveManager

@onready var dot: ColorRect = $ColorRect



@export var dot_size : float = 20




# - Displays dot in place of mouse for shop



func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN	# Hides OS mouse
	
	dot.size = Vector2.ONE * dot_size
	dot.position = Vector2(-dot_size/2,-dot_size/2)

func _process(_delta: float) -> void:
	# Tracks dot to mouse lcoation
	dot.global_position = get_global_mouse_position()
	
	if Input.is_action_just_pressed("ToggleCursor"):
		if Input.mouse_mode == Input.MOUSE_MODE_HIDDEN:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

## Shows or Hides dot based on toggle
func show_dot(can_see: bool) -> void:
	dot.visible = can_see
	print("dot is set: ", can_see)
	print("dot is:", dot.visible)
