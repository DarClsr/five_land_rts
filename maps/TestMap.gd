extends Node2D
"""M0 测试地图：宣纸底 + 墨岩/水域障碍 + 12 己方单位 + 4 敌方装饰单位 + 相机/HUD/小地图/框选。"""

const MAP := Rect2(-1600, -900, 3200, 1800)

var _obstacles: Array[PackedVector2Array] = []


func _ready() -> void:
	y_sort_enabled = true  # 2.5D: 按脚底 Y 排序遮挡
	_build_paper()
	_build_terrain()
	_build_navigation()
	var cam := _build_camera()
	_build_units()
	_build_fog()
	_build_hud_and_selection(cam)
	_build_minimap(cam)


func _build_paper() -> void:
	var paper := ColorRect.new()
	paper.position = MAP.position
	paper.size = MAP.size
	paper.z_index = -100
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sm := ShaderMaterial.new()
	sm.shader = load("res://art/shaders/paper.gdshader")
	paper.material = sm
	add_child(paper)


func _build_terrain() -> void:
	var rock_specs := [
		[Vector2(-260, -190), Vector2(320, 220), 3],
		[Vector2(400, 420), Vector2(260, 300), 5],
		[Vector2(850, -580), Vector2(300, 240), 8],
	]
	for spec in rock_specs:
		var rock := InkRock.new()
		rock.position = spec[0]
		rock.size = spec[1]
		rock.rock_seed = spec[2]
		add_child(rock)
		_obstacles.append(rock.obstruction_corners())

	var pond := WaterPond.new()
	pond.position = Vector2(-350, 620)
	pond.size = Vector2(560, 280)
	add_child(pond)
	_obstacles.append(pond.obstruction_corners())


func _build_navigation() -> void:
	var region := NavigationRegion2D.new()
	add_child(region)

	var inset := 60.0
	var trav := PackedVector2Array([
		MAP.position + Vector2(inset, inset),
		Vector2(MAP.end.x - inset, MAP.position.y + inset),
		MAP.end - Vector2(inset, inset),
		Vector2(MAP.position.x + inset, MAP.end.y - inset),
	])
	var np := NavigationPolygon.new()
	var source := NavigationMeshSourceGeometryData2D.new()
	source.add_traversable_outline(trav)
	for outline in _obstacles:
		source.add_obstruction_outline(outline)
	NavigationServer2D.bake_from_source_geometry_data(np, source)
	region.navigation_polygon = np


func _build_camera() -> RTTSCamera:
	var cam := RTTSCamera.new()
	cam.map_rect = MAP
	add_child(cam)
	return cam


func _build_units() -> void:
	for i in 12:
		var u := Unit.new()
		u.team = 0
		u.position = Vector2(-1300.0 + float(i % 4) * 44.0, 620.0 + float(i / 4) * 44.0)
		add_child(u)
	for i in 4:
		var e := Unit.new()
		e.team = 1
		e.position = Vector2(1250.0 + float(i) * 50.0, -620.0)
		add_child(e)


func _build_fog() -> void:
	var fog := FogOfWar.new()
	fog.setup(MAP)
	add_child(fog)


func _build_hud_and_selection(cam: RTTSCamera) -> void:
	var hud := BasicHUD.new()
	add_child(hud)
	var sel := SelectionManager.new()
	sel.setup(cam)
	sel.hud = hud
	add_child(sel)
	hud.setup(sel, cam)


func _build_minimap(cam: RTTSCamera) -> void:
	var mm := Minimap.new()
	mm.setup(cam, MAP, self)
	add_child(mm)
