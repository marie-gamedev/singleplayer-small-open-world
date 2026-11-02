shader_type spatial;
render_mode unshaded, fog_disabled;
uniform sampler2D screen_texture: hint_screen_texture;
//uniform float pixel_size : hint_range(0.0, 100.0, 2.0) = 8.0;

//painterly variables
uniform sampler2D noise_tex: repeat_enable;
uniform float iterations: hint_range(1.0, 50.0, 1.0) = 10.0;
uniform float shift: hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float rotation: hint_range(0.0, 2.0, 0.01) = 1.0;
uniform float sharpness: hint_range(1.0, 10.0, 0.01) = 2.0;

uniform sampler2D move_tex: repeat_enable;
uniform vec2 movement_offset = vec2(0.0);
uniform float shake_intensity : hint_range(0.0, 0.5, 0.01) = 0.05;

mat2 rotate(float a){
	float sa = sin(a);
	float ca = cos(a);
	return mat2(vec2(ca, sa), vec2(-sa, ca));
}

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	
	vec2 scrolled_uv = uv + movement_offset;
	vec2 noise_offset = texture(move_tex, scrolled_uv).rg;
	noise_offset = (noise_offset - 0.5) * shake_intensity;
	vec2 distorted_uv = uv + noise_offset;
	
	vec2 tex_size = vec2(textureSize(screen_texture, 0));
	vec2 tex_pixel_size = 1.0 / tex_size;
	vec2 resolution = 1.0 / tex_pixel_size;
	float aspect_ratio = resolution.x / resolution.y;
	vec3 color = vec3(0.0);
	float noise = pow(texture(noise_tex, distorted_uv).r, sharpness);
	for (float i = 0.0; i < iterations; i++){
		vec2 offset = vec2(1.0 / aspect_ratio, 0.0) * rotate(i * rotation);
		offset *= (1.0 + i * 0.005) * shift * 0.1;
		color += texture(screen_texture, uv + noise * offset).rgb;
	}
	color /= iterations;
	ALBEDO = color;
}