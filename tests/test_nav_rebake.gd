extends Node2D
"""M2 技术风险一号：土系地形改造 = 导航网格运行时重烘焙验证。

场景：开阔地图中央垒一道竖墙 → 单位必须绕行且不得穿墙 → 拆墙后恢复直达。
验收：绕行成功 + 无穿墙 + 重烘焙耗时可接受。
"""

const MAP := Rect2(-1600, -900, 3200, 1800)
const WALL := Rect2(-20, -400, 40, 800)  # 竖墙居中，留上下通道
const A := Vector2(-1300, 0)
const B := Vector2(1300, 0)
const PHASE_TIMEOUT := 2500  # 每阶段 ~42 秒

var region: NavigationRegion2D
var walls: Array[PackedVector2Array] = []
var walker: Unit
var phase := 0  # 0 开阔 / 1 有墙 / 2 拆墙
var _frames := 0
var _violated := false
var _bake_ms: Array[float] = []


func _ready() -> void:
	print("TEST_REBAKE: 场景加载")
	region = NavigationRegion2D.new()
	add_child(region)
	_rebuild()
	walker = Unit.new()
	walker.team = 0
	walker.position = A
	add_child(walker)
	for i in 20:
		await get_tree().physics_frame  # 等导航同步
	walker.command_move_to(B)
	print("PHASE 0: 开阔地 A→B 直达")


func _physics_process(_delta: float) -> void:
	if walker == null:
		return
	_frames += 1
	if phase == 1 and WALL.has_point(walker.global_position):
		_violated = true
	if walker.global_position.distance_to(B) < 120.0:
		match phase:
			0:
				_enter(1)
			1:
				_enter(2)
			2:
				_finish()
	elif _frames >= PHASE_TIMEOUT:
		_fail("阶段 %d 超时（位置 %s）" % [phase, walker.global_position])


func _enter(next: int) -> void:
	phase = next
	_frames = 0
	if next == 1:
		walls = [_wall_corners(WALL)]
		var ms := _rebuild()
		_bake_ms.append(ms)
		print("PHASE 1: 垒墙（重烘焙 %.0fms），再次 A→B 应绕行" % ms)
	elif next == 2:
		walls = []
		var ms := _rebuild()
		_bake_ms.append(ms)
		print("PHASE 2: 拆墙（重烘焙 %.0fms），恢复直达" % ms)
	walker.global_position = A
	walker.velocity = Vector2.ZERO
	walker.command_move_to(B)


func _wall_corners(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([
		r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])


func _rebuild() -> float:
	var t0 := Time.get_ticks_msec()
	var inset := 60.0
	var trav := PackedVector2Array([
		MAP.position + Vector2(inset, inset),
		Vector2(MAP.end.x - inset, MAP.position.y + inset),
		MAP.end - Vector2(inset, inset),
		Vector2(MAP.position.x + inset, MAP.end.y - inset),
	])
	var np := NavigationPolygon.new()
	var src := NavigationMeshSourceGeometryData2D.new()
	src.add_traversable_outline(trav)
	for w in walls:
		src.add_obstruction_outline(w)
	NavigationServer2D.bake_from_source_geometry_data(np, src)
	region.navigation_polygon = np
	return float(Time.get_ticks_msec() - t0)


func _finish() -> void:
	var max_ms: float = 0.0
	for m in _bake_ms:
		max_ms = maxf(max_ms, m)
	if _violated:
		_fail("单位穿墙——重烘焙未生效")
	elif max_ms > 200.0:
		_fail("重烘焙过慢：%.0fms" % max_ms)
	else:
		print("TEST_REBAKE PASS: 绕行成功、无穿墙，重烘焙最大 %.0fms" % max_ms)
		get_tree().quit(0)


func _fail(msg: String) -> void:
	print("TEST_REBAKE FAIL: ", msg)
	get_tree().quit(1)
