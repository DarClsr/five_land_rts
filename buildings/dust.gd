class_name Dust
extends Node2D
"""尘：阵亡单位所化，皇陵可归尘唤俑 / 炼晶，60 秒后散逸。"""

const TTL := 60.0

var amount := 1
var _t := 0.0


func _ready() -> void:
	add_to_group("dust")


func _process(delta: float) -> void:
	_t += delta
	if _t >= TTL:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var fade := clampf((TTL - _t) / 10.0, 0.0, 1.0)
	var c := Color(0.55, 0.46, 0.30, 0.55 * fade)
	draw_circle(Vector2.ZERO, 7.0, c)
	draw_circle(Vector2(5, 2), 4.0, Color(c.r, c.g, c.b, c.a * 0.7))
	draw_circle(Vector2(-5, 1), 3.5, Color(c.r, c.g, c.b, c.a * 0.6))
