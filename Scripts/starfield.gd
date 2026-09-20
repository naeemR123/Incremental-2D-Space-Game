extends Node2D



@onready var far_layer: Parallax2D = $FarLayer
@onready var far_sprite : Sprite2D = $FarLayer/Sprite2D

@onready var mid_layer: Parallax2D = $MidLayer
@onready var mid_sprite: Sprite2D = $MidLayer/Sprite2D

@onready var near_layer: Parallax2D = $NearLayer
@onready var near_sprite: Sprite2D = $NearLayer/Sprite2D

@onready var near2_layer: Parallax2D = $Near2Layer
@onready var near2_sprite: Sprite2D = $Near2Layer/Sprite2D


@export_group("Far Parallax")
@export var far_star_count : int = 150
@export var far_star_size : int 
@export var far_texture_size : Vector2i = Vector2i(640, 360)
@export var far_scroll_scale : float = 0.1
@export var far_autoscroll : Vector2
@export var far_repeat_times : int = 4 

@export_group("Mid Parallax")
@export var mid_star_count : int = 150
@export var mid_star_size : int 
@export var mid_texture_size : Vector2i = Vector2i(640, 360)
@export var mid_scroll_scale : float = 0.3
@export var mid_autoscroll : Vector2
@export var mid_repeat_times : int = 4 

@export_group("Near Parallax")
@export var near_star_count : int = 150
@export var near_star_size : int 
@export var near_texture_size : Vector2i = Vector2i(640, 360)
@export var near_scroll_scale : float = 0.6
@export var near_autoscroll : Vector2
@export var near_repeat_times : int = 4 
@export_group("")

@export_group("Near2 Parallax")
@export var near2_star_count : int = 150
@export var near2_star_size : int 
@export var near2_texture_size : Vector2i = Vector2i(640, 360)
@export var near2_scroll_scale : float = 0.6
@export var near2_autoscroll : Vector2
@export var near2_repeat_times : int = 4 
@export_group("")



func _ready() -> void:
	
	
	# [FAR] LAYER ASSIGNMENT
	var far_texture = generate_starfield_texture(far_texture_size, far_star_count, far_star_size) 
	far_sprite.texture = far_texture
	far_layer.repeat_size = Vector2(far_texture_size)
	far_layer.scroll_scale = Vector2(far_scroll_scale,far_scroll_scale)
	far_layer.autoscroll = Vector2(far_autoscroll)
	far_layer.repeat_times = far_repeat_times
	
	# [MID] LAYER ASSIGNMENT
	var mid_texture = generate_starfield_texture(mid_texture_size, mid_star_count, mid_star_size)
	mid_sprite.texture = mid_texture
	mid_layer.repeat_size = Vector2(mid_texture_size)
	mid_layer.scroll_scale = Vector2(mid_scroll_scale,mid_scroll_scale)
	mid_layer.autoscroll = Vector2(mid_autoscroll)
	mid_layer.repeat_times = mid_repeat_times
	
	# [NEAR] LAYER ASSIGNMENT
	var near_texture = generate_starfield_texture(near_texture_size, near_star_count, near_star_size)
	near_sprite.texture = near_texture
	near_layer.repeat_size = Vector2(near_texture_size)
	near_layer.scroll_scale = Vector2(near_scroll_scale,near_scroll_scale)
	near_layer.autoscroll = Vector2(near_autoscroll)
	near_layer.repeat_times = near_repeat_times
	
	# [NEAR2] LAYER ASSIGNMENT
	var near2_texture = generate_starfield_texture(near2_texture_size, near2_star_count, near2_star_size)
	near2_sprite.texture = near2_texture
	near2_layer.repeat_size = Vector2(near2_texture_size)
	near2_layer.scroll_scale = Vector2(near2_scroll_scale,near2_scroll_scale)
	near2_layer.autoscroll = Vector2(near2_autoscroll)
	near2_layer.repeat_times = near2_repeat_times
	

# Creates Transparent Image based on parameters
# Procederally generates random star-map on game startup
func generate_starfield_texture(size: Vector2i, star_count: int, star_size: int) -> ImageTexture:
	
	# Creates image from parameter size, with no mipmaps, and formated for RGBA 8-bit
	var image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0,0,0,0))	# Fills entire image as transparent
	
	# Turns star_size into a float and rounds it up
	var radius = float(star_size)
	var r = ceili(radius)
	
	# Runs loop based on parameter star_count | Creates stars in random places
	for i in star_count:
		
		# Creates star based on parameter star_size, then assigns its brightness
		var cx = randi_range(r, size.x - 1 - r)
		var cy = randi_range(r, size.y - 1 - r)
		var brightness = randf_range(0.3, 0.8)
		var phase = randf()	# unique per star
		
		# Places pixels in the randomized location, overwriting the transparent pixels, 
		# and loops - placing more pixels beside it based on parameter star_size.
		# Then determines how far away it is from center of star size, 
		# and decreases its transparancy based on it.
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				var dist = Vector2(dx,dy).length()
				if dist <= radius:
					var alpha = 1.0 - (dist / radius)
					var px = cx + dx
					var py = cy + dy
					if alpha > image.get_pixel(px, py).a:
						image.set_pixel(px, py, Color(brightness, brightness, phase, alpha))
	
	# Returns the completed image as a Texture, converted from the pixel grid
	return ImageTexture.create_from_image(image)
