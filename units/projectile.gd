class_name Projectile
extends Node2D
"""远程弹道：追踪目标，命中结算伤害（克制与状态在 take_damage 内处理）。"""

var attacker: Node2D
var target: Node2D
var base_dmg := 0.0
var speed := 420.0

var _ttl := 3.0
var _color := Color(0.2, 0.2, 0.2)


func setup(a: Node2D, t: Node2D, dmg: float) -> void:
	attacker = a
	target = t
	base_dmg = dmg
	var elem := "凡"
	if a != null and a.get("element") != null:
		elem = a.element
	_color = Elements.element_color(elem)


func _process(delta: float) -> void:
	_ttl -= delta
	if _ttl <= 0.0 or not is_instance_valid(target) or not _target_alive():
		queue_free()
		return
	var aim: Vector2 = target.global_position + Vector2(0, -14)
	var dir := aim - global_position
	if dir.length() < 14.0:
		var att := attacker if is_instance_valid(attacker) else null
		target.take_damage(base_dmg, att)
		queue_free()
		return
	position += dir.normalized() * speed * delta
	rotation = dir.angle()
	queue_redraw()


func _target_alive() -> bool:
	var v = target.get("alive")
	return v == null or bool(v)


func _draw() -> void:
	draw_line(Vector2(-7, 0), Vector2(7, 0), _color, 2.0)
	draw_circle(Vector2(7, 0), 2.0, _color)
