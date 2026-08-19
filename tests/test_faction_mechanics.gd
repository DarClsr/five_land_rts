extends Node2D
"""势力机制回归：曹魏军屯扩张经济与蜀汉连营相邻加固。"""

const SHALLOW_WATER := preload("res://art/shallow_water.gd")

var _failures := 0


func _ready() -> void:
	await _check_wei_farm()
	await _check_shu_encampment()
	await _check_wu_water_network()
	await _check_wu_watchtower()
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


func _check_wu_water_network() -> void:
	var player := PlayerState.new()
	player.setup(3, "shuo")
	add_child(player)
	var water := SHALLOW_WATER.new()
	water.position = Vector2(0, 900)
	water.size = Vector2(300, 160)
	add_child(water)
	var scout := Defs.spawn("youxia", 3)
	scout.position = water.position
	add_child(scout)
	var wei_guard := Defs.spawn("yanjiawei", 0)
	wei_guard.position = water.position
	add_child(wei_guard)
	await get_tree().process_frame
	_expect(is_equal_approx(scout._speed_mult(), Unit.WATER_SPEED_MULT), "东吴水军在浅水中移速 +35%")
	_expect(is_equal_approx(wei_guard._speed_mult(), 1.0), "曹魏单位不获得水网加速")
	scout.position = Vector2(500, 900)
	scout.toggle_stealth()
	_expect(is_equal_approx(scout._speed_mult(), 0.5), "锦帆游侠潜行时保持半速")
	scout.toggle_stealth()
	_expect(is_equal_approx(scout._speed_mult(), Unit.AMBUSH_MULT), "主动现身后移速 +25%")
	var dummy := Unit.new()
	dummy.team = 9
	dummy.element = "凡"
	dummy.max_hp = 100.0
	dummy.position = Vector2(560, 900)
	add_child(dummy)
	await get_tree().process_frame
	var hp_before := dummy.hp
	dummy.take_damage(40.0, scout)
	_expect(is_equal_approx(hp_before - dummy.hp, 50.0), "现身突击伤害 +25%")
	scout._update_status(Unit.AMBUSH_TIME + 0.1)
	_expect(is_equal_approx(scout.attack_damage_multiplier(), 1.0), "现身突击 3 秒后结束")


func _check_wu_watchtower() -> void:
	var wu_player := PlayerState.new()
	wu_player.setup(4, "shuo")
	add_child(wu_player)
	var watchtower := Building.new()
	watchtower.setup("fengsui", 4, true)
	watchtower.position = Vector2(0, 1300)
	add_child(watchtower)
	var hidden_enemy := Unit.new()
	hidden_enemy.team = 5
	hidden_enemy.max_hp = 100.0
	hidden_enemy.position = Vector2(100, 1300)
	hidden_enemy.stealthed = true
	add_child(hidden_enemy)
	await get_tree().process_frame
	watchtower._tower_tick(2.0)
	for i in 30:
		await get_tree().physics_frame
	_expect(hidden_enemy.hp < hidden_enemy.max_hp, "东吴水寨瞭台可攻击潜行单位")
	_expect(hidden_enemy.slow_time > 0.0, "水寨瞭台命中附带减速")

	var shu_tower := Building.new()
	shu_tower.setup("fengsui", 2, true)
	shu_tower.position = Vector2(0, 1600)
	add_child(shu_tower)
	var hidden_enemy_2 := Unit.new()
	hidden_enemy_2.team = 6
	hidden_enemy_2.max_hp = 100.0
	hidden_enemy_2.position = Vector2(100, 1600)
	hidden_enemy_2.stealthed = true
	add_child(hidden_enemy_2)
	await get_tree().process_frame
	shu_tower._tower_tick(2.0)
	for i in 30:
		await get_tree().physics_frame
	_expect(is_equal_approx(hidden_enemy_2.hp, hidden_enemy_2.max_hp), "蜀汉烽火台不能攻击潜行单位")
	_expect(hidden_enemy_2.slow_time <= 0.0, "蜀汉烽火台不附带东吴减速")


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("  PASS: " + message)
	else:
		_failures += 1
		push_error("  FAIL: " + message)
