shader_type canvas_item;

uniform float size : hint_range(0.0, 0.5, 0.01) = 0.5;
uniform float softness : hint_range(0.0, 0.5, 0.01) = 0.5;

uniform float glint_speed : hint_range(0.0, 10.0, 0.01) = 7.0;
uniform float glint_interval : hint_range(0.0, 1.0, 0.01) = 0.5;

uniform float phase_offset = 0.0;

void fragment() {
	// Called for every pixel the material is visible on.
	vec4 base = COLOR;
	
	float coord = (UV.x + UV.y) * 0.5;
	float phase = fract(TIME * glint_interval + phase_offset);
	float center = phase * glint_speed;
	float dist = abs(coord - (center-0.5));
	float band = 1.0 - smoothstep(size, size + softness, dist);
	
	
	COLOR = vec4(base.rgb + band * base.a, base.a);
}
