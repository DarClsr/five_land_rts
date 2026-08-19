extends Node
"""资源点回归：验证 M1/M2 共享对称布局、富灵脉收益和小地图标记。"""

const EXPECTED_POSITIONS := [
	Vector2(-1300, 120), Vector2(-1080, 700),
	Vector2(1300, -120), Vector2(1080, -700),
	Vector2(-1120, -560), Vector2(1120, 560),
	Vector2(180, 80),
]

var _failures := 0


func _ready() -> void:
	await _check_map("res://maps/M1Map.tscn", "M1")
	await _check_map("res://maps/M2Map.tscn", "M2")
	if _failures == 0:
		print("TEST_RESOURCES PASS")
		get_tree().quit(0)
	else:
		push_error("TEST_RESOURCES FAIL: %d 项失败" % _failures)
		get_tree().quit(1)


func _check_map(path: String, label: String) -> void:
	var map := (load(path) as PackedScene).instantiate()
	add_child(map)
	for i in 5:
		await get_tree().physics_frame
	var nodes: Array[CrystalNode] = []
	for node in get_tree().get_nodes_in_group("gather_nodes"):
		if node is CrystalNode:
			nodes.append(node)
	_expect(nodes.size() == 7, "%s 应有 7 处灵脉" % label)
	_expect(_count_rich(nodes) == 1, "%s 应有 1 处富灵脉" % label)
	_expect(_total_amount(nodes) == 12000, "%s 总储量应为 12000" % label)
	for pos in EXPECTED_POSITIONS:
		_expect(_has_node_at(nodes, pos), "%s 应有资源点 %s" % [label, pos])
	var rich_node := _rich_node(nodes)
	_expect(rich_node != null and rich_node.trip_yield() == CrystalNode.RICH_YIELD,
		"%s 富灵脉单趟应产 12 灵晶" % label)
	var normal_node := _normal_node(nodes)
	_expect(normal_node != null and normal_node.trip_yield() == CrystalNode.NORMAL_YIELD,
		"%s 普通灵脉单趟应产 8 灵晶" % label)
	var nav_map: RID = map.get_world_2d().navigation_map
	for node in nodes:
		var closest: Vector2 = NavigationServer2D.map_get_closest_point(nav_map, node.global_position)
		_expect(closest.distance_to(node.global_position) <= CrystalNode.APPROACH_DIST,
			"%s 资源点 %s 应可到达" % [label, node.position])
	_expect(map.find_child("ResourceMarkers", true, false) != null, "%s 小地图应有资源标记层" % label)
	map.queue_free()
	await get_tree().process_frame


func _count_rich(nodes: Array[CrystalNode]) -> int:
	var count := 0
	for node in nodes:
		if node.rich:
			count += 1
	return count


func _total_amount(nodes: Array[CrystalNode]) -> int:
	var total := 0
	for node in nodes:
		total += node.amount
	return total


func _has_node_at(nodes: Array[CrystalNode], pos: Vector2) -> bool:
	for node in nodes:
		if node.position.is_equal_approx(pos):
			return true
	return false


func _rich_node(nodes: Array[CrystalNode]) -> CrystalNode:
	for node in nodes:
		if node.rich:
			return node
	return null


func _normal_node(nodes: Array[CrystalNode]) -> CrystalNode:
	for node in nodes:
		if not node.rich:
			return node
	return null


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("  PASS: " + message)
	else:
		_failures += 1
		push_error("  FAIL: " + message)
