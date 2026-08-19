extends Node
"""三国显示层契约：显示身份迁移，但内部势力和玩法合同保持不变。"""

var _failures := 0


func _ready() -> void:
	_expect(Defs.faction("li")["name"] == "蜀汉", "li 显示为蜀汉")
	_expect(Defs.faction("shuo")["name"] == "东吴", "shuo 显示为东吴")
	_expect(Defs.faction("yan")["name"] == "曹魏", "yan 显示为曹魏")
	_expect(Defs.faction("li")["hq"] == "dazhai" and Defs.faction("li")["worker"] == "yanmin", "蜀汉内部合同不变")
	_expect(Defs.faction("shuo")["hq"] == "wubao" and Defs.faction("shuo")["worker"] == "mijian", "东吴内部合同不变")
	_expect(Defs.faction("yan")["hq"] == "yashu" and Defs.faction("yan")["worker"] == "yongjiang", "曹魏内部合同不变")
	_expect(Defs.faction("li")["build"] == ["gaizhang", "yanzhen", "fengsui"], "蜀汉建造列表不变")
	_expect(Defs.faction("shuo")["build"] == ["gaizhang", "yingweitang", "fengsui"], "东吴建造列表不变")
	_expect(Defs.building_name("gaizhang", "li") == "连营", "蜀汉共享营帐显示为连营")
	_expect(Defs.building_name("gaizhang", "shuo") == "水榭", "东吴共享营帐显示为水榭")
	_expect(Defs.building_name("fengsui", "li") == "烽火台", "蜀汉共享瞭台显示为烽火台")
	_expect(Defs.building_name("fengsui", "shuo") == "水寨瞭台", "东吴共享瞭台显示为水寨瞭台")
	_expect(Defs.unit("youxia")["name"] == "锦帆游侠", "东吴游侠称谓已迁移")
	_expect(Defs.unit("binglingshou")["name"] == "水军弓手", "东吴弓手称谓已迁移")
	_expect(Defs.unit("yanjiawei")["name"] == "虎卫", "曹魏重甲称谓已迁移")
	_expect(Defs.unit("juyong")["name"] == "青州重甲", "曹魏巨型重甲称谓已迁移")
	_expect(Defs.unit("taoyongzu")["name"] == "预备兵", "曹魏补员称谓已迁移")
	_expect(Defs.unit("toushiji")["name"] == "霹雳车", "曹魏攻城单位称谓已迁移")
	_expect(ProjectSettings.get_setting("application/config/name") == "五行三国", "项目名已迁移")
	_expect(load("res://maps/M1Map.tscn") is PackedScene, "M1 场景可加载")
	_expect(load("res://maps/M2Map.tscn") is PackedScene, "M2 场景可加载")
	if _failures == 0:
		print("TEST_THREE_KINGDOMS_DISPLAY PASS")
		get_tree().quit(0)
	else:
		push_error("TEST_THREE_KINGDOMS_DISPLAY FAIL: %d 项失败" % _failures)
		get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("  PASS: " + message)
	else:
		_failures += 1
		push_error("  FAIL: " + message)
