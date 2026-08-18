class_name PlayerState
extends Node
"""玩家（势力）资源与人口状态。挂在地图根下，按 team 入组。"""

signal crystals_changed(value: int)

var team := 0
var crystals := 200
var pop_used := 0
var pop_cap := 0

const START_CRYSTALS := 200


func setup(team_id: int) -> void:
	team = team_id
	crystals = START_CRYSTALS
	add_to_group("player_%d" % team_id)


static func for_team(root: Node, team_id: int) -> PlayerState:
	for n in root.get_tree().get_nodes_in_group("player_%d" % team_id):
		return n
	return null


func can_spend(amount: int) -> bool:
	return crystals >= amount


func spend(amount: int) -> bool:
	if not can_spend(amount):
		return false
	crystals -= amount
	crystals_changed.emit(crystals)
	return true


func add_crystals(amount: int) -> void:
	crystals += amount
	crystals_changed.emit(crystals)


func add_pop_cap(amount: int) -> void:
	pop_cap += amount


func register_unit(pop: int) -> void:
	pop_used += pop


func unregister_unit(pop: int) -> void:
	pop_used = maxf(0, pop_used - pop)
