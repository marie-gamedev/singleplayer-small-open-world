shader_type sky;

uniform sampler2D front : source_color;
uniform sampler2D back : source_color;
uniform sampler2D left : source_color;
uniform sampler2D right : source_color;
uniform sampler2D top : source_color;
uniform sampler2D bottom : source_color;

void sky() {
	vec3 absEyedir = abs(EYEDIR);
	float mainAxis = max(max(absEyedir.x, absEyedir.y), absEyedir.z);
	float invAxis = 1.0 / mainAxis;
	vec3 faceUVDir = EYEDIR * invAxis;

	if (EYEDIR.x >= mainAxis) {
		COLOR = textureLod(left, faceUVDir.zy * vec2(-0.5, -0.5) - 0.5, 0.0).rgb;
	} else if (EYEDIR.x <= -mainAxis) {
		COLOR = textureLod(right, faceUVDir.zy * vec2(0.5, -0.5) - 0.5, 0.0).rgb;
	} else if (EYEDIR.z >= mainAxis) {
		COLOR = textureLod(front, faceUVDir.xy * vec2(0.5, -0.5) - 0.5, 0.0).rgb;
	} else if (EYEDIR.z <= -mainAxis) {
		COLOR = textureLod(back, faceUVDir.xy * vec2(-0.5, -0.5) - 0.5, 0.0).rgb;
	} else if (EYEDIR.y >= mainAxis) {
		COLOR = textureLod(top, faceUVDir.xz * vec2(-0.5, -0.5) + 0.5, 0.0).rgb;
	} else {
		COLOR = textureLod(bottom, faceUVDir.xz * vec2(-0.5, 0.5) + 0.5, 0.0).rgb;
	}
}