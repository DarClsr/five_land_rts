extends Node2D
"""战斗回归测试：克制倍率 / 自动交战分出生死 / 灼烧 DoT / 「熄」清灼烧。"""

const TIMEOUT_FRAMES := 1800

var _fails := 0
var _frames := 0
var _duel_done := false
var _burn_done := false
var _tower_done := false
var _spawned := false


func _ready() -> void:
	print("TEST_COMBAT: 测试场景已加载")
	_build_nav()
	# 1) 克制倍率静态检查
	_check(Elements.multiplier("水", "火") == 1.25, "水克火应为 1.25")
	_check(Elements.multiplier("火", "金") == 1.25, "火克金应为 1.25")
	_check(Elements.multiplier("火", "火") == 1.0, "同行为 1.0")
	_check(Elements.multiplier("水", "凡") == 1.0, "凡品不吃克制")

	# 2) 自动交战：水游侠(克火) vs 火火矢手，近距离自发开战
	var a := Defs.spawn("youxia", 0)
	a.position = Vector2(-40, 0)
	add_child(a)
	var b := Defs.spawn("huoshishou", 1)
	b.position = Vector2(40, 0)
	add_child(b)
	set_meta("duel_a", a)
	set_meta("duel_b", b)

	# 3) 灼烧 DoT：直接点燃一个单位，验证掉血
	var c := Defs.spawn("baoyanzu", 0)
	c.position = Vector2(0, 400)
	add_child(c)
	set_meta("burn_unit", c)

	# 4) 烽燧自动射击
	var tower := Building.new()
	tower.setup("fengsui", 0, true)
	tower.position = Vector2(-200, 300)
	add_child(tower)
	var raider := Defs.spawn("youxia", 1)
	raider.position = Vector2(-80, 300)
	add_child(raider)
	set_meta("tower_target", raider)

	for i in 15:
		await get_tree().physics_frame
	c.burn_time = Elements.BURN_TIME
	set_meta("burn_hp0", c.hp)
	_spawned = true


func _physics_process(_delta: float) -> void:
	if not _spawned:
		return
	_frames += 1
	var c: Unit = get_meta("burn_unit")
	if not _burn_done and c != null and is_instance_valid(c):
		if _frames % 60 == 0 and c.burn_time <= 0.0:
			var hp0: float = get_meta("burn_hp0")
			_check(c.hp < hp0, "灼烧应持续掉血（%.1f → %.1f）" % [hp0, c.hp])
			_burn_done = true
			# 「熄」：水系攻击清灼烧并免疫
			var water := Defs.spawn("youxia", 1)
			add_child(water)
			c.take_damage(1.0, water)
			_check(c.burn_time == 0.0 and c.no_burn_until > 0, "熄应清除灼烧并设免疫")
			water.queue_free()
	if not _duel_done:
		var a = get_meta("duel_a")
		var b = get_meta("duel_b")
		var a_dead: bool = not is_instance_valid(a) or not a.alive
		var b_dead: bool = not is_instance_valid(b) or not b.alive
		if a_dead or b_dead:
			_check(b_dead and not a_dead, "水克火：游侠应胜火矢手（a死=%s b死=%s）" % [a_dead, b_dead])
			_duel_done = true
	if not _tower_done:
		var rt = get_meta("tower_target")
		if rt == null or not is_instance_valid(rt):
			_check(true, "烽燧击杀目标")
			_tower_done = true
		elif rt.hp < rt.max_hp:
			_check(true, "烽燧自动射击（hp %.0f/%.0f）" % [rt.hp, rt.max_hp])
			_tower_done = true
	if _burn_done and _duel_done and _tower_done:
		_finish()
	elif _frames >= TIMEOUT_FRAMES:
		_check(false, "超时：duel=%s burn=%s tower=%s" % [_duel_done, _burn_done, _tower_done])
		_finish()


func _build_nav() -> void:
	var region := NavigationRegion2D.new()
	add_child(region)
	var trav := PackedVector2Array([
		Vector2(-600, -400), Vector2(600, -400), Vector2(600, 600), Vector2(-600, 600),
	])
	var np := NavigationPolygon.new()
	var source := NavigationMeshSourceGeometryData2D.new()
	source.add_traversable_outline(trav)
	NavigationServer2D.bake_from_source_geometry_data(np, source)
	region.navigation_polygon = np


func _check(ok: bool, what: String) -> void:
	if ok:
		print("  PASS: " + what)
	else:
		_fails += 1
		print("  FAIL: " + what)


func _finish() -> void:
	if _fails == 0:
		print("TEST_COMBAT PASS")
		get_tree().quit(0)
	else:
		print("TEST_COMBAT FAIL: %d 项未过" % _fails)
		get_tree().quit(1)
