class_name BuildBar
extends CanvasLayer
"""底部指令栏：资源/人口显示 + 上下文按钮（大寨训练 / 民夫建造）+ 建造摆放模式。"""

const PLACE_MARGIN := 28.0
const BUILDABLE := ["gaizhang", "yanzhen", "fengsui"]

var cam: Camera2D
var map_root: Node2D
var sel: SelectionManager
var player: PlayerState

var _placing_id := ""
var _res_label: Label
var _pop_label: Label
var _btn_box: HBoxContainer
var _status: Label
var _ghost: GhostControl
var _ctx_sig := ""
var _status_clear_at := 0.0


func _init() -> void:
	layer = 8


func setup(camera: Camera2D, root: Node2D, selection: SelectionManager, p: PlayerState) -> void:
	cam = camera
	map_root = root
	sel = selection
	player = p
	_build_ui()


func _build_ui() -> void:
	var bar := PanelContainer.new()
	bar.position = Vector2(560, 1000)
	bar.custom_minimum_size = Vector2(800, 72)
	add_child(bar)

	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	bar.add_child(box)

	_res_label = Label.new()
	_res_label.text = "灵晶 200"
	box.add_child(_res_label)

	_pop_label = Label.new()
	_pop_label.text = "人口 0/0"
	box.add_child(_pop_label)

	_btn_box = HBoxContainer.new()
	_btn_box.add_theme_constant_override("separation", 10)
	box.add_child(_btn_box)

	_status = Label.new()
	_status.text = ""
	box.add_child(_status)

	_ghost = GhostControl.new()
	_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ghost)


func _process(_delta: float) -> void:
	_res_label.text = "灵晶 %d" % player.crystals
	_pop_label.text = "人口 %d/%d" % [player.pop_used, player.pop_cap]
	_refresh_buttons()
	if Time.get_ticks_msec() > _status_clear_at:
		_status.text = ""


func _refresh_buttons() -> void:
	var sig := _context_signature()
	if sig == _ctx_sig:
		return
	_ctx_sig = sig
	for c in _btn_box.get_children():
		c.queue_free()
	if sel == null:
		return
	# 民夫在选 → 建造按钮
	var has_worker := false
	for u in sel.selected:
		if u is Worker:
			has_worker = true
			break
	if has_worker:
		for id in BUILDABLE:
			_add_button(Defs.building(id)["name"] + " %d" % int(Defs.building(id)["cost"]), _start_placement.bind(id))
	# 选中大寨 → 训练按钮
	var b: Building = sel.selected_building
	if b != null and b.complete:
		for uid in Defs.building(b.def_id).get("trains", []):
			var udef: Dictionary = Defs.unit(uid)
			_add_button("训练%s %d" % [udef["name"], int(udef["cost"])], _train_unit.bind(b, uid))


func _context_signature() -> String:
	var worker := "0"
	for u in sel.selected:
		if u is Worker:
			worker = "1"
			break
	var b := "0"
	if sel.selected_building != null:
		b = str(sel.selected_building.get_instance_id())
	return worker + "|" + b


func _add_button(text: String, cb: Callable) -> void:
	var btn := Button.new()
	btn.text = text
	btn.pressed.connect(cb)
	_btn_box.add_child(btn)


func _train_unit(hq: Building, unit_id: String) -> void:
	if hq.enqueue(unit_id):
		_status.text = "训练中…队列 %d" % hq.queue_size()
	else:
		_status.text = "灵晶或人口不足"
	_status_clear_at = Time.get_ticks_msec() + 2500


func _start_placement(id: String) -> void:
	_placing_id = id
	_status.text = "点击地图放置，右键/ESC 取消"
	_status_clear_at = Time.get_ticks_msec() + 4000


func _unhandled_input(event: InputEvent) -> void:
	if _placing_id == "":
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var wp := _screen_to_world(event.position)
			if _placement_valid(wp):
				_place(wp)
				_placing_id = ""
				get_viewport().set_input_as_handled()
			else:
				_status.text = "此处无法建造"
				_status_clear_at = Time.get_ticks_msec() + 1500
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_cancel_placement()
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		_cancel_placement()
		get_viewport().set_input_as_handled()
	if _placing_id != "":
		_ghost.update_ghost(_screen_to_world(get_viewport().get_mouse_position()), _placing_id, _placement_valid(_screen_to_world(get_viewport().get_mouse_position())))
	else:
		_ghost.update_ghost(Vector2.INF, "", false)


func _cancel_placement() -> void:
	_placing_id = ""
	_ghost.update_ghost(Vector2.INF, "", false)


func _screen_to_world(p: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * p


func _placement_valid(wp: Vector2) -> bool:
	var size: Vector2 = Defs.building(_placing_id)["size"]
	var rect := Rect2(wp - size * 0.5 - Vector2.ONE * PLACE_MARGIN, size + Vector2.ONE * PLACE_MARGIN * 2.0)
	for b in map_root.get_tree().get_nodes_in_group("buildings"):
		if b is Building:
			var bs: Vector2 = Defs.building(b.def_id)["size"]
			if rect.intersects(Rect2(b.global_position - bs * 0.5, bs)):
				return false
	for n in map_root.get_tree().get_nodes_in_group("gather_nodes"):
		if n is Node2D and rect.has_point(n.global_position):
			return false
	return true


func _place(wp: Vector2) -> void:
	var def: Dictionary = Defs.building(_placing_id)
	if not player.spend(int(def["cost"])):
		_status.text = "灵晶不足"
		_status_clear_at = Time.get_ticks_msec() + 2000
		return
	var b := Building.new()
	b.setup(_placing_id, 0, false)
	b.position = wp
	map_root.add_child(b)
	# 所有选中的民夫去施工
	for u in sel.selected:
		if u is Worker:
			(u as Worker).command_build(b)
	_status.text = "%s 施工中" % def["name"]
	_status_clear_at = Time.get_ticks_msec() + 2000


class GhostControl:
	extends Control
	var _pos := Vector2.INF
	var _id := ""
	var _valid := false
	var _cam: Camera2D

	func update_ghost(world_pos: Vector2, id: String, valid: bool) -> void:
		_pos = world_pos
		_id = id
		_valid = valid
		queue_redraw()

	func _draw() -> void:
		if _id == "" or _pos == Vector2.INF:
			return
		var vp := get_viewport()
		var screen := vp.get_canvas_transform() * _pos
		var size: Vector2 = Defs.building(_id)["size"]
		var rect := Rect2(screen - size * 0.5, size)
		var col := Color(0.2, 0.6, 0.3, 0.4) if _valid else Color(0.75, 0.2, 0.15, 0.4)
		draw_rect(rect, col, true)
		draw_rect(rect, Color(col.r, col.g, col.b, 0.95), false, 2.0)
