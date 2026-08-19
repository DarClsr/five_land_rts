class_name CrystalNode
extends Node2D
"""灵脉矿：民夫采集灵晶的矿点（龙脉外露之晶）。"""

const NORMAL_AMOUNT := 1500
const RICH_AMOUNT := 3000
const NORMAL_YIELD := 8
const RICH_YIELD := 12
const MINE_TIME := 3.0
const APPROACH_DIST := 46.0
const NORMAL_COLOR := Color(0.42, 0.47, 0.55)
const RICH_COLOR := Color(0.72, 0.58, 0.22)
const DEPLETED_COLOR := Color(0.45, 0.43, 0.40)

var amount := NORMAL_AMOUNT
var rich := false


func setup(is_rich := false) -> void:
	rich = is_rich
	amount = RICH_AMOUNT if rich else NORMAL_AMOUNT
	queue_redraw()


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


func trip_yield() -> int:
	return RICH_YIELD if rich else NORMAL_YIELD


func _draw() -> void:
	# 2.5D：地面投影 + 底座
	draw_set_transform(Vector2(8, 10), 0.0, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, 26.0, Color(0.10, 0.09, 0.09, 0.15))
	draw_set_transform(Vector2.ZERO)
	draw_ellipse_fill(Vector2(0, 14), 30.0, 10.0, Color(0.35, 0.32, 0.29, 0.6))
	if rich and not is_depleted():
		draw_arc(Vector2(0, 8), 34.0, 0.0, TAU, 28, Color(RICH_COLOR, 0.75), 3.0)
	# 灵晶簇：富灵脉用金色辉光区分
	var shards := [
		[Vector2(-16, 12), Vector2(-24, -10), Vector2(-8, -26), Vector2(-2, 4)],
		[Vector2(-2, 4), Vector2(6, -22), Vector2(20, -8), Vector2(12, 14)],
		[Vector2(10, 14), Vector2(24, 2), Vector2(30, 14), Vector2(16, 22)],
	]
	var shard_color := RICH_COLOR if rich else NORMAL_COLOR
	for s in shards:
		var pts := PackedVector2Array()
		for p in s:
			pts.append(p)
		draw_colored_polygon(pts, Color(shard_color, 0.9))
		draw_polyline(pts, Color(0.25, 0.28, 0.34), 1.5, true)
	# 枯竭后转为灰褐色
	if is_depleted():
		draw_circle(Vector2.ZERO, 30.0, Color(DEPLETED_COLOR, 0.6))


func draw_ellipse_fill(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 20:
		var ang := TAU * float(i) / 20.0
		pts.append(center + Vector2(cos(ang) * rx, sin(ang) * ry))
	draw_colored_polygon(pts, color)
