class_name WaterPond
extends Node2D
"""留白水域：浅灰蓝水面 + 波纹线。不可通行。"""

@export var size := Vector2(560.0, 300.0)
@export var pond_color := Color(0.78, 0.80, 0.83, 0.5)
@export var border_color := Color(0.35, 0.36, 0.40, 0.45)
@export var pond_seed := 4


func _draw() -> void:
	var half := size * 0.5
	var pts := PackedVector2Array()
	for i in 40:
		var ang := TAU * float(i) / 40.0
		var wob := 0.88 + _hash_ang(i) * 0.14
		pts.append(Vector2(cos(ang) * half.x * wob * 0.9, sin(ang) * half.y * wob * 0.85))
	draw_colored_polygon(pts, pond_color)
	draw_polyline(pts, border_color, 2.0, true)
	# 三道波纹
	for w in 3:
		var wave := PackedVector2Array()
		var yy := -half.y * 0.4 + float(w) * half.y * 0.4
		var xx := -half.x * 0.55
		while xx <= half.x * 0.55:
			wave.append(Vector2(xx, yy + sin(xx * 0.05 + float(w) * 2.0) * 5.0))
			xx += 16.0
		draw_polyline(wave, Color(0.45, 0.47, 0.52, 0.5), 1.5, false)


func obstruction_corners() -> PackedVector2Array:
	var h := size * 0.44
	return PackedVector2Array([
		to_global(Vector2(-h.x, -h.y)), to_global(Vector2(h.x, -h.y)),
		to_global(Vector2(h.x, h.y)), to_global(Vector2(-h.x, h.y)),
	])


func _hash_ang(i: int) -> float:
	return fmod(absf(sin(float(i + pond_seed) * 91.7) * 43758.5453), 1.0)
