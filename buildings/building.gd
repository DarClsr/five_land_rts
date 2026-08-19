class_name Building
extends Node2D
"""建筑基类：施工进度、血量、水墨绘制、人口供给、生产队列。"""

var def_id := ""
var team := 0
var hp := 1.0
var max_hp := 1.0
var complete := false  # 施工完成才生效
var alive := true

var _queue: Array[String] = []  # 待训练单位 id
var _train_progress := 0.0
var _selected := false
var _tower_timer := 0.0
var _nav_id := -1              # 坊墙的导航阻挡句柄
var _self_construct := false   # 迁制：自重建中

const TOWER_RANGE := 230.0
const TOWER_DMG := 12.0


func setup(id: String, team_id: int, start_complete: bool) -> void:
	def_id = id
	team = team_id
	var def: Dictionary = Defs.building(id)
	max_hp = float(def.get("hp", 100))
	hp = max_hp if start_complete else max_hp * 0.1
	complete = start_complete


func _ready() -> void:
	add_to_group("buildings")
	if complete:
		_apply_online_effects()
	# 坊墙：注册导航阻挡，销毁时移除（运行时重烘焙，亚毫秒级）
	if Defs.building(def_id).get("wall", false):
		var half: Vector2 = Defs.building(def_id)["size"] * 0.5
		var outline := PackedVector2Array([
			to_global(Vector2(-half.x, -half.y)), to_global(Vector2(half.x, -half.y)),
			to_global(Vector2(half.x, half.y)), to_global(Vector2(-half.x, half.y))])
		var registry := NavRegistry.for_tree(self)
		if registry != null:
			_nav_id = registry.add_obstruction(outline)
		tree_exiting.connect(_remove_nav_obstruction)
	queue_redraw()


func _remove_nav_obstruction() -> void:
	if _nav_id >= 0:
		var r := NavRegistry.for_tree(self)
		if r != null:
			r.remove_obstruction(_nav_id)


func _apply_online_effects() -> void:
	var def: Dictionary = Defs.building(def_id)
	var player := PlayerState.for_team(self, team)
	if player and def.get("pop_cap", 0) > 0:
		player.add_pop_cap(int(def["pop_cap"]))


func _process(delta: float) -> void:
	if complete and not _queue.is_empty():
		_train_progress += delta
		var def: Dictionary = Defs.building(def_id)
		var unit_time: float = Defs.unit(_queue[0]).get("build_time", 10.0)
		if _train_progress >= unit_time:
			_train_progress = 0.0
			_spawn_trained(_queue.pop_front())
	if complete and Defs.building(def_id).get("tower", false):
		_tower_tick(delta)
	# 迁制：自重建（无需民夫）
	if _self_construct and not complete:
		add_build_progress(delta / float(Defs.building(def_id)["build_time"]) * 0.6)


func _tower_tick(delta: float) -> void:
	"""烽燧：每 1.5 秒射击射程内最近敌单位（凡品攻击，不吃克制）。"""
	_tower_timer -= delta
	if _tower_timer > 0.0:
		return
	_tower_timer = 1.5
	for u in get_tree().get_nodes_in_group("units"):
		if u is Unit and u.alive and u.team != team:
			if global_position.distance_to(u.global_position) <= TOWER_RANGE:
				var p := Projectile.new()
				p.setup(self, u, TOWER_DMG)
				get_parent().add_child(p)
				p.position = global_position + Vector2(0, -28)
				return


func add_build_progress(fraction: float) -> void:
	"""民夫施工：fraction = dt / build_time。"""
	if complete:
		return
	var def: Dictionary = Defs.building(def_id)
	hp = minf(hp + max_hp * 0.9 * fraction, max_hp)
	if hp >= max_hp * 0.999:
		hp = max_hp
		complete = true
		_apply_online_effects()
	queue_redraw()


func enqueue(unit_id: String) -> bool:
	if not complete:
		return false
	var def: Dictionary = Defs.building(def_id)
	if unit_id not in def.get("trains", []):
		return false
	var player := PlayerState.for_team(self, team)
	var udef: Dictionary = Defs.unit(unit_id)
	if player == null or not player.can_spend(int(udef["cost"])):
		return false
	if player.pop_used + int(udef.get("pop", 1)) > player.pop_cap:
		return false
	player.spend(int(udef["cost"]))
	player.register_unit(int(udef.get("pop", 1)))
	_queue.append(unit_id)
	return true


func queue_size() -> int:
	return _queue.size()


func set_selected(v: bool) -> void:
	_selected = v
	queue_redraw()


func is_dropoff() -> bool:
	return Defs.building(def_id).get("dropoff", false)


# ---- 皇陵能力：万物归尘 ----

func run_ability(ability_id: String) -> String:
	match ability_id:
		"dust_summon":
			return _dust_summon()
		"dust_crystal":
			return _dust_crystal()
	return "未知能力"


func _collect_dust() -> Array:
	var dusts: Array = []
	for d in get_tree().get_nodes_in_group("dust"):
		if d is Dust and is_instance_valid(d) and not d.is_queued_for_deletion():
			dusts.append(d)
	return dusts


func _dust_summon() -> String:
	var dusts := _collect_dust()
	if dusts.size() < 2:
		return "尘不足（2 尘唤 1 俑）"
	var player := PlayerState.for_team(self, team)
	var spawned := 0
	var i := 0
	while i + 1 < dusts.size():
		if player != null and player.pop_used + 1 > player.pop_cap:
			break
		(dusts[i] as Dust).queue_free()
		(dusts[i + 1] as Dust).queue_free()
		var puppet := Defs.spawn("taoyongzu", team)
		puppet.position = position + Vector2(randf_range(-60, 60), Defs.building(def_id)["size"].y * 0.5 + 30.0)
		get_parent().add_child(puppet)
		spawned += 1
		i += 2
	return "归尘唤俑 ×%d" % spawned


func _dust_crystal() -> String:
	var dusts := _collect_dust()
	if dusts.is_empty():
		return "尘不足"
	var player := PlayerState.for_team(self, team)
	if player != null:
		player.add_crystals(dusts.size() * 4)
	for d in dusts:
		(d as Dust).queue_free()
	return "归尘炼晶 +%d" % (dusts.size() * 4)


# ---- 迁制 ----

func start_migrate(pos: Vector2) -> void:
	"""打包迁往新址，落位后自重建（免民夫，耗时 60%）。"""
	position = pos
	complete = false
	_self_construct = true
	hp = max_hp * 0.5
	queue_redraw()


func _spawn_trained(unit_id: String) -> void:
	var u := Defs.spawn(unit_id, team)
	var udef: Dictionary = Defs.unit(unit_id)
	u.pop = int(udef.get("pop", 1))
	u.pop_reserved = true  # enqueue 时已预占人口
	var side: Vector2 = Vector2(0, Defs.building(def_id)["size"].y * 0.5 + 40.0)
	u.position = position + side
	get_parent().add_child(u)
	u.command_move_to(position + side + Vector2(0, 80))


func take_damage(amount: float, attacker: Node2D) -> void:
	"""建筑为凡品，不吃五行克制；投石机（siege）对建筑伤害翻倍。"""
	if not alive:
		return
	var mult := 1.0
	if attacker != null and is_instance_valid(attacker) and bool(attacker.get("siege")):
		mult = 2.0
	hp -= amount * mult
	queue_redraw()
	if hp <= 0.0:
		_die(attacker)


func _die(attacker: Node2D) -> void:
	alive = false
	var s := InkSplat.new()
	s.position = position
	s.splat_size = 60.0
	get_parent().add_child(s)
	# 燎原：火系摧毁敌方建筑，返还 30% 造价
	if attacker != null and is_instance_valid(attacker) and str(attacker.get("element")) == "火":
		var player := PlayerState.for_team(self, int(attacker.get("team")))
		if player:
			var refund := int(Defs.building(def_id).get("cost", 0) * 0.3)
			if refund > 0:
				player.add_crystals(refund)
	queue_free()


func _draw() -> void:
	var def: Dictionary = Defs.building(def_id)
	var size: Vector2 = def["size"]
	var half := size * 0.5
	var alpha := 1.0 if complete else 0.45
	# 施工中画半透明轮廓
	draw_rect(Rect2(-half, size), Color(0.25, 0.23, 0.21, alpha))
	# 竹木结构：墨墙 + 浅顶
	draw_rect(Rect2(-half + Vector2(4, 4), size - Vector2(8, size.y * 0.35)), Color(0.16, 0.15, 0.14, alpha))
	draw_rect(Rect2(-half + Vector2(4, 4), Vector2(size.x - 8, size.y * 0.28)), Color(0.55, 0.52, 0.47, alpha))
	# 依建筑类型点睛
	match def_id:
		"dazhai":
			draw_rect(Rect2(-10, -half.y + 6, 20, 30), Color(0.72, 0.18, 0.14, alpha))  # 赤旗
			draw_line(Vector2(0, -half.y + 6), Vector2(0, -half.y - 22), Color(0.1, 0.1, 0.1, alpha), 2.0)
		"wubao":
			draw_rect(Rect2(-10, -half.y + 6, 20, 30), Color(0.25, 0.32, 0.45, alpha))  # 玄旗
			draw_line(Vector2(0, -half.y + 6), Vector2(0, -half.y - 22), Color(0.1, 0.1, 0.1, alpha), 2.0)
		"yashu":
			draw_rect(Rect2(-10, -half.y + 6, 20, 30), Color(0.72, 0.58, 0.22, alpha))  # 明黄旗
			draw_line(Vector2(0, -half.y + 6), Vector2(0, -half.y - 22), Color(0.1, 0.1, 0.1, alpha), 2.0)
		"gaizhang", "fangshi":
			draw_colored_polygon(
				PackedVector2Array([Vector2(-half.x + 6, half.y - 4), Vector2(0, -half.y + 8), Vector2(half.x - 6, half.y - 4)]),
				Color(0.45, 0.42, 0.38, alpha))
		"yanzhen":
			draw_rect(Rect2(-8, -half.y + 10, 16, 20), Color(0.72, 0.18, 0.14, alpha))  # 焰字旗位
		"yingweitang":
			draw_rect(Rect2(-8, -half.y + 10, 16, 20), Color(0.25, 0.32, 0.45, alpha))  # 玄旗
		"fubingying":
			draw_rect(Rect2(-8, -half.y + 10, 16, 20), Color(0.60, 0.50, 0.30, alpha))  # 土黄旗
		"huangling":
			# 陵冢：封土堆 + 幽光
			draw_colored_polygon(
				PackedVector2Array([Vector2(-half.x + 4, half.y - 4), Vector2(0, -half.y + 10), Vector2(half.x - 4, half.y - 4)]),
				Color(0.30, 0.27, 0.24, alpha))
			draw_circle(Vector2(0, -half.y + 8), 4.5, Color(0.55, 0.75, 0.65, alpha))  # 龙脉幽光
		"yaojian":
			draw_circle(Vector2(half.x - 14, half.y - 14), 7.0, Color(0.72, 0.30, 0.14, alpha))  # 窑口火光
		"junqijian":
			draw_line(Vector2(-14, 6), Vector2(14, -8), Color(0.75, 0.75, 0.72, alpha), 2.5)  # 交叉剑械
			draw_line(Vector2(14, 6), Vector2(-14, -8), Color(0.75, 0.75, 0.72, alpha), 2.5)
		"fengsui", "gulou":
			draw_rect(Rect2(-half + Vector2(10, 6), Vector2(size.x - 20, 8)), Color(0.6, 0.57, 0.52, alpha))
			var beacon := Color(0.72, 0.18, 0.14, alpha) if def_id == "fengsui" else Color(0.60, 0.50, 0.30, alpha)
			draw_circle(Vector2(0, -half.y + 6), 5.0, beacon)
		"fangqiu":
			draw_rect(Rect2(-half + Vector2(3, 3), size - Vector2(6, 6)), Color(0.32, 0.29, 0.25, alpha))  # 夯土墙芯
			draw_rect(Rect2(-half + Vector2(3, 3), Vector2(size.x - 6, 5)), Color(0.5, 0.46, 0.4, alpha))
	# 施工进度条
	if not complete:
		var w := size.x * 0.8
		draw_rect(Rect2(Vector2(-w * 0.5, -half.y - 12), Vector2(w, 5)), Color(0.2, 0.19, 0.18, 0.5))
		draw_rect(Rect2(Vector2(-w * 0.5, -half.y - 12), Vector2(w * hp / max_hp, 5)), Color(0.72, 0.18, 0.14))
	# 选中环
	if _selected:
		draw_arc(Vector2.ZERO, maxf(half.x, half.y) + 12.0, 0.0, TAU, 40, Color(0.78, 0.23, 0.17), 1.6)
	# 生产队列指示
	if complete and not _queue.is_empty():
		var udef: Dictionary = Defs.unit(_queue[0])
		var frac := _train_progress / float(udef.get("build_time", 10.0))
		draw_rect(Rect2(Vector2(-size.x * 0.4, -half.y - 12), Vector2(size.x * 0.8 * frac, 4)), Color(0.30, 0.34, 0.42))
