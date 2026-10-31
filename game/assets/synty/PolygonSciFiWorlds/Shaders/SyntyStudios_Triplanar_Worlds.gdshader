shader_type spatial;
render_mode blend_mix, depth_draw_opaque, depth_test_default, cull_back, diffuse_lambert, specular_schlick_ggx, world_vertex_coords;

uniform sampler2D albedo_texture : source_color;
uniform sampler2D dirt_overlay_texture : source_color, hint_default_white;
uniform bool invert_dirt_overlay = false;
uniform float dirt_amount : hint_range(0.0, 1.0) = 0.5;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float smoothness : hint_range(0.0, 1.0) = 0.8;
uniform sampler2D emission_texture : source_color, hint_default_black;
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform sampler2D normal_texture : hint_normal;

uniform vec3 triplanar_scale = vec3(1.0, 1.0, 1.0);
uniform vec3 triplanar_offset;
uniform float triplanar_sharpness = 0.5;

varying vec3 triplanar_power_normal;
varying vec3 triplanar_pos;

vec4 triplanar_texture(sampler2D tex, vec3 weights, vec3 pos) {
	vec4 result = vec4(0.0);
	result += texture(tex, pos.xy) * weights.z;
	result += texture(tex, pos.xz) * weights.y;
	result += texture(tex, pos.zy * vec2(-1.0, 1.0)) * weights.x;
	return result;
}

void vertex() {
	triplanar_power_normal = pow(abs(NORMAL), vec3(triplanar_sharpness));
	triplanar_power_normal /= dot(triplanar_power_normal, vec3(1.0));
	triplanar_pos = VERTEX * triplanar_scale + triplanar_offset;
	triplanar_pos *= vec3(1.0, -1.0, 1.0);
}

void fragment() {
	vec4 base_color = texture(albedo_texture, UV);
	vec4 dirt_sample = triplanar_texture(dirt_overlay_texture, triplanar_power_normal, triplanar_pos);

	vec3 dirt_color = dirt_sample.rgb;
	if (invert_dirt_overlay) {
		dirt_color = vec3(1.0) - dirt_color;
	}

	vec3 dirt_multiply = mix(vec3(1.0), dirt_color, dirt_amount);

	vec4 emission_sample = texture(emission_texture, UV);

	ALBEDO = base_color.rgb * dirt_multiply;
	METALLIC = metallic;
	ROUGHNESS = 1.0 - smoothness;
	EMISSION = emission_sample.rgb * emission_color.rgb;
	NORMAL_MAP = texture(normal_texture, UV).rgb;
}
