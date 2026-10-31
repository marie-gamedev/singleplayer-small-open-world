shader_type spatial;
render_mode  blend_mix, depth_draw_opaque, depth_test_default, cull_back, diffuse_lambert, specular_schlick_ggx ;

uniform sampler2D main_texture : source_color, hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D hololines_texture : hint_default_black, filter_linear_mipmap, repeat_enable;
uniform float hologram_world_scale : hint_range(0.01, 10.0) = 1.0;
uniform vec4 neon_color : source_color = vec4(0.1, 0.9, 1.0, 1.0);
uniform float emission_power : hint_range(0.0, 10.0) = 3.0;
uniform float scroll_speed : hint_range(0.0, 10.0) = 1.0;
uniform float opacity : hint_range(0.0, 1.0) = 0.6;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {

	vec4 base_tex = texture(main_texture, UV);
	vec2 world_uv = world_pos.xy * hologram_world_scale;
	vec3 neon_color_mix = mix(neon_color.rgb, vec3(0,0,0), 0.3);
	world_uv.y += TIME * scroll_speed;
	vec4 holo_tex = texture(hololines_texture, world_uv);
	vec3 emission_lines = holo_tex.rgb * neon_color_mix.rgb;
	vec3 tinted_albedo =  base_tex.rgb * (neon_color_mix.rgb + emission_lines.rgb );

	ALBEDO = base_tex.rgb;
	EMISSION = tinted_albedo.rgb * emission_power;
	//neon_color.rgb * emission_power;
	//neon_color.rgb + (emission_lines.rgb * emission_power);
	ALPHA = opacity;
}