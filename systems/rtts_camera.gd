class_name RTTSCamera
extends Camera2D
"""RTS 相机：WASD/方向键/屏幕边缘平移，滚轮以鼠标为锚缩放，限制在地图内。"""

@export var map_rect := Rect2(-1600, -900, 3200, 1800)
@export var pan_speed := 1100.0
@export var min_zoom := 0.45
@export var max_zoom := 1.6
@export var edge_scroll := true
@export var edge_margin := 18.0


func _ready() -> void:
	make_current()


func _process(delta: float) -> void:
	var dir := Input.get_vector("pan_left", "pan_right", "pan_up", "pan_down")
	if edge_scroll:
		var m := get_viewport().get_mouse_position()
		var vs := get_viewport().get_visible_rect().size
		if m.x < edge_margin:
			dir.x -= 1.0
		elif m.x > vs.x - edge_margin:
			dir.x += 1.0
		if m.y < edge_margin:
			dir.y -= 1.0
		elif m.y > vs.y - edge_margin:
			dir.y += 1.0
	dir = dir.clamp(Vector2(-1, -1), Vector2(1, 1))
	if dir != Vector2.ZERO:
		position += dir * pan_speed * delta / zoom.x
	_clamp_to_map()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var factor := 1.0
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			factor = 1.15
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			factor = 1.0 / 1.15
		else:
			return
		var vp := get_viewport()
		var mouse := vp.get_mouse_position()
		var center := vp.get_visible_rect().size * 0.5
		var old_z := zoom.x
		var new_z := clampf(old_z * factor, min_zoom, max_zoom)
		if absf(new_z - old_z) < 0.0001:
			return
		zoom = Vector2(new_z, new_z)
		# 以鼠标世界坐标为锚缩放
		var world_at_mouse := position + (mouse - center) / Vector2(old_z, old_z)
		position = world_at_mouse - (mouse - center) / Vector2(new_z, new_z)
		_clamp_to_map()


func _clamp_to_map() -> void:
	var vs := get_viewport().get_visible_rect().size
	var half := vs * 0.5 / zoom
	position.x = clampf(position.x, map_rect.position.x + half.x, map_rect.end.x - half.x)
	position.y = clampf(position.y, map_rect.position.y + half.y, map_rect.end.y - half.y)
