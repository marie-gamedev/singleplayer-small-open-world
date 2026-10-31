shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// --- Base color ---
group_uniforms BaseColor;
uniform sampler2D albedo_texture : source_color;
uniform vec4 albedo_tint : source_color = vec4(1.0);

// --- Normal map ---
group_uniforms NormalMap;
uniform sampler2D normal_texture : hint_normal;
uniform float normal_map_intensity : hint_range(0.0, 2.0) = 1.0;

// --- Emission ---
group_uniforms Emission;
uniform sampler2D emission_texture : source_color, hint_default_black;
uniform vec4 emission_tint : source_color = vec4(1.0);
uniform float emission_intensity : hint_range(0.0, 8.0) = 1.0;

// --- Surface ---
group_uniforms Surface;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.5;

// --- UV (shared by albedo/normal/emission above) ---
group_uniforms UV;
uniform vec2 uv_scale = vec2(1.0);
uniform vec2 uv_offset = vec2(0.0);

// --- Triplanar override ---
group_uniforms TriplanarMapping;
uniform bool use_triplanar = false;
uniform bool triplanar_world_space = true;
uniform bool triplanar_invert_normal_green = true;
uniform float triplanar_sharpness : hint_range(1.0, 16.0) = 4.0;

group_uniforms TriplanarMapping.Top;
uniform sampler2D top_albedo_texture : source_color;
uniform sampler2D top_normal_texture : hint_normal;
uniform float top_normal_intensity : hint_range(0.0, 2.0) = 1.0;
uniform float top_roughness : hint_range(0.0, 1.0) = 0.5;
uniform float top_metallic : hint_range(0.0, 1.0) = 0.0;
uniform vec2 top_uv_scale = vec2(1.0);
uniform vec2 top_uv_offset = vec2(0.0);

group_uniforms TriplanarMapping.Bottom;
uniform sampler2D bottom_albedo_texture : source_color;
uniform sampler2D bottom_normal_texture : hint_normal;
uniform float bottom_normal_intensity : hint_range(0.0, 2.0) = 1.0;
uniform float bottom_roughness : hint_range(0.0, 1.0) = 0.5;
uniform float bottom_metallic : hint_range(0.0, 1.0) = 0.0;
uniform vec2 bottom_uv_scale = vec2(1.0);
uniform vec2 bottom_uv_offset = vec2(0.0);

group_uniforms TriplanarMapping.Side;
uniform sampler2D side_albedo_texture : source_color;
uniform sampler2D side_normal_texture : hint_normal;
uniform float side_normal_intensity : hint_range(0.0, 2.0) = 1.0;
uniform float side_roughness : hint_range(0.0, 1.0) = 0.5;
uniform float side_metallic : hint_range(0.0, 1.0) = 0.0;
uniform vec2 side_uv_scale = vec2(1.0);
uniform vec2 side_uv_offset = vec2(0.0);

group_uniforms;

varying vec3 triplanar_pos;
varying vec3 triplanar_normal;
varying mat3 modelview_normal_matrix;

void vertex() {
	if (triplanar_world_space) {
		triplanar_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		// MODEL_NORMAL_MATRIX (inverse-transpose), not MODEL_MATRIX directly - a plain
		// MODEL_MATRIX multiply skews normals under non-uniform scale.
		triplanar_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	} else {
		triplanar_pos = VERTEX;
		triplanar_normal = normalize(NORMAL);
	}
	// MODELVIEW_NORMAL_MATRIX only exists in the vertex stage in Godot - carry it down
	// so the object-space triplanar normal can be converted to view space in fragment().
	modelview_normal_matrix = MODELVIEW_NORMAL_MATRIX;
}

// A tangent guess for a projection axis, orthogonalized against the true surface normal.
// Falls back to a different guess if the natural one is nearly parallel to the normal.
vec3 safe_tangent(vec3 n, vec3 guess) {
	vec3 t = guess - n * dot(n, guess);
	if (dot(t, t) < 0.0001) {
		guess = (abs(n.y) < 0.99) ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
		t = guess - n * dot(n, guess);
	}
	return normalize(t);
}

void fragment() {
	vec2 base_uv = UV * uv_scale + uv_offset;

	vec3 base_albedo = texture(albedo_texture, base_uv).rgb * albedo_tint.rgb;
	vec3 base_tangent_normal = texture(normal_texture, base_uv).rgb * 2.0 - 1.0;
	base_tangent_normal.xy *= normal_map_intensity;
	base_tangent_normal = normalize(base_tangent_normal);

	vec3 albedo_out = base_albedo;
	vec3 normal_tangent_out = base_tangent_normal;
	float rough = roughness;
	float metal = metallic;
	float coverage = 0.0;

	if (use_triplanar) {
		// A projection only participates if its albedo texture has actually been
		// assigned (Godot's default unassigned sampler is a 1x1 texture) - leave
		// top/bottom/side empty in the Inspector to fall back to the base material there.
		float e_top = float(textureSize(top_albedo_texture, 0).x > 1);
		float e_bottom = float(textureSize(bottom_albedo_texture, 0).x > 1);
		float e_side = float(textureSize(side_albedo_texture, 0).x > 1);

		bool is_top = triplanar_normal.y > 0.0;
		float e_y = is_top ? e_top : e_bottom;
		// A hemisphere+side pair only guarantees seamless full coverage (like classic
		// triplanar) when both the relevant top/bottom texture AND the side texture
		// are assigned. Otherwise fall back to each axis' own angular falloff so a
		// lone top override fades in near the pole instead of snapping to full strength.
		bool full_coverage_possible = e_y > 0.5 && e_side > 0.5;

		vec3 pow_n = pow(abs(triplanar_normal), vec3(triplanar_sharpness));
		float wx = pow_n.x * e_side;
		float wy = pow_n.y * e_y;
		float wz = pow_n.z * e_side;
		float sum = wx + wy + wz;

		vec2 uv_top = triplanar_pos.xz * top_uv_scale + top_uv_offset;
		vec2 uv_bottom = triplanar_pos.xz * bottom_uv_scale + bottom_uv_offset;

		// Flip the side projection's horizontal axis on the negative-facing side of each
		// axis, otherwise the shared side texture mirrors between e.g. east and west walls.
		// The matching decoded normal component gets the same flip below, or the normal
		// map's bump direction would end up mirrored too.
		float flip_x = sign(triplanar_normal.x);
		float flip_z = sign(triplanar_normal.z);
		vec2 uv_side_x = vec2(flip_x * triplanar_pos.z, triplanar_pos.y) * side_uv_scale + side_uv_offset;
		vec2 uv_side_z = vec2(flip_z * triplanar_pos.x, triplanar_pos.y) * side_uv_scale + side_uv_offset;

		vec3 x_albedo = texture(side_albedo_texture, uv_side_x).rgb;
		vec3 z_albedo = texture(side_albedo_texture, uv_side_z).rgb;
		vec3 y_albedo = is_top
				? texture(top_albedo_texture, uv_top).rgb
				: texture(bottom_albedo_texture, uv_bottom).rgb;

		// Decode each axis' tangent-space normal sample - reconstructed into world/object
		// space per-axis further down, once the blend weights (px/py/pz) are known.
		vec3 x_n = texture(side_normal_texture, uv_side_x).rgb * 2.0 - 1.0;
		vec3 z_n = texture(side_normal_texture, uv_side_z).rgb * 2.0 - 1.0;
		vec3 y_n = is_top
				? texture(top_normal_texture, uv_top).rgb * 2.0 - 1.0
				: texture(bottom_normal_texture, uv_bottom).rgb * 2.0 - 1.0;

		// Undo the UV mirroring above in the sampled normal too, or bump direction flips
		x_n.x *= flip_x;
		z_n.x *= flip_z;

		// Some normal maps are authored with the opposite green-channel (Y) convention
		// (DirectX vs OpenGL style) - flip it here if the triplanar textures look inverted.
		if (triplanar_invert_normal_green) {
			x_n.y = -x_n.y;
			z_n.y = -z_n.y;
			y_n.y = -y_n.y;
		}

		// Scale each sample's tangent-space deviation from flat before reconstructing world space
		x_n.xy *= side_normal_intensity;
		z_n.xy *= side_normal_intensity;
		y_n.xy *= is_top ? top_normal_intensity : bottom_normal_intensity;

		float y_rough = is_top ? top_roughness : bottom_roughness;
		float y_metal = is_top ? top_metallic : bottom_metallic;

		// How much of this pixel is covered by an *enabled* triplanar projection -
		// whatever's left shows the base UV-mapped material untouched. Fully normalized
		// (seamless, sums to 1) only where full coverage is possible; otherwise each
		// axis keeps its own falloff so partial overrides fade naturally.
		coverage = full_coverage_possible ? 1.0 : clamp(sum, 0.0, 1.0);

		if (coverage > 0.0001) {
			float norm = max(sum, 0.0001);
			float px = wx / norm;
			float py = wy / norm;
			float pz = wz / norm;

			vec3 triplanar_albedo = x_albedo * px + y_albedo * py + z_albedo * pz;

			// Build a real orthonormal tangent basis per axis against the true local
			// surface normal (not the old whiteout swizzle shortcut, which only stays
			// accurate near each axis' own pole - using it with a single dominant axis,
			// as the masking feature does, produced a visible darkened ring at the
			// latitude where that approximation broke down). safe_tangent() falls back
			// to a different guess axis if the natural one is ~parallel to the normal;
			// that only happens where a *different* axis dominates anyway, so it's safe.
			vec3 ty = safe_tangent(triplanar_normal, vec3(1.0, 0.0, 0.0));
			vec3 by = cross(ty, triplanar_normal);
			vec3 y_world = ty * y_n.x + by * y_n.y + triplanar_normal * y_n.z;

			vec3 tx = safe_tangent(triplanar_normal, vec3(0.0, 0.0, flip_x));
			vec3 bx = cross(tx, triplanar_normal);
			vec3 x_world = tx * x_n.x + bx * x_n.y + triplanar_normal * x_n.z;

			vec3 tz = safe_tangent(triplanar_normal, vec3(flip_z, 0.0, 0.0));
			vec3 bz = cross(triplanar_normal, tz);
			vec3 z_world = tz * z_n.x + bz * z_n.y + triplanar_normal * z_n.z;

			vec3 triplanar_normal_dir = normalize(x_world * px + y_world * py + z_world * pz);
			float triplanar_rough = side_roughness * (px + pz) + y_rough * py;
			float triplanar_metal = side_metallic * (px + pz) + y_metal * py;

			// triplanar_normal_dir is in world or object space (matching triplanar_world_space),
			// but NORMAL_MAP expects tangent space - a per-vertex frame that itself rotates
			// with the mesh's own UV layout, which is NOT the same as object space even though
			// both are "attached to the mesh". Feeding one in as the other is exactly what
			// caused brightness to shift with the mesh's rotation. Convert to view space first,
			// then project onto the fragment's actual TANGENT/BINORMAL/NORMAL basis (the
			// inverse of the tangent-to-view reconstruction Godot does for NORMAL_MAP) so it's
			// genuinely in the same space as base_tangent_normal before blending.
			vec3 triplanar_view_normal = triplanar_world_space
					? normalize((VIEW_MATRIX * vec4(triplanar_normal_dir, 0.0)).xyz)
					: normalize(modelview_normal_matrix * triplanar_normal_dir);
			vec3 triplanar_tangent_normal = normalize(vec3(
					dot(triplanar_view_normal, TANGENT),
					dot(triplanar_view_normal, BINORMAL),
					dot(triplanar_view_normal, NORMAL)));

			albedo_out = mix(base_albedo, triplanar_albedo, coverage);
			normal_tangent_out = normalize(mix(base_tangent_normal, triplanar_tangent_normal, coverage));
			rough = mix(roughness, triplanar_rough, coverage);
			metal = mix(metallic, triplanar_metal, coverage);
		}
	}

	ALBEDO = albedo_out;
	NORMAL_MAP = normal_tangent_out * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 1.0;
	ROUGHNESS = rough;
	METALLIC = metal;
	EMISSION = texture(emission_texture, base_uv).rgb * emission_tint.rgb * emission_intensity;
}