class_name BasicHUD
extends CanvasLayer
"""战场顶部信息与框选矩形。"""

var sel_mgr: SelectionManager
var cam: Camera2D
@export var tips_text := "M0 骨架验证：左键点选/框选（Shift 加选） · 右键移动 · WASD/屏幕边缘平移 · 滚轮缩放 · 小地图点击跳转"

var _status: Label
var _rect: SelectionRectControl


func _init() -> void:
	layer = 5


func _ready() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	panel.offset_left = 14.0
	panel.offset_top = 12.0
	panel.offset_right = -14.0
	panel.offset_bottom = 68.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 7)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	margin.add_child(box)

	var tips := Label.new()
	tips.text = tips_text
	tips.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(tips)

	_status = Label.new()
	_status.modulate = Color(0.78, 0.76, 0.71)
	box.add_child(_status)

	_rect = SelectionRectControl.new()
	add_child(_rect)


func setup(selection: SelectionManager, camera: Camera2D) -> void:
	sel_mgr = selection
	cam = camera


func _process(_delta: float) -> void:
	if _status == null:
		return
	var count := sel_mgr.selected.size() if sel_mgr else 0
	var z := cam.zoom.x if cam else 1.0
	_status.text = "选中 %d · FPS %d · 缩放 %.2f×" % [count, Engine.get_frames_per_second(), z]


func set_drag_rect(rect) -> void:
	_rect.set_drag(rect if rect is Rect2 else Rect2())


class SelectionRectControl:
	extends Control
	var _rect := Rect2()

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_drag(rect: Rect2) -> void:
		_rect = rect if rect != null else Rect2()
		queue_redraw()

	func _draw() -> void:
		if _rect.size == Vector2.ZERO:
			return
		draw_rect(_rect, Color(0.78, 0.22, 0.16, 0.10), true)
		draw_rect(_rect, Color(0.78, 0.22, 0.16, 0.95), false, 1.5)
