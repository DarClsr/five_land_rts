class_name EnemyAI
extends Node
"""M1 敌方 AI：经济运营（民夫采集/补充/人口）+ 兵营造兵 + 集结 + 波次进攻。

波次进攻 = 移动指令推向敌方大寨，途中依靠单位自动索敌接战——行为自然且实现简单。
难度参数全部 @export，M3 做难度分级时直接调整。
"""

@export var keep_workers := 5          # 民夫维持数
@export var base_wave := 4             # 首波规模
@export var wave_growth := 2           # 每波增量
@export var max_wave := 10             # 波次上限
@export var wave_cooldown := 45.0      # 波间冷却（秒）
@export var first_wave_delay := 120.0  # 首波缓冲（给玩家发展时间）
@export var tick_interval := 2.0
@export var barracks_id := "yanzhen"   # 兵营建筑 id（朔国为影卫堂）

var team_id := 1
var root: Node2D

var _timer := 0.0
var _wave_size := 0
var _wave_active := false
var _wave_elapsed := 0.0
var _wave_units: Array[Unit] = []
var _cooldown := 0.0
var _built_count := 0
var wave_count := 0


func setup(id: int, map_root: Node2D) -> void:
	team_id = id
	root = map_root
	_wave_size = base_wave
	_cooldown = first_wave_delay
	add_to_group("enemy_ai")


func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = tick_interval
		_tick()
	_wave_elapsed += delta
	_cooldown -= delta
	_update_wave()


func _tick() -> void:
	var player := PlayerState.for_team(root, team_id)
	if player == null:
		return
	var workers: Array[Worker] = []
	var troops: Array[Unit] = []
	for u in root.get_tree().get_nodes_in_group("units"):
		if u is Unit and u.team == team_id and u.alive:
			if u is Worker:
				workers.append(u)
			elif u.attack_range > 0.0:
				troops.append(u)
	var hq := _find_building("dazhai")

	# 民夫闲置 → 采矿
	for w in workers:
		if w.state == Worker.State.IDLE:
			var node := _nearest_node(w)
			if node != null:
				w.command_gather(node)

	# 补民夫
	if hq != null and workers.size() < keep_workers and hq.queue_size() == 0:
		hq.enqueue("yanmin")

	# 人口不足 → 造篝帐（免施工，直接落成）
	if player.pop_used + 1 > player.pop_cap and player.can_spend(60) and hq != null:
		_place_tent(player, hq)

	# 造兵：游侠 3 / 冰凌 2 / 潮灵 1 循环
	var barracks := _find_building(barracks_id)
	if barracks != null and troops.size() + barracks.queue_size() < _wave_size and barracks.queue_size() < 2:
		var pick := "youxia"
		var m := _built_count % 6
		if m == 3 or m == 4:
			pick = "binglingshou"
		elif m == 5:
			pick = "chaoling"
		if barracks.enqueue(pick):
			_built_count += 1

	# 平时集结于基地前
	if not _wave_active and hq != null:
		var guard := _guard_point(hq)
		for t in troops:
			if t.attack_target == null and t.global_position.distance_to(guard) > 240.0:
				t.command_move_to(guard + Vector2(randf_range(-60, 60), randf_range(-60, 60)))

	# 发波
	if not _wave_active and hq != null and troops.size() >= _wave_size and _cooldown <= 0.0:
		_start_wave(troops)


func _start_wave(troops: Array[Unit]) -> void:
	_wave_active = true
	_wave_elapsed = 0.0
	_wave_units.clear()
	wave_count += 1
	var target := _enemy_hq_pos()
	print("[AI] 发起第 %d 波：%d 单位 → %s" % [wave_count, troops.size(), target])
	for t in troops:
		_wave_units.append(t)
		t.command_move_to(target + Vector2(randf_range(-120, 120), randf_range(-120, 120)))


func _update_wave() -> void:
	if not _wave_active:
		return
	var alive := 0
	for u in _wave_units:
		if is_instance_valid(u) and u.alive:
			alive += 1
	if alive == 0 or _wave_elapsed > 90.0:
		_wave_active = false
		_wave_units.clear()
		_wave_size = mini(_wave_size + wave_growth, max_wave)
		_cooldown = wave_cooldown
		print("[AI] 第 %d 波结束（存活 %d），下一波 %d 单位" % [wave_count, alive, _wave_size])


func _find_building(id: String) -> Building:
	for b in root.get_tree().get_nodes_in_group("buildings"):
		if b is Building and b.alive and b.complete and b.team == team_id and b.def_id == id:
			return b
	return null


func _nearest_node(w: Worker) -> CrystalNode:
	var best: CrystalNode = null
	var best_d := INF
	for n in root.get_tree().get_nodes_in_group("gather_nodes"):
		if n is CrystalNode and not n.is_depleted():
			var d: float = n.global_position.distance_squared_to(w.global_position)
			if d < best_d:
				best_d = d
				best = n
	return best


func _guard_point(hq: Building) -> Vector2:
	return hq.position + Vector2(0, 160)


func _enemy_hq_pos() -> Vector2:
	for b in root.get_tree().get_nodes_in_group("buildings"):
		if b is Building and b.alive and b.def_id == "dazhai" and b.team != team_id:
			return b.position
	return Vector2.ZERO


func _place_tent(player: PlayerState, hq: Building) -> void:
	var angles := [0.5, 1.2, 2.0, 2.8, 3.6, 4.4, 5.2]
	for a in angles:
		var pos: Vector2 = hq.position + Vector2(cos(a), sin(a) * 0.7) * randf_range(200.0, 280.0)
		if _spot_free(pos):
			if player.spend(60):
				var tent := Building.new()
				tent.setup("gaizhang", team_id, true)
				tent.position = pos
				root.add_child(tent)
			return


func _spot_free(pos: Vector2) -> bool:
	for b in root.get_tree().get_nodes_in_group("buildings"):
		if b is Building and b.global_position.distance_to(pos) < 110.0:
			return false
	for n in root.get_tree().get_nodes_in_group("gather_nodes"):
		if n is Node2D and n.global_position.distance_to(pos) < 110.0:
			return false
	return true
