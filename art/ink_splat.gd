class_name InkSplat
extends Node2D
"""死亡墨渍：数团墨点淡出放大后消失。"""

var splat_size := 22.0
var _t := 0.0
var _blobs: Array[Vector2] = []


func _init() -> void:
	z_index = -5  # 地面贴花，永远在单位与建筑之下
	# 以实例 id 派生伪随机墨点分布
	for i in 5:
		var ang := float((get_instance_id() * 7 + i * 61) % 360) * deg_to_rad(1.0)
		var rad := float((get_instance_id() * 13 + i * 29) % 100) / 100.0
		_blobs.append(Vector2(cos(ang), sin(ang) * 0.6) * rad * splat_size * 0.7)


func _process(delta: float) -> void:
	_t += delta * 1.1
	var s := 1.0 + _t * 0.5
	scale = Vector2(s, s)
	modulate.a = clampf(1.0 - _t, 0.0, 1.0)
	if _t >= 1.0:
		queue_free()


func _draw() -> void:
	var ink := Color(0.13, 0.12, 0.12, 0.55)
	draw_circle(Vector2.ZERO, splat_size * 0.5, ink)
	for b in _blobs:
		draw_circle(b, splat_size * 0.22, Color(ink.r, ink.g, ink.b, 0.4))
