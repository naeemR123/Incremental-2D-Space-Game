shader_type canvas_item;

uniform sampler2D surface_texture : source_color, filter_linear, repeat_enable;
uniform float rotation_speed : hint_range(-0.5, 0.5) = 0.05;

uniform float axial_tilt : hint_range(-90, 90) = 20.0;
uniform float axial_roll : hint_range(-180, 180) = -15.0;

uniform float light_angle : hint_range(0.0, 360) = 45.0;
uniform float light_elevation : hint_range(-90, 90) = 10.0;
uniform float ambient : hint_range(0.0, 1.0) = 0.12;
uniform float terminator_softness : hint_range(0.01, 0.6) = 0.15;

uniform float limb_darkening : hint_range(0.0, 1.0) = 0.6;
uniform float edge_softness : hint_range(0.0, 0.1) = 0.01;

void fragment() {
	vec2 centered = (UV - 0.5) * 2.0;
	float dist = length(centered);
	if (dist > 1.0) {
		discard;
	}
	
	float z = sqrt(max(0.0, 1.0 - dist * dist));
	vec3 view_normal = vec3(centered.x, centered.y, z);
	
	float roll = radians(axial_roll);
	float tilt = radians(axial_tilt);
	
	vec3 p = view_normal;
	
	float cr = cos(-roll);
	float sr = sin(-roll);
	p = vec3(p.x * cr - p.y * sr, p.x * sr + p.y * cr, p.z);
	
	float ct = cos(tilt);
	float st = sin(tilt);
	p = vec3(p.x, p.y * ct - p.z * st, p.y * st + p.z * ct);
	
	float longtitude = atan(p.x, p.z) / TAU + 0.5 + TIME * rotation_speed;
	float latitude = asin(clamp(p.y, -1.0, 1.0)) / PI + 0.5;
	vec4 surface = texture(surface_texture, vec2(longtitude, latitude));
	
	float a = radians(light_angle);
	float e = radians(light_elevation);
	vec3 light_dir = normalize(vec3(cos(a) * cos(e), -sin(a) * cos(e), sin(e)));
	
	float lambert = dot(view_normal, light_dir);
	float day = smoothstep(-terminator_softness, terminator_softness, lambert);
	float light = mix(ambient, 1.0, day);
	
	float limb = mix(1.0 - limb_darkening, 1.0, z);
	float edge_alpha = 1.0 - smoothstep(1.0 - edge_softness, 1.0, dist);
	
	COLOR = vec4(surface.rgb * light * limb, surface.a * edge_alpha);
	
}
