class_name Unit
extends CharacterBody2D
"""单位基类：寻路移动 + 战斗核心（攻击/追击/自仇恨/灼烧/减速/隐身/光环）。"""

@export var team := 0
@export var unit_id := ""
@export var pop := 1
@export var element := "凡"
@export var max_hp := 60.0
@export var base_speed := 170.0
@export var dmg := 0.0
@export var attack_range := 0.0      # 0 = 无战斗力
@export var attack_cd := 1.0
@export var ranged := false
@export var applies_slow := false   # 冰凌射手：命中减速
@export var applies_stun := false   # 地灵师：命中眩晕
@export var siege := false          # 投石机：对建筑伤害翻倍
@export var has_repair_aura := false  # 窑火匠：修缮造物（土/凡）
@export var has_sharp_aura := false  # 玄铁兵魄：增伤光环
@export var can_stealth := false     # 游侠：潜流形态
@export var has_aura := false        # 潮灵：涨潮光环
@export var uses_water_network := false
@export var is_worker := false

var hp := 0.0
var alive := true
var selected := false
var enable_stuck_heal := true  # Worker 等自带状态机的单位关闭
var pop_reserved := false

var attack_target: Node2D = null     # Unit 或 Building（duck-typing）

var burn_time := 0.0
var no_burn_until := 0
var slow_time := 0.0
var stun_time := 0.0
var stealthed := false
var ambush_time := 0.0
var aura_mult := 1.0
var dmg_buff_mult := 1.0  # 玄铁兵魄光环
var _repairing := false   # 窑火匠光环内

var _agent: NavigationAgent2D
var _sprite: Sprite2D
var _move_target := Vector2.INF
var _last_pos := Vector2.INF
var _stuck_frames := 0
var _attack_timer := 0.0
var _scan_timer := 0.0
var _aura_timer := 0.0
const AGGRO_RANGE := 240.0
const AURA_RADIUS := 130.0
const WATER_SPEED_MULT := 1.35
const AMBUSH_TIME := 3.0
const AMBUSH_MULT := 1.25

static var _tex_cache := {}


func _ready() -> void:
	add_to_group("units")
	hp = max_hp
	_sprite = Sprite2D.new()
	var visual_key := unit_id if unit_id != "" else element
	var tex: ImageTexture = _tex_cache.get(visual_key)
	if tex == null:
		tex = PixelFigure.make_texture(Elements.element_color(element), unit_id)
		_tex_cache[visual_key] = tex
	_sprite.texture = tex
	_sprite.position = Vector2(0, -16)
	if unit_id == "juyong":
		_sprite.scale = Vector2(1.35, 1.35)
	elif unit_id == "toushiji":
		_sprite.scale = Vector2(1.2, 1.2)
	add_child(_sprite)

	_agent = NavigationAgent2D.new()
	_agent.path_desired_distance = 24.0
	_agent.target_desired_distance = 26.0
	_agent.path_postprocessing = 1  # PathPostProcessing.EDGE_CENTERED，边中点路径，远离墙角
	_agent.avoidance_enabled = true
	_agent.radius = 12.0
	_agent.max_speed = base_speed * 1.25 * 2.0  # RVO 上限给光环加速留余量
	add_child(_agent)
	_agent.velocity_computed.connect(_on_velocity_computed)
	var player := PlayerState.for_team(self, team)
	if player and not pop_reserved:
		player.register_unit(pop)


# ---- 指令 ----

func command_move_to(world_pos: Vector2) -> void:
	attack_target = null
	_move_target = world_pos
	_agent.target_position = world_pos


func command_attack(t: Node2D) -> void:
	if is_worker or attack_range <= 0.0:
		return
	attack_target = t


func toggle_stealth() -> void:
	if not can_stealth:
		return
	stealthed = not stealthed
	if stealthed:
		ambush_time = 0.0
		attack_target = null
	else:
		ambush_time = AMBUSH_TIME


# ---- 主循环 ----

func _physics_process(delta: float) -> void:
	if not alive:
		return
	# 眩晕：不能移动不能攻击
	if stun_time > 0.0:
		stun_time -= delta
		velocity = Vector2.ZERO
		return
	_update_status(delta)
	var attacking_in_place := _combat_tick(delta)
	if attacking_in_place:
		velocity = Vector2.ZERO
		return
	if _agent.is_navigation_finished():
		velocity = Vector2.ZERO
		return
	var next := _agent.get_next_path_position()
	var desired := (next - global_position).normalized() * base_speed * _speed_mult()
	_agent.set_velocity(desired)  # 由避让回调 _on_velocity_computed 落地
	_detect_stuck()


func _speed_mult() -> float:
	var m := 1.0
	if stealthed:
		m *= 0.5
	if slow_time > 0.0:
		m *= Elements.SLOW_FACTOR
	if uses_water_network and is_in_shallow_water():
		m *= WATER_SPEED_MULT
	if ambush_time > 0.0:
		m *= AMBUSH_MULT
	m *= aura_mult
	return m


func is_in_shallow_water() -> bool:
	for water in get_tree().get_nodes_in_group("shallow_water"):
		if water.has_method("contains_world_point") and water.contains_world_point(global_position):
			return true
	return false


func attack_damage_multiplier() -> float:
	return dmg_buff_mult * (AMBUSH_MULT if ambush_time > 0.0 else 1.0)


func _update_status(delta: float) -> void:
	if burn_time > 0.0:
		burn_time -= delta
		hp -= Elements.BURN_DPS * delta
		if hp <= 0.0:
			_die(null)
			return
	slow_time = maxf(0.0, slow_time - delta)
	ambush_time = maxf(0.0, ambush_time - delta)
	_aura_timer -= delta
	if _aura_timer <= 0.0:
		_aura_timer = 0.6
		var near_tide := false
		var near_sharp := false
		_repairing = false
		for u in get_tree().get_nodes_in_group("units"):
			if not (u is Unit) or not u.alive or u.team != team:
				continue
			if u.has_aura and global_position.distance_to(u.global_position) <= AURA_RADIUS:
				near_tide = true
			if u.has_sharp_aura and global_position.distance_to(u.global_position) <= AURA_RADIUS:
				near_sharp = true
			if u.has_repair_aura and global_position.distance_to(u.global_position) <= AURA_RADIUS:
				_repairing = true
		aura_mult = 1.2 if near_tide else 1.0
		dmg_buff_mult = 1.2 if near_sharp else 1.0
	# 窑火匠修缮：造物（土/凡）光环内缓慢回复
	if _repairing and (element == "土" or element == "凡") and hp < max_hp:
		hp = minf(max_hp, hp + 2.0 * delta)
		queue_redraw()
	# 视觉：灼烧泛红 / 潜流半透明
	if _sprite != null:
		_sprite.modulate = Color(1.0, 0.7, 0.65) if burn_time > 0.0 else Color.WHITE
		_sprite.modulate.a = 0.35 if stealthed else 1.0


func _near_ally_tide_spirit() -> bool:
	for u in get_tree().get_nodes_in_group("units"):
		if u is Unit and u.alive and u.team == team and u.has_aura:
			if global_position.distance_to(u.global_position) <= AURA_RADIUS:
				return true
	return false

# ---- 战斗 ----

func _combat_tick(delta: float) -> bool:
	if is_worker or stealthed or attack_range <= 0.0:
		return false
	# 校验目标
	if attack_target != null and (not is_instance_valid(attack_target) or not _target_ok(attack_target)):
		attack_target = null
	# 自仇恨：闲时每 0.5s 扫最近敌人
	if attack_target == null:
		_scan_timer -= delta
		if _scan_timer <= 0.0:
			_scan_timer = 0.5
			attack_target = _find_enemy()
		if attack_target == null:
			return false
	var dist := global_position.distance_to(attack_target.global_position)
	var reach := attack_range + _target_radius()
	if dist <= reach:
		_agent.target_position = global_position  # 站定
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_attack_timer = attack_cd
			_fire(attack_target)
		if _sprite != null and attack_target is Node2D:
			_sprite.flip_h = attack_target.global_position.x < global_position.x
		return true
	# 追击
	_agent.target_position = attack_target.global_position
	return false


func _target_ok(t: Node2D) -> bool:
	if t is Unit:
		return (t as Unit).alive and (t as Unit).team != team and (team != 0 or t.visible)
	if t is Building:
		return (t as Building).alive and (t as Building).team != team and (team != 0 or t.visible)
	return false


func _target_radius() -> float:
	if attack_target is Building:
		var s: Vector2 = Defs.building((attack_target as Building).def_id)["size"]
		return maxf(s.x, s.y) * 0.5
	return 14.0


func _find_enemy() -> Node2D:
	var best: Node2D = null
	var best_d := AGGRO_RANGE
	for u in get_tree().get_nodes_in_group("units"):
		if u is Unit and u.alive and u.team != team and not u.stealthed and (team != 0 or u.visible):
			var d: float = global_position.distance_to(u.global_position) - 14.0
			if d < best_d:
				best_d = d
				best = u
	if best != null:
		return best
	for b in get_tree().get_nodes_in_group("buildings"):
		if b is Building and b.alive and b.team != team and (team != 0 or b.visible):
			var s: Vector2 = Defs.building(b.def_id)["size"]
			var d: float = global_position.distance_to(b.global_position) - maxf(s.x, s.y) * 0.5
			if d < best_d:
				best_d = d
				best = b
	return best


func _fire(t: Node2D) -> void:
	if ranged:
		var p := Projectile.new()
		p.setup(self, t, dmg)
		get_parent().add_child(p)
		p.position = global_position + Vector2(0, -20)
	else:
		t.take_damage(dmg, self)


func take_damage(amount: float, attacker: Node2D) -> void:
	if not alive:
		return
	var att_elem := "凡"
	var att_buff := 1.0
	if attacker != null and is_instance_valid(attacker) and attacker.get("element") != null:
		att_elem = str(attacker.element)
		att_buff = attacker.attack_damage_multiplier() if attacker is Unit else float(attacker.get("dmg_buff_mult"))
	hp -= amount * att_buff * Elements.multiplier(att_elem, element)
	# 「熄」：水克火，浇灭灼烧并短暂免疫
	if att_elem == "水" and element == "火":
		burn_time = 0.0
		no_burn_until = Time.get_ticks_msec() + Elements.QUENCH_TIME_MS
	# 灼烧：火系攻击附带
	elif att_elem == "火" and element != "凡" and Time.get_ticks_msec() > no_burn_until:
		burn_time = Elements.BURN_TIME
	# 冰凌：命中减速
	if attacker != null and is_instance_valid(attacker) and attacker.get("applies_slow") == true:
		slow_time = Elements.SLOW_TIME
	# 地灵师：命中眩晕
	if attacker != null and is_instance_valid(attacker) and attacker.get("applies_stun") == true:
		stun_time = 1.2
	queue_redraw()
	# 被打反击
	if not is_worker and attack_range > 0.0 and attack_target == null:
		if attacker != null and is_instance_valid(attacker) and attacker is Node2D and _target_ok(attacker):
			attack_target = attacker
	if hp <= 0.0:
		_die(attacker)


func _die(_killer: Node2D) -> void:
	if not alive:
		return
	alive = false
	var s := InkSplat.new()
	s.position = global_position
	get_parent().add_child(s)
	# 万物归尘：场上有皇陵时，阵亡者化尘待收
	for b in get_tree().get_nodes_in_group("buildings"):
		if b is Building and b.alive and b.complete and b.def_id == "huangling":
			var d := Dust.new()
			d.position = global_position
			get_parent().add_child(d)
			break
	var player := PlayerState.for_team(self, team)
	if player:
		player.unregister_unit(pop)
	queue_free()


# ---- 诊断 ----

func is_nav_finished_diag() -> bool:
	return _agent.is_navigation_finished()


func diag_next_path_pos() -> Vector2:
	return _agent.get_next_path_position()


# ---- 移动落地 ----

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	if absf(safe_velocity.x) > 1.0:
		_sprite.flip_h = safe_velocity.x < 0.0
	move_and_slide()


func _detect_stuck() -> void:
	"""卡死自愈：未到达却原地不动超过 1 秒，重新下发目标强制重寻路。"""
	if not enable_stuck_heal:
		return
	if global_position.distance_to(_last_pos) < 0.5:
		_stuck_frames += 1
		if _stuck_frames > 60:
			_stuck_frames = 0
			if _move_target != Vector2.INF:
				_agent.target_position = _move_target
	else:
		_stuck_frames = 0
	_last_pos = global_position


# ---- 视觉 ----

func set_selected(v: bool) -> void:
	selected = v
	queue_redraw()


func _draw() -> void:
	# 墨渍影（脚底椭圆）
	draw_set_transform(Vector2(0, 3), 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 11.0, Color(0.10, 0.09, 0.09, 0.16))
	draw_set_transform(Vector2.ZERO)
	if selected:
		var ring := Color(0.78, 0.23, 0.17) if team == 0 else Color(0.12, 0.12, 0.12)
		draw_arc(Vector2(0, 3), 15.0, 0.0, TAU, 40, ring, 1.6)
	# 血条（受损时显示）
	if hp < max_hp - 0.5:
		var w := 26.0
		draw_rect(Rect2(Vector2(-w * 0.5, -36), Vector2(w, 3)), Color(0.15, 0.14, 0.13, 0.7))
		draw_rect(Rect2(Vector2(-w * 0.5, -36), Vector2(w * clampf(hp / max_hp, 0.0, 1.0), 3)),
			Color(0.78, 0.23, 0.17) if team == 0 else Color(0.25, 0.30, 0.40))
