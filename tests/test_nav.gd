extends Node2D
"""导航回归测试：实例化 TestMap，命一个单位横穿地图（跨障碍），验证抵达。"""

const TARGET := Vector2(1200.0, -700.0)
const TIMEOUT_FRAMES := 1800  # 60Hz 物理帧 × 30 秒

var _unit: Unit
var _start := Vector2.ZERO
var _frames := 0


func _ready() -> void:
	print("TEST_NAV: 测试场景已加载")
	var map := (load("res://maps/TestMap.tscn") as PackedScene).instantiate()
	add_child(map)
	for i in 15:
		await get_tree().physics_frame  # 等导航网格同步
	for u in get_tree().get_nodes_in_group("units"):
		if u is Unit and u.team == 0:
			_unit = u
			break
	if _unit == null:
		_fail("no own unit found")
		return
	_start = _unit.global_position
	_unit.command_move_to(TARGET)


func _physics_process(_delta: float) -> void:
	if _unit == null:
		return
	_frames += 1
	if _frames % 120 == 0:
		print("  轨迹 %3d 帧: pos=%s next=%s vel=%s finished=%s" % [_frames, _unit.global_position, _unit.diag_next_path_pos(), _unit.velocity, _unit.is_nav_finished_diag()])
	var dist := _unit.global_position.distance_to(TARGET)
	if dist < 120.0:
		var progressed := _start.distance_to(TARGET) - dist
		print("TEST_NAV PASS: start=%s end=%s 距目标 %.1fpx（推进 %.1fpx，%d 帧）" % [_start, _unit.global_position, dist, progressed, _frames])
		get_tree().quit(0)
	elif _frames >= TIMEOUT_FRAMES:
		_fail("timeout: 卡在 %s，距目标 %.1fpx" % [_unit.global_position, dist])


func _fail(msg: String) -> void:
	print("TEST_NAV FAIL: ", msg)
	get_tree().quit(1)
