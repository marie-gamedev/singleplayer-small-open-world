shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D Planet_Texture : source_color, hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D Rim_Texture : source_color, hint_default_black, filter_linear_mipmap, repeat_enable;
uniform sampler2D Glow_Texture : source_color, hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 Planet_Tint : source_color = vec4(0.1, 0.9, 1.0, 1.0);
uniform float Planet_Light : hint_range(0.0, 10.0) = 3.0;
uniform float Rim_Intensity : hint_range(0.0, 10.0) = 3.0;
uniform vec4 Glow_Tint : source_color = vec4(0.1, 0.9, 1.0, 1.0);
uniform float Glow_Intensity : hint_range(0.0, 10.0) = 3.0;
uniform float Opacity : hint_range(0.0, 1.0) = 1.0;
uniform bool Soft_Fade = false;
uniform float gradient_position : hint_range(0.0, 1.0) = 0.75;


void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	
	float gradient_mix = clamp(UV.y - (gradient_position - 0.5), 0.0, 1.0);
	gradient_mix = 1.0 - gradient_mix;

	vec4 base_tex = texture(Planet_Texture, UV);
	vec4 rim_tex = texture(Rim_Texture, UV);
	vec4 glow_tex = texture(Glow_Texture, UV);
	
	vec3 planet_tint_mix = base_tex.rgb * Planet_Tint.rgb;
	vec3 planet_light_mix = Planet_Tint.rgb * Planet_Light;
	vec3 glow_mix = glow_tex.rgb * (Glow_Tint.rgb * Glow_Intensity);
	
	vec3 planet_color_tinted = planet_tint_mix.rgb *  planet_light_mix.rgb;
	
	vec3 rim_color_mix = rim_tex.rgb * Rim_Intensity;
	
	
	vec3 color_test = planet_color_tinted.rgb + rim_color_mix.rgb;
	

	
	if(Soft_Fade){
		ALPHA = gradient_mix * (base_tex.a * Opacity);
		ALBEDO = (color_test.rgb * gradient_mix) + glow_mix;
	} else{
		ALPHA =  base_tex.a * Opacity;
		ALBEDO = color_test.rgb + glow_mix;
	}

}
