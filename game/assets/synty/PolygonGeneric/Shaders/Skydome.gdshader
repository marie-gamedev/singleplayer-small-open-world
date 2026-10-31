shader_type spatial;

uniform sampler2D Albedo_Map : source_color;
uniform vec4 tint_color: source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform bool enable_albedo_map = false;
uniform bool blend_top_bottom_color = false;
uniform float albedo_rotation_degrees = 0.0;
uniform bool enable_unlit = false;

uniform vec4 top_color: source_color = vec4(0.1, 0.6, 0.9, 1.0);
uniform vec4 bottom_color: source_color = vec4(0.05, 0.3, 0.45, 1.0);
uniform float offset = 32.0;
uniform bool enable_uv_based;
uniform float falloff: hint_range(0.001, 100.0) = 1.0;
uniform float distance_: hint_range(1.0, 10000.0) = 1000.0;

void fragment() {
	float sky_uv;
	if (enable_uv_based) {
		sky_uv = UV.y;
	} else {
		vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
		sky_uv = clamp(pow((world_pos.y + offset) / distance_, falloff), 0.0, 1.0);
	}

	vec3 gradient_color = mix(bottom_color, top_color, sky_uv).rgb;
	vec3 final_color = gradient_color;

	if (enable_albedo_map) {
		// Rotate UV around its center (0.5, 0.5)
		float angle = radians(albedo_rotation_degrees);
		float s = sin(angle);
		float c = cos(angle);
		vec2 centered_uv = UV - vec2(0.5);
		vec2 rotated_uv = vec2(
			centered_uv.x * c - centered_uv.y * s,
			centered_uv.x * s + centered_uv.y * c
		) + vec2(0.5);

		vec4 albedo_tex = texture(Albedo_Map, rotated_uv);
		final_color = mix(gradient_color, albedo_tex.rgb, albedo_tex.a);

		if (blend_top_bottom_color) {
			final_color *= gradient_color;
		}
	}
	
	final_color *= tint_color.rgb;

	if (enable_unlit) {
		ALBEDO = vec3(0.0);
		EMISSION = final_color;
	} else {
		ALBEDO = final_color;
	}

	ROUGHNESS = 0.5;
	AO = 1.0;
}