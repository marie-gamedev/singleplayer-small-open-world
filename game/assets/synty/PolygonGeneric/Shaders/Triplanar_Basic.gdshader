shader_type spatial;
render_mode blend_mix, depth_draw_opaque, depth_test_default, cull_back, diffuse_lambert, specular_schlick_ggx, world_vertex_coords;

uniform sampler2D Albedo_Map2 : source_color;
uniform sampler2D Overlay_Map : source_color;
uniform float overlay_intensity = 1.0;
uniform float Metallic = 0.0;
uniform float Smoothness = 0.5;
uniform sampler2D Normal_Map : hint_normal;


// TextureParameterTriplanar
	vec4 triplanar_texture(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos) {
		vec4 samp = vec4(0.0);
		samp += texture(p_sampler, p_triplanar_pos.xy) * p_weights.z;
		samp += texture(p_sampler, p_triplanar_pos.xz) * p_weights.y;
		samp += texture(p_sampler, p_triplanar_pos.zy * vec2(-1.0, 1.0)) * p_weights.x;
		return samp;
	}

	uniform vec3 triplanar_scale = vec3(1.0, 1.0, 1.0);
	uniform vec3 triplanar_offset;
	uniform float triplanar_sharpness = 0.5;

	varying vec3 triplanar_power_normal;
	varying vec3 triplanar_pos;

void vertex() {
// TextureParameterTriplanar
	{
		triplanar_power_normal = pow(abs(NORMAL), vec3(triplanar_sharpness));
		triplanar_power_normal /= dot(triplanar_power_normal, vec3(1.0));
		triplanar_pos = VERTEX * triplanar_scale + triplanar_offset;
		triplanar_pos *= vec3(1.0, -1.0, 1.0);
	}
}

void fragment() {
	vec4 n_out31p0;
// Texture2D:31
	n_out31p0 = texture(Albedo_Map2, UV);


// TextureParameterTriplanar:26
	vec4 n_out26p0 = triplanar_texture(Overlay_Map, triplanar_power_normal, triplanar_pos);


// FloatParameter:28
	float n_out28p0 = overlay_intensity;


// FloatOp:27
	float n_out27p0 = pow(n_out26p0.x, n_out28p0);


// VectorOp:29
	vec3 n_out29p0 = vec3(n_out31p0.xyz) * vec3(n_out27p0);


// FloatParameter:6
	float n_out6p0 = Metallic;


// Clamp:7
	float n_in7p1 = 0.00000;
	float n_in7p2 = 1.00000;
	float n_out7p0 = clamp(n_out6p0, n_in7p1, n_in7p2);


// FloatParameter:8
	float n_out8p0 = Smoothness;


// FloatFunc:11
	float n_out11p0 = 1.0 - n_out8p0;


// Clamp:9
	float n_in9p1 = 0.00000;
	float n_in9p2 = 1.00000;
	float n_out9p0 = clamp(n_out11p0, n_in9p1, n_in9p2);


	vec4 n_out21p0;
// Texture2D:21
	n_out21p0 = texture(Normal_Map, UV);


// Output:0
	ALBEDO = n_out29p0;
	METALLIC = n_out7p0;
	ROUGHNESS = n_out9p0;
	NORMAL_MAP = vec3(n_out21p0.xyz);


}
