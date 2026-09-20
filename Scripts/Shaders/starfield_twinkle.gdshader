shader_type canvas_item;
// Runs on any 2D visual node (Sprite2D, etc.)

// Tweakable in Inspector, like @export_range
uniform float twinkle_speed : hint_range(0.1, 10.0) = 2.0;// Tweakable ^ - higher == faster blink
uniform float twinkle_intensity : hint_range(0.0, 1.0) = 0.5;// Tweakable ^ - how deep stars dim

// Called for every pixel the material is visible on.
void fragment() {	// Built-in Function | Runs Per pixel, per frame, on GPU
	vec4 tex_color = texture(TEXTURE, UV);	// Reads property of the pixel, like get_pixel(x, y)
	float star_brightness = tex_color.r;	// Defines star_brightness == pixel's red value
	
	// Reads baked-in per-star phase, scaled to radians
	float phase = tex_color.b * 6.283185;	// 2*pi - one full sine cycle
	
	// Oscillates 0-1 based on twinkle speed and an offset in time by 'phase' per star
	float twinkle = sin(TIME * twinkle_speed + phase) * 0.5 + 0.5;
	float brightness_mult = mix(1.0 - twinkle_intensity, 1.0, twinkle); // mix() = GDScript's lerp()
	
	// Final output: Setting the RGBA of the pixel | Basically return
	COLOR = vec4(vec3(star_brightness * brightness_mult), tex_color.a);
}
