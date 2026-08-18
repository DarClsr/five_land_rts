class_name SelectionManager
extends Node
"""框选/点选与右键移动指令。只选中 team 0（己方）。"""

const DRAG_THRESHOLD := 5.0
const FORMATION_SPACING := 34.0

var camera: Camera2D
var hud: BasicHUD
var selected: Array[Unit] = []
var selected_building: Building = null

var _dragging := false
var _drag_start := Vector2.ZERO


func setup(cam: Camera2D) -> void:
	camera = cam


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_dragging = true
				_drag_start = event.position
			elif _dragging:
				_dragging = false
				if hud:
					hud.set_drag_rect(null)
				var rect := Rect2(_drag_start, event.position - _drag_start).abs()
				if rect.size.length() <= DRAG_THRESHOLD:
					_point_select(event.position, event.shift_pressed)
				else:
					_rect_select(rect, event.shift_pressed)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_issue_smart_command(event.position)


func _process(_delta: float) -> void:
	if _dragging and hud:
		var cur := get_viewport().get_mouse_position()
		hud.set_drag_rect(Rect2(_drag_start, cur - _drag_start).abs())


func _world_from_screen(p: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * p


func _own_units() -> Array[Unit]:
	var result: Array[Unit] = []
	for u in get_tree().get_nodes_in_group("units"):
		if u is Unit and u.team == 0:
			result.append(u)
	return result


func _point_select(screen_pos: Vector2, shift: bool) -> void:
	var wp := _world_from_screen(screen_pos)
	var best: Unit = null
	var best_dist := 28.0
	for u in _own_units():
		var d := u.global_position.distance_to(wp)
		if d < best_dist:
			best_dist = d
			best = u
	if best == null:
		# 单位没点到 → 尝试己方建筑
		var b := _building_at(wp)
		if not shift:
			_clear_selection()
		if b != null:
			_select_building(b)
		return
	if not shift:
		_clear_selection()
	if shift and best.selected:
		best.set_selected(false)
		selected.erase(best)
	elif not best.selected:
		best.set_selected(true)
		selected.append(best)


func _building_at(wp: Vector2) -> Building:
	for b in get_tree().get_nodes_in_group("buildings"):
		if b is Building and b.team == 0:
			var size: Vector2 = Defs.building(b.def_id)["size"] * 0.5
			if Rect2(b.global_position - size, size * 2.0).has_point(wp):
				return b
	return null


func _select_building(b: Building) -> void:
	if selected_building == b:
		return
	_deselect_building()
	selected_building = b
	b.set_selected(true)


func _rect_select(screen_rect: Rect2, shift: bool) -> void:
	var a := _world_from_screen(screen_rect.position)
	var b := _world_from_screen(screen_rect.position + screen_rect.size)
	var world_rect := Rect2(a, b - a).abs()
	if not shift:
		_clear_selection()
	for u in _own_units():
		if world_rect.has_point(u.global_position) and not u.selected:
			u.set_selected(true)
			selected.append(u)


func _issue_smart_command(screen_pos: Vector2) -> void:
	var wp := _world_from_screen(screen_pos)
	# 智能指令：矿脉 → 采集；未完工工地 → 施工；否则 → 移动
	var node := _gather_node_at(wp)
	var site := _construction_site_at(wp)
	if node != null:
		var any := false
		for u in selected:
			if u is Worker:
				(u as Worker).command_gather(node)
				any = true
		if any:
			return
	if site != null:
		var any_b := false
		for u in selected:
			if u is Worker:
				(u as Worker).command_build(site)
				any_b = true
		if any_b:
			return
	_issue_move(screen_pos)


func _gather_node_at(wp: Vector2) -> CrystalNode:
	for n in get_tree().get_nodes_in_group("gather_nodes"):
		if n is CrystalNode and not n.is_depleted() and n.global_position.distance_to(wp) <= 42.0:
			return n
	return null


func _construction_site_at(wp: Vector2) -> Building:
	for b in get_tree().get_nodes_in_group("buildings"):
		if b is Building and b.team == 0 and not b.complete:
			var size: Vector2 = Defs.building(b.def_id)["size"] * 0.5
			if Rect2(b.global_position - size, size * 2.0).has_point(wp):
				return b
	return null


func _issue_move(screen_pos: Vector2) -> void:
	if selected.is_empty():
		return
	var target := _world_from_screen(screen_pos)
	# 黄金螺旋散开，避免全员挤同一点
	for i in selected.size():
		var ang := float(i) * 2.39996
		var rad := FORMATION_SPACING * sqrt(float(i) + 0.5)
		var off := Vector2(cos(ang), sin(ang) * 0.7) * rad
		selected[i].command_move_to(target + off)


func _deselect_building() -> void:
	if selected_building != null:
		selected_building.set_selected(false)
		selected_building = null


func _clear_selection() -> void:
	for u in selected:
		u.set_selected(false)
	selected.clear()
	_deselect_building()
