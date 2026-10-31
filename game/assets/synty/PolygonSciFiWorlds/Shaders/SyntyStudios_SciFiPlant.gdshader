shader_type spatial;
render_mode cull_disabled, world_vertex_coords;

uniform sampler2D albedo_texture : source_color, hint_default_white, filter_linear_mipmap;
uniform sampler2D plant_mask_texture : source_color, hint_default_white, filter_linear_mipmap;
uniform float wind_texture_scale = 0.05;
uniform sampler2D wind_noise_texture : hint_default_white, repeat_enable;
uniform float roughness: hint_range(0.0, 1.0) = 0.8;

uniform vec4 plant_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 emissive_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

//vertex - wind
uniform vec2  wind_direction = vec2(1.0, 0.4); 
uniform float wind_pan_speed = 0.15;
uniform float wind_strength = 0.3;

//vertex movement for wind effect
void vertex() {
    vec3 world_pos = VERTEX;
    vec4 vertex_mask = COLOR;
    float mask = dot(vertex_mask, vec4(1,0,0,0));
    vec2 wind_dir_n = normalize(wind_direction);
    vec2 wind_uv = world_pos.xz * wind_texture_scale + wind_dir_n * TIME * wind_pan_speed;
    float wind_sample = texture(wind_noise_texture, wind_uv).r;
    float wind = (wind_sample * 2.0 - 1.0);
    vec3 offset = vec3(wind_dir_n.x, 0.0, wind_dir_n.y) * wind * wind_strength * mask;

    VERTEX += offset;
}

void fragment() {
	vec4 base_tex = texture(albedo_texture, UV);
	vec4 mask_tex = texture(plant_mask_texture, UV);
	
	
	vec3 albedo_mix = base_tex.rgb * plant_color.rgb;
	vec3 emission_tex_mix = base_tex.rgb * (emissive_color.rgb * mask_tex.rgb);
	
    ALBEDO = albedo_mix.rgb;
	EMISSION = emission_tex_mix.rgb;
	ROUGHNESS = roughness;
}