extends Node2D
"""经济回归测试：命 1 个炎民采矿，验证灵晶两趟入账。"""

const TIMEOUT_FRAMES := 2400  # 60Hz × 40 秒

var player: PlayerState
var worker: Worker
var _frames := 0
var _node: CrystalNode


func _ready() -> void:
	print("TEST_ECON: 测试场景已加载")
	var map := (load("res://maps/M1Map.tscn") as PackedScene).instantiate()
	add_child(map)
	for i in 15:
		await get_tree().physics_frame  # 等导航网格同步
	player = PlayerState.for_team(map, 0)
	for u in get_tree().get_nodes_in_group("units"):
		if u is Worker and u.team == 0:
			worker = u
			break
	if player == null or worker == null:
		_fail("找不到玩家或炎民")
		return
	var node: CrystalNode = null
	for n in get_tree().get_nodes_in_group("gather_nodes"):
		if n is CrystalNode and not n.is_depleted():
			node = n
			break
	if node == null:
		_fail("找不到灵脉矿")
		return
	_node = node
	worker.command_gather(node)
	print("TEST_ECON: 开始采集，矿位 %s，初始灵晶 %d" % [node.global_position, player.crystals])


func _node_pos() -> Vector2:
	return _node.global_position if _node != null else Vector2.ZERO


func _physics_process(_delta: float) -> void:
	if player == null:
		return
	_frames += 1
	if _frames % 300 == 0:
		print("  %2ds: 灵晶=%d 状态=%d 携带=%d pos=%s 到矿=%d agent完=%s" % [
			_frames / 60, player.crystals, worker.state, worker.carry,
			worker.global_position, int(worker.global_position.distance_to(_node_pos())), worker.is_nav_finished_diag()])
	if player.crystals >= PlayerState.START_CRYSTALS + 16:
		print("TEST_ECON PASS: %d 帧（%ds）完成两趟采集，灵晶 %d" % [_frames, _frames / 60, player.crystals])
		get_tree().quit(0)
	elif _frames >= TIMEOUT_FRAMES:
		_fail("timeout: 灵晶=%d 状态=%d 携带=%d" % [player.crystals, worker.state, worker.carry])


func _fail(msg: String) -> void:
	print("TEST_ECON FAIL: ", msg)
	get_tree().quit(1)
