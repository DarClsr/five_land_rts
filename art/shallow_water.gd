class_name ShallowWater
extends Node2D
"""可通行浅水：提供东吴水网区域查询与轻量水墨波纹。"""

@export var size := Vector2(900.0, 160.0)


func _ready() -> void:
	add_to_group("shallow_water")
	z_index = -20
	queue_redraw()


func contains_world_point(world_point: Vector2) -> bool:
	return Rect2(global_position - size * 0.5, size).has_point(world_point)


func _draw() -> void:
	var rect := Rect2(-size * 0.5, size)
	draw_rect(rect, Color(0.56, 0.67, 0.70, 0.20), true)
	for row in 3:
		var wave := PackedVector2Array()
		var x := rect.position.x + 24.0
		var y := rect.position.y + size.y * (0.25 + float(row) * 0.25)
		while x < rect.end.x - 24.0:
			wave.append(Vector2(x, y + sin(x * 0.035 + float(row)) * 4.0))
			x += 24.0
		draw_polyline(wave, Color(0.28, 0.40, 0.44, 0.35), 1.2)
