shader_type canvas_item;

uniform vec4 color1 : source_color = vec4(0.0, 0.0, 0.0, 0.62);
uniform vec4 color2 : source_color = vec4(0.0, 0.72, 0.0, 0.69);
uniform float brightness = -0.3;
uniform sampler2D noise;
uniform float timeOffset = 1.77;
uniform float timeRate = 0.765;
uniform float noiseAmmount = -0.265;
uniform float offsetX = 1.205;
uniform float flickerT = 0.495;
uniform float solid_radius = 0.05;
uniform float dither_amount = 24.0;

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

	float center_dist = distance(UV, vec2(0.5, 0.5));

	const float pulse_scale_factor = 0.15;
	const float speed_multiplier = 3.0;

	float pulse = 1.0 + sin(TIME * (timeRate * speed_multiplier * speed_multiplier_extra) + timeOffset) * (noiseAmmount * pulse_scale_factor);
	pulse = max(pulse, 0.01);

	float flickerValue = texture(noise, vec2(TIME * speed_multiplier_extra + timeOffset, (TIME * speed_multiplier_extra + timeOffset) * 0.9)).r;
	if (flickerValue > flickerT) {
		pulse *= flickerValue / (1.0 - flickerT) * 0.62;
	}

	float scaled_center_dist = center_dist / pulse;
	scaled_center_dist = clamp(scaled_center_dist, 0.0, 1.0);

	float dist = 1.0 - scaled_center_dist;

	float centerBoost = smoothstep(solid_radius * 0.0, solid_radius, 1.0 - scaled_center_dist) * 0.35;
	COLOR.rgb = COLOR.rgb * (1.0 + centerBoost);

	if (center_dist <= solid_radius * pulse) {
		COLOR.a *= dist + brightness;
	} else {
		float a = dist + brightness;
		float noiseSample = texture(noise, UV).r;
		a = (a * (2.0 - noiseAmmount) + noiseSample * noiseAmmount) / 2.0;
		a = round(a * dither_amount) / dither_amount;
		COLOR.a *= a;
	}
	COLOR.a = clamp(COLOR.a, 0.0, 1.0);
}