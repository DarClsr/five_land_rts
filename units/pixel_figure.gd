class_name PixelFigure
extends RefCounted
"""24x32 程序化像素单位样板：统一脚底锚点，以装备轮廓区分兵种。"""

const W := 24
const H := 32


static func make_texture(accent: Color, unit_id := "") -> ImageTexture:
	var data := PackedByteArray()
	data.resize(W * H * 4)
	var img := Image.create_from_data(W, H, false, Image.FORMAT_RGBA8, data)
	var ink := Color(0.16, 0.15, 0.14)
	var dark := Color(0.30, 0.29, 0.28)
	var mid := Color(0.52, 0.51, 0.49)
	var pale := Color(0.80, 0.78, 0.74)
	if unit_id == "toushiji":
		_fill(img, Rect2i(3, 18, 18, 6), dark)
		_fill(img, Rect2i(6, 14, 11, 5), mid)
		_fill(img, Rect2i(13, 5, 2, 11), pale)
		_fill(img, Rect2i(14, 4, 7, 3), ink)
		_fill(img, Rect2i(2, 24, 6, 6), ink)
		_fill(img, Rect2i(16, 24, 6, 6), ink)
		_fill(img, Rect2i(4, 25, 2, 2), accent)
		_fill(img, Rect2i(18, 25, 2, 2), accent)
		return ImageTexture.create_from_image(img)
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
	match unit_id:
		"yanmin", "mijian", "yongjiang":
			_fill(img, Rect2i(2, 14, 5, 6), pale)      # 工具袋
			_fill(img, Rect2i(4, 8, 2, 12), accent)    # 工具柄
		"youxia":
			_fill(img, Rect2i(2, 7, 1, 14), pale)      # 双刃
			_fill(img, Rect2i(21, 7, 1, 14), pale)
			_fill(img, Rect2i(5, 4, 14, 3), ink)       # 兜帽
		"binglingshou":
			_fill(img, Rect2i(2, 8, 2, 14), pale)      # 长弓
			_fill(img, Rect2i(4, 7, 1, 2), pale)
			_fill(img, Rect2i(4, 21, 1, 2), pale)
		"chaoling":
			_fill(img, Rect2i(3, 17, 18, 8), accent)   # 宽袍
			_fill(img, Rect2i(9, 0, 6, 6), pale)       # 潮珠
			_fill(img, Rect2i(10, 1, 4, 4), accent)
		"yanjiawei":
			_fill(img, Rect2i(1, 10, 6, 13), pale)     # 大盾
			_fill(img, Rect2i(2, 12, 4, 2), accent)
			_fill(img, Rect2i(4, 5, 16, 5), ink)       # 重盔
		"dilingshi":
			_fill(img, Rect2i(21, 4, 2, 22), dark)     # 地杖
			_fill(img, Rect2i(19, 1, 5, 5), accent)
		"juyong":
			_fill(img, Rect2i(2, 7, 20, 6), pale)      # 巨肩甲
			_fill(img, Rect2i(4, 13, 16, 10), dark)
			_fill(img, Rect2i(7, 0, 10, 8), ink)
		"yaohuojiang":
			_fill(img, Rect2i(1, 5, 3, 17), dark)      # 锻锤
			_fill(img, Rect2i(0, 3, 8, 5), accent)
		"xuantiebingpo":
			_fill(img, Rect2i(4, 1, 16, 2), accent)    # 兵魄光环
			_fill(img, Rect2i(2, 4, 2, 14), pale)
			_fill(img, Rect2i(20, 4, 2, 14), pale)
	return ImageTexture.create_from_image(img)


static func _fill(img: Image, r: Rect2i, c: Color) -> void:
	for y in range(r.position.y, r.position.y + r.size.y):
		for x in range(r.position.x, r.position.x + r.size.x):
			img.set_pixel(x, y, c)
