class_name VictoryManager
extends Node
"""胜负判定：任一方大寨被摧毁即结算。"""

signal game_over(player_won: bool)

var root: Node2D
var _timer := 0.0
var _ended := false
var _start_ms := 0


func setup(map_root: Node2D) -> void:
	root = map_root
	_start_ms = Time.get_ticks_msec()


func _process(delta: float) -> void:
	if _ended:
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer = 1.0
		_check()


func _check() -> void:
	var hq_player := _find_hq(0)
	var hq_enemy := _find_hq(1)
	var player_lost := hq_player == null or not hq_player.alive
	var enemy_lost := hq_enemy == null or not hq_enemy.alive
	if not (player_lost or enemy_lost):
		return
	_ended = true
	var won: bool = enemy_lost and not player_lost
	var elapsed := float(Time.get_ticks_msec() - _start_ms) / 1000.0
	print("[胜负] %s（用时 %.0f 秒）" % ["玩家胜利" if won else "玩家败北", elapsed])
	game_over.emit(won)
	EndScreen.show_screen(root, won, elapsed)
	get_tree().paused = true


func _find_hq(t: int) -> Building:
	for b in root.get_tree().get_nodes_in_group("buildings"):
		if b is Building and b.team == t and b.def_id == "dazhai" and b.alive:
			return b
	return null
