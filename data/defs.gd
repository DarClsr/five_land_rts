class_name Defs
extends RefCounted
"""数据定义表。M3 迁移为 .tres 资源，字段结构保持一致。"""

# ---- 单位（element: 金木水火土 / 凡）----
const UNITS := {
	# 离国（火）
	"yanmin": {
		"name": "炎民", "element": "火", "hp": 60, "dmg": 0, "speed": 140.0,
		"cost": 50, "build_time": 8.0, "pop": 1, "worker": true,
	},
	"huoshishou": {
		"name": "火矢手", "element": "火", "hp": 80, "dmg": 9, "range": 180.0, "cd": 1.2,
		"speed": 150.0, "ranged": true, "cost": 90, "build_time": 12.0, "pop": 1,
	},
	"baoyanzu": {
		"name": "爆炎卒", "element": "火", "hp": 110, "dmg": 16, "range": 34.0, "cd": 1.0,
		"speed": 160.0, "cost": 110, "build_time": 14.0, "pop": 1,
	},
	# 朔国（水）
	"mijian": {
		"name": "密探", "element": "水", "hp": 60, "dmg": 0, "speed": 140.0,
		"cost": 50, "build_time": 8.0, "pop": 1, "worker": true,
	},
	"youxia": {
		"name": "锦帆游侠", "element": "水", "hp": 90, "dmg": 10, "range": 36.0, "cd": 0.9,
		"speed": 185.0, "can_stealth": true, "cost": 100, "build_time": 13.0, "pop": 1,
	},
	"binglingshou": {
		"name": "水军弓手", "element": "水", "hp": 75, "dmg": 8, "range": 170.0, "cd": 1.3,
		"speed": 145.0, "ranged": true, "slow": true, "cost": 95, "build_time": 13.0, "pop": 1,
	},
	"chaoling": {
		"name": "潮灵", "element": "水", "hp": 90, "dmg": 0, "speed": 155.0,
		"aura": true, "cost": 80, "build_time": 10.0, "pop": 1,
	},
	# 大衍（土）
	"yongjiang": {
		"name": "俑匠", "element": "凡", "hp": 60, "dmg": 0, "speed": 140.0,
		"cost": 50, "build_time": 8.0, "pop": 1, "worker": true,
	},
	"yanjiawei": {
		"name": "虎卫", "element": "土", "hp": 220, "dmg": 8, "range": 34.0, "cd": 1.1,
		"speed": 120.0, "cost": 130, "build_time": 16.0, "pop": 1,
	},
	"dilingshi": {
		"name": "地灵师", "element": "土", "hp": 90, "dmg": 6, "range": 160.0, "cd": 2.2,
		"speed": 140.0, "ranged": true, "stun": true, "cost": 110, "build_time": 14.0, "pop": 1,
	},
	"juyong": {
		"name": "青州重甲", "element": "土", "hp": 380, "dmg": 24, "range": 40.0, "cd": 1.4,
		"speed": 90.0, "cost": 260, "build_time": 24.0, "pop": 2,
	},
	"taoyongzu": {
		"name": "预备兵", "element": "凡", "hp": 55, "dmg": 6, "range": 30.0, "cd": 1.0,
		"speed": 150.0, "cost": 0, "build_time": 2.0, "pop": 1,  # 仅由皇陵归尘唤起
	},
	"toushiji": {
		"name": "霹雳车", "element": "凡", "hp": 150, "dmg": 30, "range": 260.0, "cd": 3.0,
		"speed": 70.0, "ranged": true, "siege": true, "cost": 220, "build_time": 20.0, "pop": 2,
	},
	"yaohuojiang": {
		"name": "窑火匠", "element": "火", "hp": 80, "dmg": 5, "range": 120.0, "cd": 1.6,
		"speed": 140.0, "ranged": true, "repair_aura": true, "cost": 100, "build_time": 13.0, "pop": 1,
	},
	"xuantiebingpo": {
		"name": "玄铁兵魄", "element": "金", "hp": 100, "dmg": 0, "speed": 150.0,
		"sharp_aura": true, "cost": 90, "build_time": 12.0, "pop": 1,
	},
}

# ---- 建筑 ----
const BUILDINGS := {
	# 离国
	"dazhai": {
		"name": "汉中府", "size": Vector2(140, 100), "hp": 1200,
		"cost": 0, "build_time": 40.0, "pop_cap": 6, "dropoff": true, "trains": ["yanmin"],
	},
	"gaizhang": {
		"name": "营帐", "faction_names": {"li": "连营", "shuo": "水榭"},
		"size": Vector2(72, 60), "hp": 240,
		"cost": 60, "build_time": 12.0, "pop_cap": 8,
	},
	"yanzhen": {
		"name": "白毦营", "size": Vector2(96, 80), "hp": 600,
		"cost": 120, "build_time": 18.0, "trains": ["huoshishou", "baoyanzu"],
	},
	"fengsui": {
		"name": "瞭台", "faction_names": {"li": "烽火台", "shuo": "水寨瞭台"},
		"size": Vector2(48, 64), "hp": 400,
		"cost": 80, "build_time": 14.0, "tower": true,
	},
	# 朔国
	"wubao": {
		"name": "都督府", "size": Vector2(140, 100), "hp": 1200,
		"cost": 0, "build_time": 40.0, "pop_cap": 6, "dropoff": true, "trains": ["mijian"],
	},
	"yingweitang": {
		"name": "解烦营", "size": Vector2(96, 80), "hp": 600,
		"cost": 120, "build_time": 18.0, "trains": ["youxia", "binglingshou", "chaoling"],
	},
	# 大衍
	"yashu": {
		"name": "司空府", "size": Vector2(140, 100), "hp": 1200,
		"cost": 0, "build_time": 40.0, "pop_cap": 6, "dropoff": true, "trains": ["yongjiang"],
	},
	"fangshi": {
		"name": "军帐", "size": Vector2(72, 60), "hp": 240,
		"cost": 60, "build_time": 12.0, "pop_cap": 8,
	},
	"fubingying": {
		"name": "武卫营", "size": Vector2(96, 80), "hp": 600,
		"cost": 120, "build_time": 18.0, "trains": ["yanjiawei", "dilingshi", "juyong", "toushiji"],
	},
	"huangling": {
		"name": "军资府", "size": Vector2(120, 90), "hp": 900,
		"cost": 200, "build_time": 30.0, "abilities": ["dust_summon", "dust_crystal"], "no_migrate": true,
	},
	"yaojian": {
		"name": "工曹坊", "size": Vector2(88, 70), "hp": 500,
		"cost": 110, "build_time": 15.0, "trains": ["yaohuojiang"],
	},
	"junqijian": {
		"name": "强弩署", "size": Vector2(88, 70), "hp": 500,
		"cost": 110, "build_time": 15.0, "trains": ["xuantiebingpo"],
	},
	"gulou": {
		"name": "望楼", "size": Vector2(48, 64), "hp": 400,
		"cost": 80, "build_time": 14.0, "tower": true,
	},
	"fangqiu": {
		"name": "阵墙", "size": Vector2(56, 56), "hp": 350,
		"cost": 20, "build_time": 4.0, "wall": true, "no_migrate": true,
	},
}

# ---- 势力 ----
const FACTIONS := {
	"li": {
		"name": "蜀汉", "color": Color(0.22, 0.50, 0.35), "hq": "dazhai", "worker": "yanmin",
		"build": ["gaizhang", "yanzhen", "fengsui"],
	},
	"shuo": {
		"name": "东吴", "color": Color(0.25, 0.32, 0.45), "hq": "wubao", "worker": "mijian",
		"build": ["gaizhang", "yingweitang", "fengsui"],
	},
	"yan": {
		"name": "曹魏", "color": Color(0.24, 0.26, 0.30), "hq": "yashu", "worker": "yongjiang",
		"build": ["fangshi", "fubingying", "huangling", "yaojian", "junqijian", "gulou", "fangqiu"],
	},
}


static func unit(id: String) -> Dictionary:
	return UNITS[id]


static func building(id: String) -> Dictionary:
	return BUILDINGS[id]


static func building_name(id: String, faction_id := "") -> String:
	var def: Dictionary = BUILDINGS[id]
	return str(def.get("faction_names", {}).get(faction_id, def["name"]))


static func faction(id: String) -> Dictionary:
	return FACTIONS[id]


## 单位工厂：按定义表实例化单位（民夫/战斗单位统一入口）
static func spawn(id: String, team_id: int) -> Unit:
	var def: Dictionary = UNITS[id]
	var u: Unit
	if def.get("worker", false):
		u = Worker.new()
	else:
		u = Unit.new()
	u.unit_id = id
	u.team = team_id
	u.element = str(def.get("element", "凡"))
	u.max_hp = float(def.get("hp", 60))
	u.base_speed = float(def.get("speed", 150.0))
	u.dmg = float(def.get("dmg", 0))
	u.attack_range = float(def.get("range", 0))
	u.attack_cd = float(def.get("cd", 1.0))
	u.ranged = bool(def.get("ranged", false))
	u.applies_slow = bool(def.get("slow", false))
	u.applies_stun = bool(def.get("stun", false))
	u.siege = bool(def.get("siege", false))
	u.has_aura = bool(def.get("aura", false))
	u.has_repair_aura = bool(def.get("repair_aura", false))
	u.has_sharp_aura = bool(def.get("sharp_aura", false))
	u.can_stealth = bool(def.get("can_stealth", false))
	u.pop = int(def.get("pop", 1))
	return u
