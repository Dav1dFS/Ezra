shader_type canvas_item;

uniform vec4 color1 : source_color;
uniform vec4 color2 : source_color;
uniform float brightness = 0.0;
uniform sampler2D noise;
uniform float timeOffset = 0.0;
uniform float timeRate = 1.0;
uniform float noiseAmmount = 0.1;
uniform float offsetX = 0.0;
uniform float flickerT = 0.6;
uniform float solid_radius = 0.2;
uniform float dither_amount = 15.0;

uniform float darkness_multiplier = 1.0;
uniform float speed_multiplier_extra = 1.0;

vec4 lerp(vec4 col1, vec4 col2, float t) {
	float r = (col2.r - col1.r) * t + col1.r;
	float g = (col2.g - col1.g) * t + col1.g;
	float b = (col2.b - col1.b) * t + col1.b;
	return vec4(r, g, b, col1.a);
}

void fragment() {
	COLOR = lerp(color1, color2, texture(noise, UV).r);
	COLOR.rgb *= darkness_multiplier;

	// distância radial ao centro (0 = centro)
	float center_dist = distance(UV, vec2(0.5, 0.5));

	// reduz a amplitude do pulso para não abrir tanto
	const float pulse_scale_factor = 0.15;
	const float speed_multiplier = 3.0;

	// PULSE (expansão/contração uniforme) - usa o multiplicador extra de velocidade
	float pulse = 1.0 + sin(TIME * (timeRate * speed_multiplier * speed_multiplier_extra) + timeOffset) * (noiseAmmount * pulse_scale_factor);
	pulse = max(pulse, 0.01);

	// flicker global - também afetado pelo multiplicador de velocidade
	float flickerValue = texture(noise, vec2(TIME * speed_multiplier_extra + timeOffset, (TIME * speed_multiplier_extra + timeOffset) * 0.9)).r;
	if (flickerValue > flickerT) {
		pulse *= flickerValue / (1.0 - flickerT) * 0.62;
	}

	// escalamos a coordenada radial pelo inverso do pulse
	float scaled_center_dist = center_dist / pulse;
	scaled_center_dist = clamp(scaled_center_dist, 0.0, 1.0);

	// dist = 1.0 no centro, decresce para a borda
	float dist = 1.0 - scaled_center_dist;

	// Boost suave de cor no centro
	float centerBoost = smoothstep(solid_radius * 0.0, solid_radius, 1.0 - scaled_center_dist) * 0.35;
	COLOR.rgb = COLOR.rgb * (1.0 + centerBoost);

	// Dentro do raio sólido
	if (center_dist <= solid_radius * pulse) {
		COLOR.a *= dist + brightness;
	} else {
		// Fora do raio sólido: atenuação radial com mistura de ruído estático
		float a = dist + brightness;
		float noiseSample = texture(noise, UV).r;
		a = (a * (2.0 - noiseAmmount) + noiseSample * noiseAmmount) / 2.0;
		a = round(a * dither_amount) / dither_amount;
		COLOR.a *= a;
	}
	COLOR.a = clamp(COLOR.a, 0.0, 1.0);
}