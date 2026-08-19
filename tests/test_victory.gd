extends Node2D
"""胜负回归测试：直接摧毁敌方大寨，断言弹出胜利结算并暂停。"""

const TIMEOUT_FRAMES := 360  # 6 秒内应结算

var _frames := 0
var _destroyed := false


func _ready() -> void:
	print("TEST_VICTORY: 测试场景已加载")
	process_mode = Node.PROCESS_MODE_ALWAYS  # 结算会暂停场景，测试节点必须照常运行
	var map := (load("res://maps/M1Map.tscn") as PackedScene).instantiate()
	add_child(map)
	for i in 15:
		await get_tree().physics_frame
	var enemy_hq: Building = null
	for b in get_tree().get_nodes_in_group("buildings"):
		if b is Building and b.team == 1 and b.is_hq():
			enemy_hq = b
			break
	if enemy_hq == null:
		_fail("找不到敌方大寨")
		return
	enemy_hq.take_damage(99999.0, null)
	_destroyed = true
	print("TEST_VICTORY: 敌方大寨已摧毁，等待结算…")


func _physics_process(_delta: float) -> void:
	if not _destroyed:
		return
	_frames += 1
	var screen := get_tree().get_first_node_in_group("end_screen")
	if screen != null:
		var paused: bool = get_tree().paused
		if paused:
			print("TEST_VICTORY PASS: 结算画面出现且游戏已暂停（%d 帧）" % _frames)
			get_tree().paused = false
			get_tree().quit(0)
		else:
			_fail("结算出现但未暂停")
	elif _frames >= TIMEOUT_FRAMES:
		_fail("超时：结算画面未出现")


func _fail(msg: String) -> void:
	print("TEST_VICTORY FAIL: ", msg)
	get_tree().paused = false
	get_tree().quit(1)
