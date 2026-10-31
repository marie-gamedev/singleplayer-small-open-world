shader_type spatial;
render_mode blend_mix, depth_draw_opaque, depth_prepass_alpha, depth_test_default, cull_back, diffuse_lambert, specular_schlick_ggx;

uniform sampler2D Albedo_Map : source_color;
uniform vec4 BaseColor : source_color = vec4(1.000000, 1.000000, 1.000000, 1.000000);
uniform vec4 SkinColor : source_color = vec4(1.000000, 0.800000, 0.682353, 1.000000);
uniform sampler2D Skin_Mask : source_color, hint_default_black;
uniform vec4 Hair_Color : source_color = vec4(0.309804, 0.254902, 0.176471, 1.000000);
uniform sampler2D Hair_Mask : source_color, hint_default_black;
uniform float Alpha_Transparency : hint_range(0.0, 1.0) = 1.0;
uniform bool USE_METALLIC_SMOOTHNESS_MAP;
uniform sampler2D Metallic_Smoothness_Map : source_color;
uniform float Smoothness = 0.5;
uniform float Metallic = 0.0;
uniform bool Enable_Emission;
uniform sampler2D Emission_Map : source_color, hint_default_black;
uniform vec4 Emission_Color : source_color = vec4(0.000000, 0.000000, 0.000000, 1.000000);
uniform sampler2D Normal_Map : hint_normal;



void fragment() {
	vec4 n_out2p0;
// Texture2D:2
	n_out2p0 = texture(Albedo_Map, UV);


// ColorParameter:4
	vec4 n_out4p0 = BaseColor;


// VectorOp:3
	vec4 n_out3p0 = n_out2p0 * n_out4p0;
	float n_out3p4 = n_out3p0.a;


// ColorParameter:33
	vec4 n_out33p0 = SkinColor;


// VectorOp:39
	vec3 n_out39p0 = vec3(n_out3p0.xyz) * vec3(n_out33p0.xyz);


	vec4 n_out35p0;
// Texture2D:35
	n_out35p0 = texture(Skin_Mask, UV);


// Mix:40
	vec3 n_out40p0 = mix(vec3(n_out3p0.xyz), n_out39p0, vec3(n_out35p0.xyz));


// ColorParameter:36
	vec4 n_out36p0 = Hair_Color;


// VectorOp:42
	vec3 n_out42p0 = vec3(n_out3p0.xyz) * vec3(n_out36p0.xyz);


	vec4 n_out38p0;
// Texture2D:38
	n_out38p0 = texture(Hair_Mask, UV);


// Mix:41
	vec3 n_out41p0 = mix(n_out40p0, n_out42p0, vec3(n_out38p0.xyz));


// FloatParameter:44
	float n_out44p0 = Alpha_Transparency;


// VectorOp:43
	vec3 n_out43p0 = vec3(n_out3p4) * vec3(n_out44p0);


// BooleanParameter:26
	bool n_out26p0 = USE_METALLIC_SMOOTHNESS_MAP;


	vec4 n_out29p0;
// Texture2D:29
	n_out29p0 = texture(Metallic_Smoothness_Map, UV);
	float n_out29p1 = n_out29p0.r;
	float n_out29p4 = n_out29p0.a;


// VectorCompose:31
	vec2 n_out31p0 = vec2(n_out29p4, n_out29p1);


// FloatParameter:8
	float n_out8p0 = Smoothness;


// FloatFunc:11
	float n_out11p0 = 1.0 - n_out8p0;


// Clamp:9
	float n_in9p1 = 0.00000;
	float n_in9p2 = 1.00000;
	float n_out9p0 = clamp(n_out11p0, n_in9p1, n_in9p2);


// FloatParameter:6
	float n_out6p0 = Metallic;


// Clamp:7
	float n_in7p1 = 0.00000;
	float n_in7p2 = 1.00000;
	float n_out7p0 = clamp(n_out6p0, n_in7p1, n_in7p2);


// VectorCompose:28
	vec2 n_out28p0 = vec2(n_out9p0, n_out7p0);


	vec3 n_out25p0;
// Switch:25
	n_out25p0 = mix(vec3(n_out28p0, 0.0), vec3(n_out31p0, 0.0), float(n_out26p0));


// VectorDecompose:32
	float n_out32p0 = vec4(n_out25p0, 0.0).x;
	float n_out32p1 = vec4(n_out25p0, 0.0).y;
	float n_out32p2 = vec4(n_out25p0, 0.0).z;
	float n_out32p3 = vec4(n_out25p0, 0.0).w;


// BooleanParameter:18
	bool n_out18p0 = Enable_Emission;


	vec4 n_out14p0;
// Texture2D:14
	n_out14p0 = texture(Emission_Map, UV);


// ColorParameter:17
	vec4 n_out17p0 = Emission_Color;


// VectorOp:16
	vec3 n_out16p0 = vec3(n_out14p0.xyz) + vec3(n_out17p0.xyz);


// ColorConstant:19
	vec4 n_out19p0 = vec4(0.000000, 0.000000, 0.000000, 1.000000);


	vec3 n_out20p0;
// Switch:20
	n_out20p0 = mix(vec3(n_out19p0.xyz), n_out16p0, float(n_out18p0));


	vec4 n_out21p0;
// Texture2D:21
	n_out21p0 = texture(Normal_Map, UV);


// Output:0
	ALBEDO = n_out41p0;
	ALPHA = n_out43p0.x;
	METALLIC = n_out32p1;
	ROUGHNESS = n_out32p0;
	EMISSION = n_out20p0;
	NORMAL_MAP = vec3(n_out21p0.xyz);


}
