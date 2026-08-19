class_name InkRock
extends Node2D
"""程序化墨岩障碍（2.5D）：深色岩体 + 上浮浅色顶面 + 侧影，size 为局部包围盒。"""

@export var size := Vector2(320.0, 220.0)
@export var rock_color := Color(0.20, 0.19, 0.185, 0.95)
@export var rock_seed := 1


func _draw() -> void:
	var half := size * 0.5
	var h := size.y * 0.38  # 挤出高度
	var pts := _outline(half)
	# 1) 地面投影（光源左上）
	var shadow := PackedVector2Array()
	for p in pts:
		shadow.append(p + Vector2(14.0, 8.0))
	draw_colored_polygon(shadow, Color(0.10, 0.09, 0.09, 0.15))
	# 2) 岩体（深色主面）
	draw_colored_polygon(pts, rock_color)
	# 3) 顶面（上浮浅色）
	var top := PackedVector2Array()
	for p in pts:
		top.append(p - Vector2(0, h))
	draw_colored_polygon(top, Color(0.42, 0.40, 0.37, 0.95))
	draw_polyline(top, Color(0.12, 0.11, 0.10), 1.5, true)
	# 4) 皴：顶面几笔深色短擦
	for k in 5:
		var q := Vector2(_hashv(k, rock_seed) - 0.5, _hashv(rock_seed, k) - 0.5) * size * 0.5
		draw_line(q - Vector2(0, h), q - Vector2(0, h) + Vector2(18.0 + _hashv(k, 9) * 22.0, 6.0), Color(0.10, 0.10, 0.10, 0.5), 2.0)


func _outline(half: Vector2) -> PackedVector2Array:
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
			pts.append(p + p.direction_to(Vector2.ZERO) * inward)
	return pts


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
