class_name InkRock
extends Node2D
"""程序化墨岩障碍：圆噪声轮廓的岩石 + 几笔皴。size 为局部包围盒。"""

@export var size := Vector2(320.0, 220.0)
@export var rock_color := Color(0.20, 0.19, 0.185, 0.95)
@export var rock_seed := 1


func _draw() -> void:
	var half := size * 0.5
	var corners := [
		Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
		Vector2(half.x, half.y), Vector2(-half.x, half.y),
	]
	var pts := PackedVector2Array()
	for i in 4:
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[(i + 1) % 4]
		var n := maxi(int(a.distance_to(b) / 30.0), 2)
		for j in n:
			var p := a.lerp(b, float(j) / float(n))
			var inward := (_hash(p) - 0.5) * 26.0
			var dir := p.direction_to(Vector2.ZERO)
			pts.append(p + dir * inward)
	draw_colored_polygon(pts, rock_color)
	# 皴：岩面上几笔深色短擦
	for k in 5:
		var q := Vector2(_hashv(k, rock_seed) - 0.5, _hashv(rock_seed, k) - 0.5) * size * 0.5
		draw_line(q, q + Vector2(18.0 + _hashv(k, 9) * 22.0, 8.0), Color(0.08, 0.08, 0.08, 0.5), 2.0)


func obstruction_corners() -> PackedVector2Array:
	"""导航阻挡轮廓（略小于视觉轮廓，留单位半径余量）。"""
	var h := size * 0.48
	return PackedVector2Array([
		to_global(Vector2(-h.x, -h.y)), to_global(Vector2(h.x, -h.y)),
		to_global(Vector2(h.x, h.y)), to_global(Vector2(-h.x, h.y)),
	])


func _hash(p: Vector2) -> float:
	return fmod(absf(sin(p.x * 0.13 + p.y * 0.17) * 43758.5453), 1.0)


func _hashv(a: int, b: int) -> float:
	return fmod(absf(sin(float(a) * 127.1 + float(b) * 311.7) * 43758.5453), 1.0)
