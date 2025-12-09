shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(0.0, 1.0, 0.5, 1.0);
uniform float glow_size : hint_range(0.1, 1.0) = 0.5;
uniform float glow_intensity : hint_range(0.0, 2.0) = 1.0;
uniform float edge_softness : hint_range(0.0, 1.0) = 0.3;

void fragment() {
	vec2 center = vec2(0.5, 0.5);
	float dist = distance(UV, center);
	
	float glow = 1.0 - smoothstep(0.0, glow_size, dist);
	glow = pow(glow, 1.0 - edge_softness);
	
	COLOR = glow_color;
	COLOR.a = glow * glow_intensity;
}