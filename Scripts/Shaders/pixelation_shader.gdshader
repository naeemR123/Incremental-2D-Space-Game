shader_type canvas_item;

uniform float block_size : hint_range(1.0, 32.0) = 3.0;
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

	// Called for every pixel the material is visible on.
void fragment() {
	
	vec2 screen_px = SCREEN_UV / SCREEN_PIXEL_SIZE;
	
	vec2 snapped = floor(screen_px / block_size) * block_size + block_size * 0.5;
	
	COLOR = texture(screen_texture, snapped * SCREEN_PIXEL_SIZE);
}