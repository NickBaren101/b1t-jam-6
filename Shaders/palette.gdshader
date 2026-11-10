shader_type canvas_item;

// Full-screen pass: snaps every pixel to the nearer of the game's two colours,
// so sprites, HUD text, tints and placeholders can never add a third one.
uniform vec4 light_color : source_color = vec4(0.5216, 0.1451, 0.1608, 1.0); // (133, 37, 41)
uniform vec4 dark_color : source_color = vec4(0.0, 0.0078, 0.0627, 1.0);     // (0, 2, 16)
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

void fragment() {
	vec3 c = texture(screen_texture, SCREEN_UV).rgb;
	COLOR = distance(c, light_color.rgb) < distance(c, dark_color.rgb) ? light_color : dark_color;
}
