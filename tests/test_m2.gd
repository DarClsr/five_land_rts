extends Node2D
"""M2 综合回归：眩晕 / 兵魄增伤光环 / 窑火匠修缮 / 皇陵归尘 / 坊墙封路（NavRegistry）。"""

const TIMEOUT_FRAMES := 4200  # 70 秒
const WALL := Rect2(-20, -220, 40, 440)
const A := Vector2(-700, 0)
const B := Vector2(700, 0)

var _fails := 0
var _frames := 0
var _phase := 0  # 0 前置检查 → 1 无墙直达 → 2 有墙绕行 → 3 拆墙恢复
var _violated := false
var walker: Unit
var registry: NavRegistry


func _ready() -> void:
	print("TEST_M2: 场景加载")
	# 导航：开阔场地 1600x900
	var trav := PackedVector2Array([
		Vector2(-800, -450), Vector2(800, -450), Vector2(800, 450), Vector2(-800, 450)])
	registry = NavRegistry.new()
	registry.setup(self, trav, [])
	add_child(registry)

	var player := PlayerState.new()
	player.setup(0, "yan")
	player.pop_cap = 20
	add_child(player)

	# 眩晕：地灵师攻击附带
	var dls := Defs.spawn("dilingshi", 0)
	dls.position = Vector2(-300, -350)
	add_child(dls)
	var dummy := Defs.spawn("youxia", 1)
	dummy.position = Vector2(-260, -350)
	add_child(dummy)
	dummy.take_damage(3.0, dls)
	_check(dummy.stun_time > 0.0, "地灵师命中应眩晕（stun=%.2f）" % dummy.stun_time)
	dls.queue_free()
	dummy.queue_free()

	# 增伤光环：兵魄邻位
	var po := Defs.spawn("xuantiebingpo", 0)
	po.position = Vector2(0, 200)
	add_child(po)
	var guard := Defs.spawn("yanjiawei", 0)
	guard.position = Vector2(40, 200)
	add_child(guard)
	set_meta("guard", guard)
	set_meta("guard_hp0", guard.hp)

	# 修缮光环：窑火匠邻位受伤巨俑回血（扣血须在入场后，_ready 会重置 hp）
	var kiln := Defs.spawn("yaohuojiang", 0)
	kiln.position = Vector2(0, 320)
	add_child(kiln)
	var puppet := Defs.spawn("juyong", 0)
	puppet.position = Vector2(50, 320)
	add_child(puppet)
	puppet.hp = puppet.max_hp * 0.5
	set_meta("puppet", puppet)
	set_meta("puppet_hp0", puppet.hp)

	# 皇陵归尘
	var tomb := Building.new()
	tomb.setup("huangling", 0, true)
	tomb.position = Vector2(-400, -300)
	add_child(tomb)
	for i in 5:
		var d := Dust.new()
		d.position = Vector2(-380 + i * 20.0, -280)
		add_child(d)
	var msg: String = tomb.run_ability("dust_summon")
	var puppets := 0
	for u in get_tree().get_nodes_in_group("units"):
		if u is Unit and u.element == "凡" and u.attack_range > 0.0:
			puppets += 1
	_check(msg.contains("×2") and puppets >= 1, "归尘唤俑应 2 尘唤 1 俑（%s，陶俑 %d）" % [msg, puppets])
	var left := get_tree().get_nodes_in_group("dust").size()
	var msg2: String = tomb.run_ability("dust_crystal")
	_check(left >= 1 and msg2.contains("+4"), "归尘炼晶（余尘 %d，%s）" % [left, msg2])

	# 坊墙封路：走者 A→B
	walker = Unit.new()
	walker.team = 0
	walker.position = A
	add_child(walker)
	for i in 20:
		await get_tree().physics_frame
	walker.command_move_to(B)
	_phase = 1
	print("  PHASE 1: 无墙直达")


func _physics_process(_delta: float) -> void:
	_frames += 1
	if walker == null:
		return
	# 光环检查（第 90 帧，0.6s 扫描已跑）
	if _frames == 90:
		var guard: Unit = get_meta("guard")
		var puppet: Unit = get_meta("puppet")
		print("  诊断: guard=%s buff=%.2f po_dist=%.0f stun=%.2f | puppet hp=%.0f/%.0f" % [
			guard.global_position, guard.dmg_buff_mult,
			guard.global_position.distance_to(Vector2(0, 200)), guard.stun_time,
			puppet.hp, float(get_meta("puppet_hp0"))])
		_check(guard.dmg_buff_mult > 1.15, "兵魄增伤光环（×%.2f）" % guard.dmg_buff_mult)
		_check(puppet.hp > float(get_meta("puppet_hp0")), "窑火匠修缮光环（%.0f→%.0f）" % [float(get_meta("puppet_hp0")), puppet.hp])
	if _phase == 2 and WALL.has_point(walker.global_position):
		_violated = true
	if walker.global_position.distance_to(B) < 110.0:
		match _phase:
			1:
				registry.add_obstruction(PackedVector2Array([
					WALL.position, Vector2(WALL.end.x, WALL.position.y), WALL.end, Vector2(WALL.position.x, WALL.end.y)]))
				_reset_walker()
				_phase = 2
				print("  PHASE 2: 坊墙封路，应绕行")
			2:
				registry._dynamic.clear()
				registry._rebake()
				_reset_walker()
				_phase = 3
				print("  PHASE 3: 拆墙恢复直达")
			3:
				_finish()


func _reset_walker() -> void:
	walker.global_position = A
	walker.velocity = Vector2.ZERO
	walker.command_move_to(B)


func _check(ok: bool, what: String) -> void:
	if ok:
		print("  PASS: " + what)
	else:
		_fails += 1
		print("  FAIL: " + what)


func _finish() -> void:
	_check(not _violated, "全程无穿墙")
	if _fails == 0:
		print("TEST_M2 PASS")
		get_tree().quit(0)
	else:
		print("TEST_M2 FAIL: %d 项未过" % _fails)
		get_tree().quit(1)
