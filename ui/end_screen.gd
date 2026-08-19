class_name EndScreen
extends CanvasLayer
"""结算画面：墨色遮罩 + 大捷/败北 + 用时 + 再来一局/退出。"""

static func show_screen(map_root: Node2D, won: bool, elapsed: float) -> void:
	var tree := map_root.get_tree()
	var s := EndScreen.new()
	s.layer = 50
	s.process_mode = Node.PROCESS_MODE_ALWAYS
	tree.root.add_child(s)
	s._build(won, elapsed, map_root)


func _build(won: bool, elapsed: float, map_root: Node2D) -> void:
	add_to_group("end_screen")
	var player := PlayerState.for_team(map_root, 0)
	var faction_id := player.faction if player != null else "li"
	var faction_def: Dictionary = Defs.faction(faction_id)
	var veil := ColorRect.new()
	veil.color = Color(0.07, 0.06, 0.06, 0.78)
	# CanvasLayer 内 Control 使用屏幕坐标
	veil.position = Vector2.ZERO
	veil.size = Vector2(1920, 1080)
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(veil)

	var title := Label.new()
	title.text = "大捷" if won else "败北"
	title.add_theme_font_size_override("font_size", 120)
	title.add_theme_color_override("font_color", faction_def["color"] if won else Color(0.13, 0.12, 0.12))
	title.position = Vector2(760, 260)
	title.size = Vector2(400, 160)
	add_child(title)

	var sub := Label.new()
	sub.text = "%s旌旗蔽野 · 用时 %d 分 %d 秒" % [faction_def["name"], int(elapsed) / 60, int(elapsed) % 60]
	sub.add_theme_font_size_override("font_size", 26)
	sub.add_theme_color_override("font_color", Color(0.85, 0.82, 0.76))
	sub.position = Vector2(660, 460)
	sub.size = Vector2(600, 40)
	add_child(sub)

	var again := Button.new()
	again.text = "再来一局"
	again.position = Vector2(770, 580)
	again.custom_minimum_size = Vector2(160, 48)
	again.pressed.connect(func() -> void:
		get_tree().paused = false
		get_tree().reload_current_scene())
	add_child(again)

	var quit := Button.new()
	quit.text = "退出"
	quit.position = Vector2(990, 580)
	quit.custom_minimum_size = Vector2(160, 48)
	quit.pressed.connect(func() -> void:
		get_tree().quit())
	add_child(quit)
