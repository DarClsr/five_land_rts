class_name PixelFigure
extends RefCounted
"""占位像素小人生成器：24x32 墨灰斗笠剑客，accent 色画腰带（阵营识别）。M2 起替换为正式美术。"""

const W := 24
const H := 32


static func make_texture(accent: Color) -> ImageTexture:
	var data := PackedByteArray()
	data.resize(W * H * 4)
	var img := Image.create_from_data(W, H, false, Image.FORMAT_RGBA8, data)
	var ink := Color(0.16, 0.15, 0.14)
	var dark := Color(0.30, 0.29, 0.28)
	var mid := Color(0.52, 0.51, 0.49)
	var pale := Color(0.80, 0.78, 0.74)
	_fill(img, Rect2i(3, 2, 18, 2), dark)          # 斗笠檐
	_fill(img, Rect2i(6, 0, 12, 2), ink)           # 斗笠顶
	_fill(img, Rect2i(8, 4, 8, 5), mid)            # 脸
	_fill(img, Rect2i(7, 9, 10, 10), dark)         # 袍身
	_fill(img, Rect2i(6, 11, 1, 6), dark)          # 左臂
	_fill(img, Rect2i(17, 11, 1, 6), dark)         # 右臂
	_fill(img, Rect2i(6, 12, 12, 2), accent)       # 腰带（阵营色）
	_fill(img, Rect2i(9, 19, 3, 8), ink)           # 左腿
	_fill(img, Rect2i(12, 19, 3, 8), dark)         # 右腿
	_fill(img, Rect2i(8, 27, 4, 2), ink)           # 左足
	_fill(img, Rect2i(12, 27, 4, 2), ink)          # 右足
	_fill(img, Rect2i(19, 4, 1, 13), pale)         # 背剑
	_fill(img, Rect2i(18, 17, 3, 1), dark)         # 剑柄
	return ImageTexture.create_from_image(img)


static func _fill(img: Image, r: Rect2i, c: Color) -> void:
	for y in range(r.position.y, r.position.y + r.size.y):
		for x in range(r.position.x, r.position.x + r.size.x):
			img.set_pixel(x, y, c)
