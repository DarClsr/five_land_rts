extends Node2D
"""M1 对战地图：离国 vs 朔国，验证经济、争夺、AI 与胜负闭环。"""

const MAP := Rect2(-1600, -900, 3200, 1800)

var _obstacles: Array[PackedVector2Array] = []


func _ready() -> void:
	y_sort_enabled = true  # 2.5D: 按脚底 Y 排序遮挡
	_build_paper()
	_build_terrain()
	_build_navigation()
	var cam := _build_camera()
	var player := _build_player_and_bases()
	_build_units()
	_build_fog()
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
	var inset := 60.0
	var trav := PackedVector2Array([
		MAP.position + Vector2(inset, inset),
		Vector2(MAP.end.x - inset, MAP.position.y + inset),
		MAP.end - Vector2(inset, inset),
		Vector2(MAP.position.x + inset, MAP.end.y - inset),
	])
	var registry := NavRegistry.new()
	registry.setup(self, trav, _obstacles)
	add_child(registry)


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

	# 离国大寨
	var hq := Building.new()
	hq.setup("dazhai", 0, true)
	hq.position = Vector2(-1050, 350)
	add_child(hq)

	# 朔国基地：坞堡 + 影卫堂 + 篝帐（AI 接管运营）
	var player1 := PlayerState.new()
	player1.setup(1, "shuo")
	player1.crystals = 300  # 补偿无微操
	add_child(player1)

	var ehq := Building.new()
	ehq.setup("wubao", 1, true)
	ehq.position = Vector2(1100, -450)
	add_child(ehq)

	var ebar := Building.new()
	ebar.setup("yingweitang", 1, true)
	ebar.position = Vector2(1260, -430)
	add_child(ebar)

	var etent := Building.new()
	etent.setup("gaizhang", 1, true)
	etent.position = Vector2(1030, -540)
	add_child(etent)

	# 双方各2处安全矿、2处侧翼扩张矿、1处中央富灵脉
	for spec in [
		[Vector2(-1300, 120), false], [Vector2(-1080, 700), false],
		[Vector2(1300, -120), false], [Vector2(1080, -700), false],
		[Vector2(-1120, -560), false], [Vector2(1120, 560), false],
		[Vector2(180, 80), true],
	]:
		var node := CrystalNode.new()
		node.setup(spec[1])
		node.position = spec[0]
		add_child(node)

	# AI 与胜负
	var ai := EnemyAI.new()
	ai.setup(1, self)
	ai.hq_id = "wubao"
	ai.worker_id = "mijian"
	ai.barracks_id = "yingweitang"
	add_child(ai)

	var victory := VictoryManager.new()
	victory.setup(self)
	add_child(victory)
	return player


func _build_units() -> void:
	for i in 5:
		var w := Defs.spawn("yanmin", 0)
		w.position = Vector2(-1020 + float(i) * 55.0, 500 + float(i) * 26.0)
		add_child(w)
	# 朔国 AI 民夫（密探，AI 会派去采矿并补足到 5）
	for i in 3:
		var w1 := Defs.spawn("mijian", 1)
		w1.position = Vector2(1150 + float(i) * 50.0, -370)
		add_child(w1)
	# 朔国仅留 2 游侠看家，进攻部队由 AI 自产（首波不再碾压玩家）
	for pos in [Vector2(1060, -360), Vector2(1130, -330)]:
		var g := Defs.spawn("youxia", 1)
		g.position = pos
		add_child(g)


func _build_fog() -> void:
	var fog := FogOfWar.new()
	fog.setup(MAP)
	add_child(fog)


func _build_hud_and_selection(cam: RTTSCamera, player: PlayerState) -> void:
	var hud := BasicHUD.new()
	hud.tips_text = "M1：右键敌人=攻击 | 焰阵造兵 | 家里造烽燧防守(80灵晶) | 水克火·冰凌减速 | 火拆建筑返灵晶"
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
