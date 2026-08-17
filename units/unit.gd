class_name Unit
extends CharacterBody2D
"""M0 占位单位：NavigationAgent2D 寻路 + 避让，像素小人 + 墨渍影 + 选中环。"""

@export var team := 0
@export var move_speed := 170.0

var selected := false

var _agent: NavigationAgent2D
var _sprite: Sprite2D
var _last_pos := Vector2.INF
var _stuck_frames := 0
var _move_target := Vector2.INF

static var _tex_cache := {}


func _ready() -> void:
	add_to_group("units")
	_sprite = Sprite2D.new()
	var tex: ImageTexture = _tex_cache.get(team)
	if tex == null:
		tex = PixelFigure.make_texture(_team_accent())
		_tex_cache[team] = tex
	_sprite.texture = tex
	_sprite.position = Vector2(0, -16)
	add_child(_sprite)

	_agent = NavigationAgent2D.new()
	_agent.path_desired_distance = 24.0
	_agent.target_desired_distance = 26.0
	_agent.path_postprocessing = 1  # PathPostProcessing.EDGE_CENTERED，边中点路径，远离墙角
	_agent.avoidance_enabled = true
	_agent.radius = 12.0
	_agent.max_speed = move_speed * 1.25  # RVO 避让的速度上限，默认 100 会拖慢行军
	add_child(_agent)
	_agent.velocity_computed.connect(_on_velocity_computed)


func command_move_to(world_pos: Vector2) -> void:
	_move_target = world_pos
	_agent.target_position = world_pos


func is_nav_finished_diag() -> bool:
	return _agent.is_navigation_finished()


func diag_next_path_pos() -> Vector2:
	return _agent.get_next_path_position()


func _physics_process(_delta: float) -> void:
	if _agent.is_navigation_finished():
		velocity = Vector2.ZERO
		_stuck_frames = 0
		return
	var next := _agent.get_next_path_position()
	var desired := (next - global_position).normalized() * move_speed
	_agent.set_velocity(desired)  # 由避让回调 _on_velocity_computed 落地
	_detect_stuck()


func _detect_stuck() -> void:
	"""卡死自愈：未到达却原地不动超过 1 秒，重新下发目标强制重寻路。"""
	if global_position.distance_to(_last_pos) < 0.5:
		_stuck_frames += 1
		if _stuck_frames > 60:
			_stuck_frames = 0
			if _move_target != Vector2.INF:
				_agent.target_position = _move_target
	else:
		_stuck_frames = 0
	_last_pos = global_position


func _on_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	if absf(safe_velocity.x) > 1.0:
		_sprite.flip_h = safe_velocity.x < 0.0
	move_and_slide()


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


func _team_accent() -> Color:
	return Color(0.72, 0.18, 0.14) if team == 0 else Color(0.30, 0.34, 0.42)
