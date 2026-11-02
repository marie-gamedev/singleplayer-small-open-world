
shader_type spatial;
render_mode cull_back, diffuse_lambert;

// Original material
uniform sampler2D albedo_tex : source_color, hint_default_white;
uniform vec4 base_color : source_color = vec4(1.0);

// Painterly settings
uniform sampler2D noise_tex : repeat_enable, filter_linear;

uniform float brush_scale : hint_range(0.1, 30.0) = 4.0;
uniform float brush_length : hint_range(1.0, 20.0) = 6.0;
uniform float brush_strength : hint_range(0.0, 1.0) = 0.35;
uniform float color_variation : hint_range(0.0, 1.0) = 0.25;

varying vec3 object_pos;
varying vec3 object_normal;

void vertex() {
    object_pos = VERTEX;
    object_normal = NORMAL;
}

float brush_noise(vec3 pos, vec3 normal) {
    vec3 weights = pow(abs(normal), vec3(4.0));
    weights /= max(
        weights.x + weights.y + weights.z,
        0.0001
    );

    // Elongated noise creates directional strokes
    vec2 stretch = vec2(1.0, brush_length);

    float x = texture(noise_tex, pos.yz * stretch).r;
    float y = texture(noise_tex, pos.xz * stretch).r;
    float z = texture(noise_tex, pos.xy * stretch).r;

    return x * weights.x +
           y * weights.y +
           z * weights.z;
}

void fragment() {
    vec3 pos = object_pos * brush_scale;
    vec3 normal = normalize(object_normal);

    vec3 original_color =
        texture(albedo_tex, UV).rgb * base_color.rgb;

    // Surface-attached brush pattern
    float noise = brush_noise(pos, normal);

    // Create irregular paint patches
    float strokes = smoothstep(0.3, 0.7, noise);

    // Vary paint brightness
    float paint_variation = mix(
        1.0 - color_variation,
        1.0 + color_variation,
        strokes
    );

    vec3 painted_color = original_color * paint_variation;

    ALBEDO = mix(
        original_color,
        painted_color,
        brush_strength
    );

    ROUGHNESS = 1.0;
}
