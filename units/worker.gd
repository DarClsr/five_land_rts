class_name Worker
extends Unit
"""民夫：采集灵晶（矿→大寨往返）与建筑施工。"""

enum State { IDLE, TO_MINE, MINING, TO_DEPOSIT, TO_BUILD, BUILDING }

var state := State.IDLE
var carry := 0

var _node: CrystalNode
var _site: Building
var _hq: Building
var _timer := 0.0
var _deposit_target := Vector2.INF


func _ready() -> void:
	super()
	move_speed = float(Defs.unit("yanmin")["speed"])
	enable_stuck_heal = false  # 状态机自行驱动目标，交给自愈反而添乱


func command_gather(node: CrystalNode) -> void:
	_site = null
	_node = node
	_hq = _find_hq()
	_enter_to_mine()


func command_build(site: Building) -> void:
	_node = null
	_site = site
	state = State.TO_BUILD
	_move_to_point(site.position + _offset_from(site.position))


func command_move_to(world_pos: Vector2) -> void:
	_node = null
	_site = null
	_hq = null
	state = State.IDLE
	super(world_pos)


func _physics_process(delta: float) -> void:
	super(delta)
	match state:
		State.TO_MINE:
			if _node == null or _node.is_depleted():
				_retarget_node_or_idle()
			elif _near(_node.position, CrystalNode.APPROACH_DIST + 24.0):
				state = State.MINING
				_timer = CrystalNode.MINE_TIME
		State.MINING:
			if _node == null or _node.is_depleted():
				_retarget_node_or_idle()
				return
			_timer -= delta
			if _timer <= 0.0:
				carry = _node.take(CrystalNode.CARRY_PER_TRIP)
				queue_redraw()
				if carry <= 0:
					_retarget_node_or_idle()
				else:
					_hq = _find_hq()
					if _hq == null:
						state = State.IDLE
						return
					state = State.TO_DEPOSIT
					_deposit_target = _hq.position + (global_position - _hq.position).normalized() * 80.0
					_move_to_point(_deposit_target)
		State.TO_DEPOSIT:
			if _hq == null:
				state = State.IDLE
				return
			if _near(_hq.position, 130.0):
				var player := PlayerState.for_team(self, team)
				if player:
					player.add_crystals(carry)
				carry = 0
				queue_redraw()
				if _node != null and not _node.is_depleted():
					_enter_to_mine()
				else:
					_retarget_node_or_idle()
		State.TO_BUILD:
			if _site == null or _site.complete:
				state = State.IDLE
			elif _near(_site.position, 70.0):
				state = State.BUILDING
		State.BUILDING:
			if _site == null or _site.complete:
				state = State.IDLE
			else:
				_site.add_build_progress(delta / float(Defs.building(_site.def_id)["build_time"]))
				if _site.complete:
					state = State.IDLE


func _enter_to_mine() -> void:
	if _node == null or _node.is_depleted():
		_retarget_node_or_idle()
		return
	state = State.TO_MINE
	_move_to_point(_node.position + _offset_from(_node.position))


func _retarget_node_or_idle() -> void:
	var nearest := _find_nearest_node()
	if nearest != null:
		_node = nearest
		_enter_to_mine()
	else:
		state = State.IDLE
		_node = null


func _find_nearest_node() -> CrystalNode:
	var best: CrystalNode = null
	var best_d := INF
	for n in get_tree().get_nodes_in_group("gather_nodes"):
		if n is CrystalNode and not n.is_depleted():
			var d: float = n.global_position.distance_squared_to(global_position)
			if d < best_d:
				best_d = d
				best = n
	return best


func _find_hq() -> Building:
	var best: Building = null
	var best_d := INF
	for b in get_tree().get_nodes_in_group("buildings"):
		if b is Building and b.team == team and b.complete and b.is_dropoff():
			var d: float = b.global_position.distance_squared_to(global_position)
			if d < best_d:
				best_d = d
				best = b
	return best


func _move_to_point(p: Vector2) -> void:
	_agent.target_position = p


func _offset_from(center: Vector2) -> Vector2:
	return (global_position - center).normalized() * CrystalNode.APPROACH_DIST * 0.9


func _near(p: Vector2, dist: float) -> bool:
	return global_position.distance_to(p) <= dist


func _draw() -> void:
	super()
	if carry > 0:
		draw_circle(Vector2(0, -38), 4.0, Color(0.42, 0.47, 0.55))
