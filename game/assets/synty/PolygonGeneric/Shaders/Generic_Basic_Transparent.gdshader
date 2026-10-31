shader_type spatial;
render_mode blend_mix, depth_draw_opaque, depth_test_default, cull_back, diffuse_lambert, specular_schlick_ggx;

uniform vec2 Albedo_Tiling = vec2(1.000000, 1.000000);
uniform vec2 Albedo_Offset = vec2(0.000000, 0.000000);
uniform sampler2D Albedo_Map : source_color;
uniform float Alpha_Transparency : hint_range(0.0, 1.0) = 1.0;
uniform vec4 BaseColor : source_color = vec4(1.000000, 1.000000, 1.000000, 1.000000);
uniform float Metallic = 0.0;
uniform float Smoothness = 0.5;
uniform bool Enable_Emission;
uniform sampler2D Emission_Map : source_color, hint_default_white;
uniform vec4 Emission_Color : source_color = vec4(0.000000, 0.000000, 0.000000, 1.000000);
uniform vec2 Normal_Tiling = vec2(1.000000, 1.000000);
uniform vec2 Normal_Offset = vec2(0.000000, 0.000000);
uniform sampler2D Normal_Map : hint_normal;
uniform float Normal_Strength = 1.0;


void fragment() {
// Input:38
	vec2 n_out38p0 = UV;


// Vector2Parameter:29
	vec2 n_out29p0 = Albedo_Tiling;


// VectorOp:36
	vec3 n_out36p0 = vec3(n_out38p0, 0.0) * vec3(n_out29p0, 0.0);


// Vector2Parameter:30
	vec2 n_out30p0 = Albedo_Offset;


// VectorOp:37
	vec3 n_out37p0 = n_out36p0 + vec3(n_out30p0, 0.0);


	vec4 n_out2p0;
// Texture2D:2
	n_out2p0 = texture(Albedo_Map, vec2(n_out37p0.xy));


// ColorParameter:4
	vec4 n_out4p0 = BaseColor;


// VectorOp:3
	vec4 n_out3p0 = n_out2p0 * n_out4p0;


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


// BooleanParameter:18
	bool n_out18p0 = Enable_Emission;


	vec4 n_out14p0;
// Texture2D:14
	n_out14p0 = texture(Emission_Map, UV);


// ColorParameter:17
	vec4 n_out17p0 = Emission_Color;


// VectorOp:16
// Multiply Emission_Map (RGB) by Emission_Color.
// Emission_Map defaults to white (hint_default_white), so when no
// texture is assigned this is a no-op (white * color = color) and
// Emission_Color alone drives the mesh; when a texture is assigned,
// its RGB tints/masks the color per-channel.
	vec3 n_out16p0 = n_out14p0.xyz * n_out17p0.xyz;


// Switch:35
	vec4 n_out35p0 = vec4(n_out16p0, 0.0);


// ColorConstant:19
	vec4 n_out19p0 = vec4(0.000000, 0.000000, 0.000000, 1.000000);


	vec3 n_out20p0;
// Switch:20
	n_out20p0 = mix(vec3(n_out19p0.xyz), vec3(n_out35p0.xyz), float(n_out18p0));


// Input:39
	vec2 n_out39p0 = UV;


// Vector2Parameter:32
	vec2 n_out32p0 = Normal_Tiling;


// VectorOp:40
	vec3 n_out40p0 = vec3(n_out39p0, 0.0) * vec3(n_out32p0, 0.0);


// Vector2Parameter:33
	vec2 n_out33p0 = Normal_Offset;


// VectorOp:41
	vec3 n_out41p0 = n_out40p0 + vec3(n_out33p0, 0.0);


	vec4 n_out21p0;
// Texture2D:21
	n_out21p0 = texture(Normal_Map, vec2(n_out41p0.xy));


// FloatParameter:25
	float n_out25p0 = Normal_Strength;


// FloatParameter:Alpha
	float n_out_alpha = Alpha_Transparency;


// Output:0
	ALBEDO = vec3(n_out3p0.xyz);
	ALPHA = n_out3p0.a * n_out_alpha;
	METALLIC = n_out7p0;
	ROUGHNESS = n_out9p0;
	EMISSION = n_out20p0;
	NORMAL_MAP = vec3(n_out21p0.xyz);
	NORMAL_MAP_DEPTH = n_out25p0;


}