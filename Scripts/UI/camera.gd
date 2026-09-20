extends Camera2D


@onready var game := Game_Manager

@onready var shop_panel := get_tree().current_scene.get_node("UI/ShopPanel")

@export_category("Settings")

@export_group("Shop Slide")
@export var shop_slide_duration : float = 2
@export var shop_slide_trans : Tween.TransitionType = Tween.TRANS_QUINT
@export var shop_slide_ease : Tween.EaseType = Tween.EASE_IN_OUT

@export_group("Screen Shake")
@export_range(0, 30, 0.5, "or_greater") var shake_amount : float = 10
@export_range(1, 50, 0.5, "or_greater") var shake_decay : float = 25.0

@export_group("Parallax")
@export_range(0,10,0.5) var mouse_parallax_strength : float = 6.0 # from 1 - 10

@export_group("Aspect Compensation")
@export var base_resolution : Vector2 = Vector2(1920, 1080) 		# Matches project.godot's base viewport size
@export_range(0.5, 1.0, 0.01) var min_zoom_factor : float = 0.9 	# Widest allowed zoom-out (tall/narrow screens)
@export_range(1.0, 2.0, 0.01) var max_zoom_factor : float = 1.15	# Tightest allowed zoom-in (ultrawide screens)

@export_group("Player Controls")
@export var zoom_step : float = 0.05
@export var max_zoom : float = 2.0
@export var min_zoom : float = 0.75
var default_zoom : Vector2

@export_group("")

var shake_strength : float = 0.0

var shop_offset : Vector2 = Vector2.ZERO
var shop_open : bool = true
var shop_tween : Tween


func _ready() -> void:
	# Zoom must be set BEFORE reading shop_offset below
	get_viewport().size_changed.connect(_update_aspect_zoom)
	_update_aspect_zoom()
	
	game.planet_hit.connect(_on_planet_hit)

# Gets the new screen size + ratio and adjusts camera to it | Updates on screen resize
func _update_aspect_zoom() -> void:
	var canvas_size = shop_panel.get_parent_area_size()
	var base_aspect = base_resolution.x / base_resolution.y
	var current_aspect = canvas_size.x / canvas_size.y
	
	# How far the current screen's aspect deviates from base, in either direction
	var deviation = max(current_aspect / base_aspect, base_aspect / current_aspect)
	var new_default = Vector2.ONE * clamp(deviation, min_zoom_factor, max_zoom_factor)
	zoom = new_default
	default_zoom = new_default
	
	if shop_tween:
		shop_tween.kill()
	shop_offset = _get_shop_slide_target() if shop_open else Vector2.ZERO

func _on_planet_hit(damage: float) -> void:
	shake_strength = shake_amount * clampf(damage/5.0, 0.5, 2.0)


func _process(delta: float) -> void:
	var mouse_offset = get_mouse_parallax_offset()
	var shake_offset = Vector2(randf_range(-1,1), randf_range(-1,1)) * shake_strength
	
	offset =  mouse_offset + shake_offset + shop_offset
	
	if shake_strength > 0:
		shake_strength = move_toward(shake_strength, 0, shake_decay * delta)
	
	if Input.is_action_just_pressed("ZoomIn"):
		zoom += Vector2(zoom_step,zoom_step)
		zoom = Vector2.ONE * clampf(zoom.x, min_zoom, max_zoom)
	if Input.is_action_just_pressed("ZoomOut"):
		zoom -= Vector2(zoom_step,zoom_step)
		zoom = Vector2.ONE * clampf(zoom.x, min_zoom, max_zoom)
	if Input.is_action_just_pressed("ZoomReset"):
		zoom = default_zoom


func get_mouse_parallax_offset() -> Vector2:
	
	var viewport_size = get_viewport_rect().size
	var center = viewport_size / 2
	var mouse_pos = get_viewport().get_mouse_position()
	
	var normalized_mouse_offset = (mouse_pos - center)/center
	var parallax_strength = mouse_parallax_strength*5
	
	return normalized_mouse_offset * parallax_strength

# Tweens camera to the right | Called via ui._shop_ui()
func set_shop(is_open: bool) -> void:
	shop_open = is_open
	var target = _get_shop_slide_target() if is_open else Vector2.ZERO
	
	if shop_tween:
		shop_tween.kill()	# Quickly stops in-progress motion
	
	shop_tween = create_tween()
	shop_tween.set_trans(shop_slide_trans)
	shop_tween.set_ease(shop_slide_ease)
	shop_tween.tween_property(self, "shop_offset", target, shop_slide_duration)

# Reads shop_panels width to dynamically adjust to any screen size
func _get_shop_slide_target() -> Vector2:
	var canvas_width = shop_panel.get_parent_area_size().x
	var panel_fraction = shop_panel.anchor_right - shop_panel.anchor_left
	var shift_pixels = (panel_fraction / 2.0) * canvas_width
	
	return Vector2(-shift_pixels / zoom.x, 0)
