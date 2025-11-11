shader_type canvas_item;

// Avisa o Godot que queremos acesso à textura do ecrã
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float gamma : hint_range(0.5, 2.0) = 1.0;

void fragment() {
    // Lê o conteúdo do ecrã
    vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV);
    // Aplica correção de gamma
    color.rgb = pow(color.rgb, vec3(1.0 / gamma));
    COLOR = color;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}