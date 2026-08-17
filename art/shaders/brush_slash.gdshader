shader_type canvas_item;
// 飞白剑气：干笔断续的斜向剑痕，起笔带朱砂，progress 控制出鞘进度
uniform float progress : hint_range(0.0, 1.0) = 1.0;
uniform vec3 ink_color : source_color = vec3(0.96, 0.95, 0.92);
uniform vec3 cinnabar : source_color = vec3(0.72, 0.18, 0.14);

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
	vec2 uv = UV;
	// 剑气走斜线：从左下到右上
	float d = uv.y - (0.74 - 0.48 * uv.x);
	float band = 1.0 - smoothstep(0.0, 0.085, abs(d));
	// 两端收锋（起笔窄、收笔尖）
	float taper = smoothstep(0.0, 0.18, uv.x) * smoothstep(1.0, 0.72, uv.x);
	float reveal = step(uv.x, progress);
	// 飞白：沿剑向的干笔断续
	float streak = smoothstep(0.32, 0.72, vnoise(vec2(uv.x * 130.0, uv.y * 4.0)));
	float a = band * taper * reveal * streak * 0.92;
	vec3 col = mix(ink_color, cinnabar, smoothstep(0.30, 0.0, uv.x) * 0.55);
	COLOR = vec4(col, a);
}
