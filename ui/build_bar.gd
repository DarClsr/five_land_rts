class_name BuildBar
extends CanvasLayer
"""底部指令栏：资源/人口显示 + 上下文按钮（大寨训练 / 民夫建造）+ 建造摆放模式。"""

const PLACE_MARGIN := 28.0

var cam: Camera2D
var map_root: Node2D
var sel: SelectionManager
var player: PlayerState

var _placing_id := ""
var _migrating: Building = null  # 迁制：待落位的建筑
var _res_label: Label
var _pop_label: Label
var _selection_label: Label
var _btn_box: HFlowContainer
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
	bar.anchor_left = 0.0
	bar.anchor_top = 1.0
	bar.anchor_right = 1.0
	bar.anchor_bottom = 1.0
	bar.offset_left = 14.0
	bar.offset_top = -126.0
	bar.offset_right = -328.0
	bar.offset_bottom = -14.0
	add_child(bar)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	bar.add_child(margin)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 6)
	margin.add_child(stack)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 18)
	stack.add_child(header)

	var faction_label := Label.new()
	var faction_def: Dictionary = Defs.faction(player.faction)
	faction_label.text = str(faction_def["name"])
	faction_label.add_theme_color_override("font_color", faction_def["color"])
	header.add_child(faction_label)

	_selection_label = Label.new()
	_selection_label.text = "未选中"
	_selection_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_selection_label)

	_res_label = Label.new()
	_res_label.text = "灵晶 200"
	header.add_child(_res_label)

	_pop_label = Label.new()
	_pop_label.text = "人口 0/0"
	header.add_child(_pop_label)

	_btn_box = HFlowContainer.new()
	_btn_box.add_theme_constant_override("separation", 10)
	_btn_box.custom_minimum_size.y = 34.0
	stack.add_child(_btn_box)

	_status = Label.new()
	_status.text = ""
	_status.modulate = Color(0.78, 0.76, 0.71)
	stack.add_child(_status)

	_ghost = GhostControl.new()
	_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ghost)


func _process(_delta: float) -> void:
	_res_label.text = "灵晶 %d" % player.crystals
	_pop_label.text = "人口 %d/%d" % [player.pop_used, player.pop_cap]
	_update_selection_label()
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
		for id in Defs.faction(player.faction)["build"]:
			_add_button(Defs.building_name(id, player.faction) + " %d" % int(Defs.building(id)["cost"]), _start_placement.bind(id))
	# 游侠在选 → 潜流切换
	var has_stealth := false
	for u in sel.selected:
		if u is Unit and u.can_stealth:
			has_stealth = true
			break
	if has_stealth:
		_add_button("潜流/现身", _toggle_stealth)
	# 选中己方完工建筑 → 训练 / 能力 / 迁移
	var b: Building = sel.selected_building
	if b != null and b.complete:
		var bdef: Dictionary = Defs.building(b.def_id)
		for uid in bdef.get("trains", []):
			var udef: Dictionary = Defs.unit(uid)
			_add_button("训练%s %d" % [udef["name"], int(udef["cost"])], _train_unit.bind(b, uid))
		for ability in bdef.get("abilities", []):
			var label := "军资补员（2份1兵）" if ability == "dust_summon" else "军资折晶（1份4晶）"
			_add_button(label, _run_ability.bind(b, ability))
		if player.faction == "yan" and not bdef.get("no_migrate", false) and not bdef.get("wall", false):
			_add_button("迁移", _start_migrate.bind(b))


func _context_signature() -> String:
	var worker := "0"
	var stealth := "0"
	for u in sel.selected:
		if u is Worker:
			worker = "1"
		elif u is Unit and u.can_stealth:
			stealth = "1"
	var b := "0"
	if sel.selected_building != null:
		b = str(sel.selected_building.get_instance_id())
	return worker + stealth + "|" + b


func _add_button(text: String, cb: Callable) -> void:
	var btn := Button.new()
	btn.text = text
	btn.tooltip_text = text
	btn.custom_minimum_size = Vector2(126, 34)
	btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	btn.pressed.connect(cb)
	_btn_box.add_child(btn)


func _update_selection_label() -> void:
	if sel == null:
		return
	if sel.selected_building != null:
		var b := sel.selected_building
		var bonus := "  ·  连营加固" if b.has_encampment_bonus() else ""
		_selection_label.text = "%s  HP %d/%d  ·  队列 %d%s" % [Defs.building_name(b.def_id, player.faction), int(b.hp), int(b.max_hp), b.queue_size(), bonus]
	elif sel.selected.size() == 1:
		var u := sel.selected[0]
		var unit_name := str(Defs.unit(u.unit_id).get("name", "单位"))
		var state := ""
		if u.ambush_time > 0.0:
			state = "  ·  现身突击"
		elif u.uses_water_network and u.is_in_shallow_water():
			state = "  ·  水网疾行"
		_selection_label.text = "%s  ·  %s  ·  HP %d/%d%s" % [unit_name, u.element, int(u.hp), int(u.max_hp), state]
	elif not sel.selected.is_empty():
		_selection_label.text = "已选中 %d 个单位" % sel.selected.size()
	else:
		_selection_label.text = "未选中  ·  左键框选，右键下令"


func _toggle_stealth() -> void:
	var revealed := false
	for u in sel.selected:
		if u is Unit and u.can_stealth:
			(u as Unit).toggle_stealth()
			revealed = revealed or not u.stealthed
	_status.text = "现身突击：3 秒移速与伤害 +25%" if revealed else "潜流形态：隐形 · 无法攻击 · 移速减半"
	_status_clear_at = Time.get_ticks_msec() + 2500


func _train_unit(hq: Building, unit_id: String) -> void:
	if hq.enqueue(unit_id):
		_status.text = "训练中…队列 %d" % hq.queue_size()
	else:
		_status.text = "灵晶或人口不足"
	_status_clear_at = Time.get_ticks_msec() + 2500


func _start_placement(id: String) -> void:
	_migrating = null
	_placing_id = id
	var near_resource := float(Defs.building(id).get("resource_radius", 0.0)) > 0.0
	_status.text = "点击灵脉附近放置，右键/ESC 取消" if near_resource else "点击地图放置，右键/ESC 取消"
	_status_clear_at = Time.get_ticks_msec() + 4000


func _run_ability(b: Building, ability: String) -> void:
	_status.text = b.run_ability(ability)
	_status_clear_at = Time.get_ticks_msec() + 2500


func _start_migrate(b: Building) -> void:
	_placing_id = ""
	_migrating = b
	_status.text = "迁制：点击新址落位，右键/ESC 取消"
	_status_clear_at = Time.get_ticks_msec() + 4000


func _active_ghost_id() -> String:
	if _placing_id != "":
		return _placing_id
	if _migrating != null:
		return _migrating.def_id
	return ""


func _unhandled_input(event: InputEvent) -> void:
	if _placing_id == "" and _migrating == null:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var wp := _screen_to_world(event.position)
			if _placement_valid(wp):
				if _migrating != null:
					_migrating.start_migrate(wp)
					_status.text = "迁移落位，自重建中…"
					_status_clear_at = Time.get_ticks_msec() + 2000
					_migrating = null
				else:
					_place(wp)
					_placing_id = ""
				get_viewport().set_input_as_handled()
			else:
				_status.text = "此处无法落位"
				_status_clear_at = Time.get_ticks_msec() + 1500
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_cancel_placement()
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		_cancel_placement()
		get_viewport().set_input_as_handled()
	var ghost_id := _active_ghost_id()
	if ghost_id != "":
		var mp := _screen_to_world(get_viewport().get_mouse_position())
		_ghost.update_ghost(mp, ghost_id, _placement_valid(mp))
	else:
		_ghost.update_ghost(Vector2.INF, "", false)


func _cancel_placement() -> void:
	_placing_id = ""
	_migrating = null
	_ghost.update_ghost(Vector2.INF, "", false)
	_ghost.update_ghost(Vector2.INF, "", false)


func _screen_to_world(p: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * p


func _placement_valid(wp: Vector2) -> bool:
	var id := _active_ghost_id()
	if id == "":
		return false
	if not _resource_requirement_met(id, wp):
		return false
	var size: Vector2 = Defs.building(id)["size"]
	var rect := Rect2(wp - size * 0.5 - Vector2.ONE * PLACE_MARGIN, size + Vector2.ONE * PLACE_MARGIN * 2.0)
	for b in map_root.get_tree().get_nodes_in_group("buildings"):
		if b is Building:
			# 迁移模式忽略自己
			if b == _migrating:
				continue
			var bs: Vector2 = Defs.building(b.def_id)["size"]
			if rect.intersects(Rect2(b.global_position - bs * 0.5, bs)):
				return false
	for n in map_root.get_tree().get_nodes_in_group("gather_nodes"):
		if n is Node2D and rect.has_point(n.global_position):
			return false
	return true


func _resource_requirement_met(id: String, wp: Vector2) -> bool:
	var radius := float(Defs.building(id).get("resource_radius", 0.0))
	if radius <= 0.0:
		return true
	for n in map_root.get_tree().get_nodes_in_group("gather_nodes"):
		if n is CrystalNode and not n.is_depleted() and wp.distance_to(n.global_position) <= radius:
			return true
	return false


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
	_status.text = "%s 施工中" % Defs.building_name(_placing_id, player.faction)
	_status_clear_at = Time.get_ticks_msec() + 2000


class GhostControl:
	extends Control
	var _pos := Vector2.INF
	var _id := ""
	var _valid := false

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
		var footprint: Vector2 = Defs.building(_id)["size"]
		var rect := Rect2(screen - footprint * 0.5, footprint)
		var col := Color(0.2, 0.6, 0.3, 0.4) if _valid else Color(0.75, 0.2, 0.15, 0.4)
		draw_rect(rect, col, true)
		draw_rect(rect, Color(col.r, col.g, col.b, 0.95), false, 2.0)
