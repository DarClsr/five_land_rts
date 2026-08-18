extends Node2D
"""M1 对战地图：离国基地（大寨+3炎民+双灵脉矿） vs 朔国基地（占位）。经济冲刺验证场。"""

const MAP := Rect2(-1600, -900, 3200, 1800)

var _obstacles: Array[PackedVector2Array] = []


func _ready() -> void:
	_build_paper()
	_build_terrain()
	_build_navigation()
	var cam := _build_camera()
	var player := _build_player_and_bases()
	_build_units()
	_build_hud_and_selection(cam, player)
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
		[Vector2(-150, -150), Vector2(320, 220), 3],
		[Vector2(350, 580), Vector2(520, 280), 6],
		[Vector2(820, -720), Vector2(300, 240), 8],
	]
	for spec in rock_specs:
		var rock := InkRock.new()
		rock.position = spec[0]
		rock.size = spec[1]
		rock.rock_seed = spec[2]
		add_child(rock)
		_obstacles.append(rock.obstruction_corners())


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
	cam.position = Vector2(-900, 300)  # 开局镜头对准离国基地
	add_child(cam)
	return cam


func _build_player_and_bases() -> PlayerState:
	var player := PlayerState.new()
	player.setup(0)
	add_child(player)

	# 离国大寨 + 双灵脉矿
	var hq := Building.new()
	hq.setup("dazhai", 0, true)
	hq.position = Vector2(-1050, 350)
	add_child(hq)

	for pos in [Vector2(-1300, 120), Vector2(-780, 620)]:
		var node := CrystalNode.new()
		node.position = pos
		add_child(node)

	# 朔国基地（占位，M1-2 补战斗）
	var ehq := Building.new()
	ehq.setup("dazhai", 1, true)
	ehq.position = Vector2(1100, -450)
	add_child(ehq)

	var enode := CrystalNode.new()
	enode.position = Vector2(1350, -150)
	add_child(enode)
	return player


func _build_units() -> void:
	for i in 3:
		var w := Worker.new()
		w.team = 0
		w.position = Vector2(-1020 + float(i) * 55.0, 500 + float(i) * 30.0)
		add_child(w)
	for i in 4:
		var e := Unit.new()
		e.team = 1
		e.position = Vector2(980 + float(i) * 55.0, -380)
		add_child(e)


func _build_hud_and_selection(cam: RTTSCamera, player: PlayerState) -> void:
	var hud := BasicHUD.new()
	hud.tips_text = "M1 经济：选大寨→训练炎民 | 选炎民→底部建造 | 右键矿脉采集 / 工地施工 | WASD平移 滚轮缩放"
	add_child(hud)
	var sel := SelectionManager.new()
	sel.setup(cam)
	sel.hud = hud
	add_child(sel)
	hud.setup(sel, cam)

	var bar := BuildBar.new()
	bar.setup(cam, self, sel, player)
	add_child(bar)


func _build_minimap(cam: RTTSCamera) -> void:
	var mm := Minimap.new()
	mm.setup(cam, MAP, self)
	add_child(mm)
