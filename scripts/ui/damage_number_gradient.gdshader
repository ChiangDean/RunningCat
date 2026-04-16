shader_type canvas_item;

uniform vec4 top_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 mid_color : source_color = vec4(1.0, 0.9, 0.4, 1.0);
uniform vec4 bottom_color : source_color = vec4(1.0, 0.8, 0.2, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float t = clamp(UV.y, 0.0, 1.0);
	vec4 gradient = t < 0.5
		? mix(top_color, mid_color, t * 2.0)
		: mix(mid_color, bottom_color, (t - 0.5) * 2.0);
	COLOR = vec4(gradient.rgb, tex.a * COLOR.a);
}
