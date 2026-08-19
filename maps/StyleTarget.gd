extends Node2D
"""M0 风格定妆照：宣纸底 · 三层水墨远山 · 像素小人 · 飞白剑气 · 朱砂点睛。一屏锁定视觉基准。"""


func _ready() -> void:
	var paper := ColorRect.new()
	paper.position = Vector2(-960, -540)
	paper.size = Vector2(1920, 1080)
	paper.z_index = -100
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sm := ShaderMaterial.new()
	sm.shader = load("res://art/shaders/paper.gdshader")
	paper.material = sm
	add_child(paper)

	var mountains := InkMountains.new()
	mountains.width = 2600.0
	mountains.base_y = 60.0
	mountains.layers = 3
	mountains.ink_seed = 11
	add_child(mountains)

	# 飞白剑气（斜贯画面）
	var slash := ColorRect.new()
	slash.position = Vector2(-620, -300)
	slash.size = Vector2(1240, 620)
	slash.rotation_degrees = -4.0
	slash.z_index = 5
	slash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var slash_mat := ShaderMaterial.new()
	slash_mat.shader = load("res://art/shaders/brush_slash.gdshader")
	slash.material = slash_mat
	add_child(slash)

	# 像素小人（朱砂腰带，放大 4 倍）
	var shadow := ShadowDot.new()
	shadow.position = Vector2(180, 372)
	add_child(shadow)
	var hero := Sprite2D.new()
	hero.texture = PixelFigure.make_texture(Color(0.72, 0.18, 0.14))
	hero.position = Vector2(180, 360)
	hero.scale = Vector2(4, 4)
	hero.z_index = 6
	add_child(hero)

	# 朱砂印章
	var seal := ColorRect.new()
	seal.position = Vector2(830, 424)
	seal.size = Vector2(58, 58)
	seal.color = Color(0.72, 0.18, 0.14)
	seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(seal)
	var seal_text := Label.new()
	seal_text.text = "三国"
	seal_text.position = Vector2(834, 438)
	seal_text.add_theme_font_size_override("font_size", 20)
	seal_text.add_theme_color_override("font_color", Color(0.94, 0.90, 0.84))
	add_child(seal_text)

	# 注脚
	var layer := CanvasLayer.new()
	add_child(layer)
	var caption := Label.new()
	caption.text = "《五行三国》M0 风格定妆照 —— 像素小人 · 水墨远山 · 飞白剑气 · 朱砂点睛"
	caption.position = Vector2(16, 1040)
	layer.add_child(caption)

	var cam := Camera2D.new()
	add_child(cam)
	cam.make_current()


class ShadowDot:
	extends Node2D

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.4))
		draw_circle(Vector2.ZERO, 38.0, Color(0.10, 0.09, 0.09, 0.18))
