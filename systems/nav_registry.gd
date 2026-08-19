class_name NavRegistry
extends Node
"""地图级导航注册器：静态轮廓 + 动态阻挡（坊墙等），变更即重烘焙（亚毫秒级，spike 已验证）。"""

var _region: NavigationRegion2D
var _traversable: PackedVector2Array = PackedVector2Array()
var _static_obstacles: Array[PackedVector2Array] = []
var _dynamic := {}  # id -> PackedVector2Array
var _next_id := 1


func setup(map_root: Node2D, traversable: PackedVector2Array, obstacles: Array) -> void:
	_traversable = traversable
	for o in obstacles:
		_static_obstacles.append(o)
	_region = NavigationRegion2D.new()
	map_root.add_child(_region)
	add_to_group("nav_registry")
	_rebake()


static func for_tree(node: Node) -> NavRegistry:
	var n: Node = node.get_tree().get_first_node_in_group("nav_registry")
	return n as NavRegistry if n is NavRegistry else null


func add_obstruction(outline: PackedVector2Array) -> int:
	var id := _next_id
	_next_id += 1
	_dynamic[id] = outline
	_rebake()
	return id


func remove_obstruction(id: int) -> void:
	if _dynamic.erase(id):
		_rebake()


func _rebake() -> void:
	if _region == null:
		return
	var np := NavigationPolygon.new()
	var src := NavigationMeshSourceGeometryData2D.new()
	src.add_traversable_outline(_traversable)
	for o in _static_obstacles:
		src.add_obstruction_outline(o)
	for o in _dynamic.values():
		src.add_obstruction_outline(o)
	NavigationServer2D.bake_from_source_geometry_data(np, src)
	_region.navigation_polygon = np
