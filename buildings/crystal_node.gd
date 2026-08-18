class_name CrystalNode
extends Node2D
"""灵脉矿：民夫采集灵晶的矿点（龙脉外露之晶）。"""

const CARRY_PER_TRIP := 8
const MINE_TIME := 3.0
const APPROACH_DIST := 46.0

var amount := 1500


func _ready() -> void:
	add_to_group("gather_nodes")
	queue_redraw()


func take(requested: int) -> int:
	var got := mini(requested, amount)
	amount -= got
	queue_redraw()
	return got


func is_depleted() -> bool:
	return amount <= 0


func _draw() -> void:
	# 灰蓝晶簇：几枚多边形晶石 + 留白底
	var shards := [
		[Vector2(-16, 12), Vector2(-24, -10), Vector2(-8, -26), Vector2(-2, 4)],
		[Vector2(-2, 4), Vector2(6, -22), Vector2(20, -8), Vector2(12, 14)],
		[Vector2(10, 14), Vector2(24, 2), Vector2(30, 14), Vector2(16, 22)],
	]
	for s in shards:
		var pts := PackedVector2Array()
		for p in s:
			pts.append(p)
		draw_colored_polygon(pts, Color(0.42, 0.47, 0.55, 0.85))
		draw_polyline(pts, Color(0.25, 0.28, 0.34), 1.5, true)
	# 余量越少越淡
	if is_depleted():
		draw_circle(Vector2.ZERO, 30.0, Color(0.85, 0.83, 0.78, 0.6))
