shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

// BASE
uniform sampler2D Main_Texture : source_color, hint_default_black;
uniform sampler2D normal_main : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D Rock_Mask_Triplanar : filter_linear_mipmap, repeat_enable;

uniform sampler2D Ground_Mask_Triplanar : hint_default_black, filter_linear_mipmap, repeat_enable;
uniform sampler2D Noise : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_rock : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_triplanar : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D Emissive : source_color, hint_default_black;

// CONST COLORS - FLOATS
uniform vec4 Ground_Color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 Rock_Color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 Road_Color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float Smoothness : hint_range(0.0, 1.0) = 0.8;
uniform float Metallic : hint_range(0.0, 1.0) = 0;


uniform float ground_detail_scale = 0.5;
uniform float ground_detail_power : hint_range(0.0, 3.0) = 1.0;

uniform float triplanar_sharpness : hint_range(1.0, 16.0) = 4.0;


uniform float ground_pebble_scale : hint_range(0.0, 0.3) = 0.1;


uniform float ground_falloff : hint_range(0, 2) = 0.5;

uniform bool noise_use_triplanar = false;
uniform float noise_scale : hint_range(0.0, 1.0) = 0.05;

uniform float noise_edge : hint_range(0.0, 0.5) = 0.1;


varying vec3 world_pos;
varying vec3 world_nrm;

varying vec3 tri_weights;
varying vec3 tri_pos;
varying vec3 nrm_pos;     // unflipped object-space position for normal projection
varying vec3 obj_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_nrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);

	vec3 w = pow(abs(NORMAL), vec3(triplanar_sharpness));
	tri_weights = w / dot(w, vec3(1.0));
	nrm_pos = VERTEX;
	tri_pos = nrm_pos * vec3(1.0, -1.0, 1.0);
	obj_normal = NORMAL;
}


vec4 triplanar(sampler2D tex, vec3 pos, vec3 w, float scale) {
	w /= (w.x + w.y + w.z); 
	vec4 x = texture(tex, pos.zy * scale);
	vec4 y = texture(tex, pos.xz * scale);
	vec4 z = texture(tex, pos.xy * scale);
	return x * w.x + y * w.y + z * w.z;
}


vec3 unpack_normal(vec4 c) {
	vec3 n;
	n.xy = c.rg * 2.0 - 1.0;
	n.z = sqrt(max(1.0 - dot(n.xy, n.xy), 0.0));
	return n;
}


vec3 triplanar_normal(sampler2D tex, vec3 pos, vec3 n, float scale) {
	vec3 w = pow(abs(n), vec3(triplanar_sharpness));
	w /= (w.x + w.y + w.z);

	vec3 tx = unpack_normal(texture(tex, pos.zy * scale));
	vec3 ty = unpack_normal(texture(tex, pos.xz * scale));
	vec3 tz = unpack_normal(texture(tex, pos.xy * scale));

	tx = vec3(tx.xy + n.zy, abs(tx.z) * n.x);
	ty = vec3(ty.xy + n.xz, abs(ty.z) * n.y);
	tz = vec3(tz.xy + n.xy, abs(tz.z) * n.z);

	return normalize(tx.zyx * w.x + ty.xzy * w.y + tz.xyz * w.z);
}

vec3 triplanar_normal_obj(sampler2D tex, vec3 pos, vec3 n, vec3 w, float scale) {
	w /= (w.x + w.y + w.z);

	vec3 tx = unpack_normal(texture(tex, pos.zy * scale));
	vec3 ty = unpack_normal(texture(tex, pos.xz * scale));
	vec3 tz = unpack_normal(texture(tex, pos.xy * scale));

	tx.y = -tx.y;
	tz.y = -tz.y;

	tx = vec3(tx.xy + n.zy, abs(tx.z) * n.x);
	ty = vec3(ty.xy + n.xz, abs(ty.z) * n.y);
	tz = vec3(tz.xy + n.xy, abs(tz.z) * n.z);

	return normalize(tx.zyx * w.x + ty.xzy * w.y + tz.xyz * w.z);
}

void fragment() {
	vec3 wn = normalize(world_nrm);
	float top_world_mask = smoothstep(1.0 - ground_falloff, 1.0, wn.y);

	float glossiness = 1.0 - Smoothness;

	vec3 rock_tri = triplanar(Rock_Mask_Triplanar, tri_pos, tri_weights, ground_pebble_scale).rgb;

	vec3 main_albedo = texture(Main_Texture, UV).rgb;
	vec3 emissive_col = texture(Emissive, UV).rgb;

	float noise_val = noise_use_triplanar
			? triplanar(Noise, tri_pos, tri_weights, noise_scale).r
			: texture(Noise, UV).r;

	vec3 ground_mask = texture(Ground_Mask_Triplanar, UV).rgb;

	vec3 albedo_ground_mix = mix(main_albedo, Rock_Color.rgb, ground_mask.r);
	vec3 road_color_mix    = mix(albedo_ground_mix, Road_Color.rgb, ground_mask.b);
	vec3 ground_road_mix   = mix(Ground_Color.rgb, Road_Color.rgb, ground_mask.b);
	vec3 rock_road_mix     = mix(ground_road_mix, Rock_Color.rgb, rock_tri.r);

	float ground_amt = smoothstep(noise_val - noise_edge, noise_val + noise_edge, top_world_mask);

	ground_amt = clamp(mix(ground_amt, 1.0, ground_mask.g), 0.0, 1.0);

	vec3 main_texture_mix = mix(road_color_mix, rock_road_mix, ground_amt);

	ALBEDO = main_texture_mix;
	ROUGHNESS = glossiness;
	METALLIC = Metallic;
	EMISSION = emissive_col;


	float mask_g_invert = 1.0 - ground_mask.g;

	vec3 tn = unpack_normal(texture(normal_main, UV));
	vec3 main_view = normalize(TANGENT * tn.x + BINORMAL * tn.y + NORMAL * tn.z);
	vec3 main_world = normalize((INV_VIEW_MATRIX * vec4(main_view, 0.0)).xyz);
	vec3 rock_obj = triplanar_normal_obj(normal_rock, tri_pos, normalize(obj_normal), tri_weights,
			ground_pebble_scale);
	vec3 rock = normalize(mat3(MODEL_MATRIX) * rock_obj);
	vec3 tri = triplanar_normal(normal_triplanar, world_pos, wn, ground_detail_scale);

	vec3 tri_detail = normalize(mix(wn, tri, ground_detail_power));
	vec3 tri_masked = normalize(mix(wn, tri_detail, mask_g_invert));

	vec3 final_world = normalize(main_world + (rock - wn) + (tri_masked - wn));

	NORMAL = normalize((VIEW_MATRIX * vec4(final_world, 0.0)).xyz);
}