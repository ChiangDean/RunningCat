shader_type canvas_item;

uniform float desaturate_strength : hint_range(0.0, 1.0) = 0.42;

void fragment() {
	vec4 source = texture(TEXTURE, UV) * COLOR;
	float luma = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	vec3 gray = vec3(luma);
	source.rgb = mix(source.rgb, gray, desaturate_strength);
	COLOR = source;
}
