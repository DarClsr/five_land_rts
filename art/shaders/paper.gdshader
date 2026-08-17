shader_type canvas_item;
// 宣纸底色：暖米白 + 双频噪声颗粒 + 边缘微暗（vignette）
uniform vec3 paper_color : source_color = vec3(0.925, 0.898, 0.835);
uniform float grain : hint_range(0.0, 0.2) = 0.05;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x),
		f.y);
}

void fragment() {
	float n = vnoise(UV * 420.0) * 0.6 + vnoise(UV * 90.0) * 0.4;
	vec3 col = paper_color * (1.0 - grain + n * grain * 2.0);
	vec2 d = min(UV, 1.0 - UV);
	float vign = smoothstep(0.0, 0.16, min(d.x, d.y));
	col *= mix(0.94, 1.0, vign);
	COLOR = vec4(col, 1.0);
}
