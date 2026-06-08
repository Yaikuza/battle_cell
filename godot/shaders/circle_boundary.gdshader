shader_type canvas_item;

uniform vec2 u_center;
uniform float u_radius;
uniform vec2 u_offset;
uniform vec2 u_size;

void fragment() {
	vec2 world_pos = UV * u_size + u_offset;
	float dist = distance(world_pos, u_center);
	COLOR.a = dist >= u_radius ? 1.0 : 0.0;
}
