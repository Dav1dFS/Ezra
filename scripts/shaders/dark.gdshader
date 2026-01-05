shader_type canvas_item;

uniform float radius:    hint_range(0.0, 1.0) = 0.07;
uniform float softness:  hint_range(0.0, 1.0) = 0.647;
uniform float intensity: hint_range(0.0, 3.0) = 1.096;
uniform float contrast:  hint_range(0.5, 4.0) = 1.2;
uniform vec4 vignette_color: source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
    vec2 uv = SCREEN_UV;
    vec2 centered = uv - vec2(0.5);

    float edge_box = max(abs(centered.x) * 2.0, abs(centered.y) * 2.0);

    float edge_radial = length(centered) * 2.0;
    float shape = mix(edge_box, edge_radial, 0.25);

    float v = smoothstep(radius, radius + softness, shape);
    v = pow(v, contrast);

    vec4 overlay = vignette_color;
    overlay.a = clamp(v * intensity, 0.0, 1.0);

    COLOR = overlay;
}
