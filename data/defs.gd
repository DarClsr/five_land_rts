class_name Defs
extends RefCounted
"""M1 数据定义表。M2 起迁移为 .tres 资源，字段结构保持一致。"""

# ---- 单位（element: 金木水火土 / 凡）----
const UNITS := {
	"yanmin": {  # 离国民夫
		"name": "炎民", "element": "火", "hp": 60, "dmg": 0, "speed": 140.0,
		"cost": 50, "build_time": 8.0, "pop": 1, "worker": true,
	},
	"huoshishou": {  # 火矢手：远程，攻击附带灼烧
		"name": "火矢手", "element": "火", "hp": 80, "dmg": 9, "range": 180.0, "cd": 1.2,
		"speed": 150.0, "ranged": true, "cost": 90, "build_time": 12.0, "pop": 1,
	},
	"baoyanzu": {  # 爆炎卒：高攻低血近战
		"name": "爆炎卒", "element": "火", "hp": 110, "dmg": 16, "range": 34.0, "cd": 1.0,
		"speed": 160.0, "cost": 110, "build_time": 14.0, "pop": 1,
	},
	"youxia": {  # 游侠：双形态刺客（M1 潜流=隐身减速，穿水 M2 实装）
		"name": "游侠", "element": "水", "hp": 95, "dmg": 12, "range": 36.0, "cd": 0.9,
		"speed": 185.0, "can_stealth": true, "cost": 100, "build_time": 13.0, "pop": 1,
	},
	"binglingshou": {  # 冰凌射手：远程减速
		"name": "冰凌射手", "element": "水", "hp": 75, "dmg": 8, "range": 170.0, "cd": 1.3,
		"speed": 145.0, "ranged": true, "slow": true, "cost": 95, "build_time": 13.0, "pop": 1,
	},
	"chaoling": {  # 潮灵：涨潮光环（范围友军加速）
		"name": "潮灵", "element": "水", "hp": 90, "dmg": 0, "speed": 155.0,
		"aura": true, "cost": 80, "build_time": 10.0, "pop": 1,
	},
}

# ---- 建筑 ----
const BUILDINGS := {
	"dazhai": {  # 离国主基地：灵晶回缴点 + 训练炎民
		"name": "大寨", "size": Vector2(140, 100), "hp": 1200,
		"cost": 0, "build_time": 40.0, "pop_cap": 6, "dropoff": true, "trains": ["yanmin"],
	},
	"gaizhang": {  # 篝帐：人口
		"name": "篝帐", "size": Vector2(72, 60), "hp": 240,
		"cost": 60, "build_time": 12.0, "pop_cap": 8,
	},
	"yanzhen": {  # 焰阵：兵营
		"name": "焰阵", "size": Vector2(96, 80), "hp": 600,
		"cost": 120, "build_time": 18.0, "trains": ["huoshishou", "baoyanzu"],
	},
	"fengsui": {  # 烽燧：防御塔（M1-2 解锁攻击）
		"name": "烽燧", "size": Vector2(48, 64), "hp": 400,
		"cost": 80, "build_time": 14.0,
	},
}


static func unit(id: String) -> Dictionary:
	return UNITS[id]


static func building(id: String) -> Dictionary:
	return BUILDINGS[id]


## 单位工厂：按定义表实例化单位（民夫/战斗单位统一入口）
static func spawn(id: String, team_id: int) -> Unit:
	var def: Dictionary = UNITS[id]
	var u: Unit
	if def.get("worker", false):
		u = Worker.new()
	else:
		u = Unit.new()
	u.team = team_id
	u.element = str(def.get("element", "凡"))
	u.max_hp = float(def.get("hp", 60))
	u.base_speed = float(def.get("speed", 150.0))
	u.dmg = float(def.get("dmg", 0))
	u.attack_range = float(def.get("range", 0))
	u.attack_cd = float(def.get("cd", 1.0))
	u.ranged = bool(def.get("ranged", false))
	u.applies_slow = bool(def.get("slow", false))
	u.can_stealth = bool(def.get("can_stealth", false))
	u.has_aura = bool(def.get("aura", false))
	u.pop = int(def.get("pop", 1))
	return u
