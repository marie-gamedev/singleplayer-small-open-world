shader_type spatial;
render_mode unshaded;

uniform samplerCube my_cubemap;
uniform float reflection_strength : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    vec3 reflection_dir = reflect(-VIEW, NORMAL);
    vec3 reflection_color = textureLod(my_cubemap, reflection_dir, 0.0).rgb;
    ALBEDO = reflection_color;
}
