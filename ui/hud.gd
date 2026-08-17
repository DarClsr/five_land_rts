class_name BasicHUD
extends CanvasLayer
"""M0 极简 HUD：操作提示、状态行、框选矩形。"""

var sel_mgr: SelectionManager
var cam: Camera2D

var _status: Label
var _rect: SelectionRectControl


func _init() -> void:
	layer = 5


func _ready() -> void:
	var tips := Label.new()
	tips.text = "M0 骨架验证：左键点选/框选（Shift 加选） · 右键移动 · WASD/屏幕边缘平移 · 滚轮缩放 · 小地图点击跳转"
	tips.position = Vector2(16, 10)
	add_child(tips)

	_status = Label.new()
	_status.position = Vector2(16, 34)
	add_child(_status)

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
