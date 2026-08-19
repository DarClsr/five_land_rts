class_name Minimap
extends CanvasLayer
"""小地图：SubViewport 共享世界渲染全景，点击跳转相机。"""

const PANEL_SIZE := Vector2(300.0, 169.0)
const MARGIN := 14.0

var cam_ref: Camera2D
var map_rect: Rect2
var _tex: TextureRect


func _init() -> void:
	layer = 10


func setup(world_cam: Camera2D, rect: Rect2, sub_parent: Node) -> void:
	cam_ref = world_cam
	map_rect = rect

	var sub := SubViewport.new()
	sub.size = Vector2i(480, 270)
	sub.world_2d = sub_parent.get_tree().root.world_2d
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sub_parent.add_child(sub)

	var mini_cam := Camera2D.new()
	sub.add_child(mini_cam)
	mini_cam.position = rect.get_center()
	mini_cam.zoom = Vector2(float(sub.size.x) / rect.size.x, float(sub.size.y) / rect.size.y)
	mini_cam.make_current()

	_build_panel(sub)


func _build_panel(sub: SubViewport) -> void:
	var frame := ColorRect.new()
	frame.anchor_left = 1.0
	frame.anchor_top = 1.0
	frame.anchor_right = 1.0
	frame.anchor_bottom = 1.0
	frame.offset_left = -PANEL_SIZE.x - MARGIN - 2.0
	frame.offset_top = -PANEL_SIZE.y - MARGIN - 2.0
	frame.offset_right = -MARGIN + 2.0
	frame.offset_bottom = -MARGIN + 2.0
	frame.color = Color(0.12, 0.11, 0.10, 0.85)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)

	_tex = TextureRect.new()
	_tex.anchor_left = 1.0
	_tex.anchor_top = 1.0
	_tex.anchor_right = 1.0
	_tex.anchor_bottom = 1.0
	_tex.offset_left = -PANEL_SIZE.x - MARGIN
	_tex.offset_top = -PANEL_SIZE.y - MARGIN
	_tex.offset_right = -MARGIN
	_tex.offset_bottom = -MARGIN
	_tex.texture = sub.get_texture()
	_tex.stretch_mode = TextureRect.STRETCH_SCALE
	_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tex.gui_input.connect(_on_gui)
	add_child(_tex)

	var markers := ResourceMarkers.new()
	markers.name = "ResourceMarkers"
	markers.setup(map_rect)
	markers.anchor_left = 1.0
	markers.anchor_top = 1.0
	markers.anchor_right = 1.0
	markers.anchor_bottom = 1.0
	markers.offset_left = -PANEL_SIZE.x - MARGIN
	markers.offset_top = -PANEL_SIZE.y - MARGIN
	markers.offset_right = -MARGIN
	markers.offset_bottom = -MARGIN
	markers.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(markers)


func _on_gui(event: InputEvent) -> void:
	var press: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	var drag: bool = event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0
	if press or drag:
		_jump(event.position)


func _jump(local_pos: Vector2) -> void:
	var world := map_rect.position + (local_pos / PANEL_SIZE) * map_rect.size
	cam_ref.position = world


class ResourceMarkers:
	extends Control

	var map_rect: Rect2
	var _timer := 0.0

	func setup(rect: Rect2) -> void:
		map_rect = rect

	func _process(delta: float) -> void:
		_timer += delta
		if _timer >= 0.25:
			_timer = 0.0
			queue_redraw()

	func _draw() -> void:
		var fog := get_tree().get_first_node_in_group("fog_of_war") as FogOfWar
		for candidate in get_tree().get_nodes_in_group("gather_nodes"):
			var node := candidate as CrystalNode
			if node == null:
				continue
			if fog != null and not fog.is_explored(node.global_position):
				continue
			var marker_pos: Vector2 = ((node.global_position - map_rect.position) / map_rect.size) * size
			var color := CrystalNode.DEPLETED_COLOR
			if not node.is_depleted():
				color = CrystalNode.RICH_COLOR if node.rich else CrystalNode.NORMAL_COLOR
			var radius := 4.5 if node.rich else 3.0
			draw_circle(marker_pos, radius, color)
			draw_arc(marker_pos, radius + 1.5, 0.0, TAU, 12, Color(0.08, 0.07, 0.06, 0.9), 1.0)
