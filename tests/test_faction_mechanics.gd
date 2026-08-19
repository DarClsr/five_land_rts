extends Node2D
"""势力机制回归：曹魏军屯扩张经济与蜀汉连营相邻加固。"""

var _failures := 0


func _ready() -> void:
	await _check_wei_farm()
	await _check_shu_encampment()
	if _failures == 0:
		print("TEST_FACTION_MECHANICS PASS")
		get_tree().quit(0)
	else:
		push_error("TEST_FACTION_MECHANICS FAIL: %d 项失败" % _failures)
		get_tree().quit(1)


func _check_wei_farm() -> void:
	var player := PlayerState.new()
	player.setup(0, "yan")
	add_child(player)
	var vein := CrystalNode.new()
	vein.position = Vector2.ZERO
	add_child(vein)
	var bar := BuildBar.new()
	bar.map_root = self
	bar._placing_id = "fangshi"
	_expect(bar._placement_valid(Vector2(240, 0)), "军屯可建在灵脉附近")
	_expect(not bar._placement_valid(Vector2(700, 0)), "军屯不可远离灵脉建造")
	bar.free()

	var hq := Building.new()
	hq.setup("yashu", 0, true)
	hq.position = Vector2(900, 0)
	add_child(hq)
	var farm := Building.new()
	farm.setup("fangshi", 0, true)
	farm.position = Vector2(240, 0)
	add_child(farm)
	var worker := Defs.spawn("yongjiang", 0) as Worker
	worker.position = Vector2(80, 0)
	add_child(worker)
	await get_tree().process_frame
	_expect(farm.is_dropoff() and not farm.is_hq(), "军屯是回缴点但不是主基地")
	_expect(player.pop_cap == 14, "主基地与军屯共提供 14 人口上限")
	_expect(worker._find_hq() == farm, "民夫优先向最近军屯回缴")
	var victory := VictoryManager.new()
	victory.setup(self)
	_expect(victory._find_hq(0) == hq, "胜负判定仍锁定司空府")
	victory.free()


func _check_shu_encampment() -> void:
	var player := PlayerState.new()
	player.setup(2, "li")
	add_child(player)
	var target := Building.new()
	target.setup("yanzhen", 2, true)
	target.position = Vector2(0, 500)
	add_child(target)
	var camp := Building.new()
	camp.setup("gaizhang", 2, true)
	camp.position = Vector2(180, 500)
	add_child(camp)
	await get_tree().process_frame
	var hp_before := target.hp
	target.take_damage(100.0, null)
	_expect(target.has_encampment_bonus(), "蜀汉建筑获得邻近连营加固")
	_expect(is_equal_approx(hp_before - target.hp, 85.0), "连营加固使建筑伤害降低 15%")
	camp.position = Vector2(400, 500)
	await get_tree().process_frame
	hp_before = target.hp
	target.take_damage(100.0, null)
	_expect(not target.has_encampment_bonus(), "离开连营范围后加固失效")
	_expect(is_equal_approx(hp_before - target.hp, 100.0), "无连营时建筑承受完整伤害")


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("  PASS: " + message)
	else:
		_failures += 1
		push_error("  FAIL: " + message)
