shader_type canvas_item;

uniform vec3 gold_tint: source_color = vec3(1.0, 0.686, 0.0);
uniform float tint_amplitude: hint_range(0.0, 4.0, 0.01) = 2.0;

// instance uniform = one value per CanvasItem, shared material
// can be reached by $Node.set_instance_shader_parameter()
instance uniform float tint_strength: hint_range(0.0, 2.0, 0.01) = 0.0;

void vertex() {
	// Called for every vertex the material is visible on.
	vec3 tint = pow(gold_tint, vec3(tint_amplitude)) * tint_strength;
	
	COLOR = vec4(COLOR.rgb + tint, COLOR.a);
}
