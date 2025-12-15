shader_type canvas_item;

uniform sampler2D noise_texture : repeat_enable, filter_nearest;

uniform float density = 2.5;
uniform vec2 speed = vec2(0.02, 0.01);
uniform int layers = 3;
uniform float noise_scale = 1.0;
uniform float contrast = 1.5;
uniform float min_threshold = 0.3;
uniform float edge_softness = 0.2;
uniform vec2 clear_center = vec2(0.5, 0.5); // centro do mapa (UV)
uniform vec2 clear_size = vec2(0.4, 0.3);   // área sem fog
uniform float clear_softness = 0.05;

void fragment() {
	float final_fog = 0.0;

	for (int i = 0; i < layers; i++) {
		float layer_offset = float(i) * 0.5;
		vec2 uv = UV * noise_scale + speed * TIME + vec2(layer_offset);
		float noise = texture(noise_texture, uv).r;
		noise = pow(noise, contrast);
		final_fog += noise;
	}

	final_fog /= float(layers);
	final_fog = max(final_fog, min_threshold);
	final_fog = smoothstep(edge_softness, 1.0, final_fog);

	/* -------------------------
	   MÁSCARA DO CENTRO
	------------------------- */
	vec2 half_size = clear_size * 0.5;
	vec2 delta = abs(UV - clear_center);

	float mask_x = smoothstep(half_size.x, half_size.x + clear_softness, delta.x);
	float mask_y = smoothstep(half_size.y, half_size.y + clear_softness, delta.y);

	float clear_mask = max(mask_x, mask_y);

	COLOR.a *= final_fog * density * clear_mask;
}