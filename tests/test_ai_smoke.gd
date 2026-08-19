extends Node2D
"""AI 冒烟测试：跑 90 秒，验证敌方 AI 在运营（生产/采矿）并按期发起首波进攻。"""

const TIMEOUT_FRAMES := 10800  # 60Hz × 180 秒

var _frames := 0
var _started := false
var _econ_ok := false
var _wave_ok := false


func _ready() -> void:
	print("TEST_AI: 测试场景已加载")
	var map := (load("res://maps/M1Map.tscn") as PackedScene).instantiate()
	add_child(map)
	for i in 15:
		await get_tree().physics_frame
	_started = true


func _physics_process(_delta: float) -> void:
	if not _started:
		return
	_frames += 1
	# 30 秒：AI 应有运营迹象（民夫增加 / 队列在转 / 灵晶变动）
	if _frames == 1800:
		var player1 := PlayerState.for_team(self, 1)
		var workers := 0
		for u in get_tree().get_nodes_in_group("units"):
			if u is Worker and u.team == 1:
				workers += 1
		var hq_queue := 0
		for b in get_tree().get_nodes_in_group("buildings"):
			if b is Building and b.team == 1 and b.is_hq():
				hq_queue = b.queue_size()
		_econ_ok = workers >= 4 or hq_queue > 0 or (player1 != null and player1.crystals != 300)
		print("TEST_AI 30s: 民夫=%d 大寨队列=%d 灵晶=%s 运营=%s" % [
			workers, hq_queue, player1.crystals if player1 != null else -1, _econ_ok])
	# 160 秒：首波应已发出（首波缓冲 150s）
	if _frames == 9600:
		var ai := get_tree().get_first_node_in_group("enemy_ai")
		_wave_ok = ai != null and ai.wave_count >= 1
		print("TEST_AI 160s: 已发波 %d 波=%s" % [ai.wave_count if ai != null else -1, _wave_ok])
	if _frames >= TIMEOUT_FRAMES:
		if _econ_ok and _wave_ok:
			print("TEST_AI PASS")
			get_tree().quit(0)
		else:
			print("TEST_AI FAIL: 运营=%s 发波=%s" % [_econ_ok, _wave_ok])
			get_tree().quit(1)
