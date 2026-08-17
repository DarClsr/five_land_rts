class_name InkMountains
extends Node2D
"""程序化水墨远山：多层山脊 + 顶浓底淡的晕染渐变。"""

@export var width := 2400.0
@export var base_y := 80.0
@export var fill_depth := 1000.0
@export var layers := 3
@export var ink_seed := 7
@export var ink_color := Color(0.14, 0.13, 0.125)


func _draw() -> void:
	for li in layers:
		var t := float(li) / float(maxi(layers - 1, 1))
		var alpha := lerpf(0.16, 0.52, t)
		var amp := lerpf(70.0, 150.0, t)
		var y_off := lerpf(-170.0, 30.0, t)
		var ph := float((ink_seed + li * 37) % 100) * 0.7

		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var x := -width * 0.5
		while x <= width * 0.5:
			var r1 := (sin(x * 0.0042 + ph) * 0.5 + 0.5) * amp * 0.62
			var r2 := (sin(x * 0.011 + ph * 2.3) * 0.5 + 0.5) * amp * 0.28
			var r3 := sin(x * 0.043 + ph * 3.1) * amp * 0.10
			pts.append(Vector2(x, base_y + y_off - (r1 + r2 + r3)))
			cols.append(Color(ink_color.r, ink_color.g, ink_color.b, alpha))
			x += 26.0
		# 底部两角淡出（晕染）
		pts.append(Vector2(width * 0.5 + 60.0, base_y + fill_depth))
		pts.append(Vector2(-width * 0.5 - 60.0, base_y + fill_depth))
		cols.append(Color(ink_color.r, ink_color.g, ink_color.b, 0.0))
		cols.append(Color(ink_color.r, ink_color.g, ink_color.b, 0.0))
		draw_polygon(pts, cols)
