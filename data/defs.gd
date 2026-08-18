class_name Defs
extends RefCounted
"""M1 数据定义表。M2 起迁移为 .tres 资源，字段结构保持一致。"""

# ---- 单位（element: 金木水火土 / 凡）----
const UNITS := {
	"yanmin": {  # 离国民夫
		"name": "炎民", "element": "火", "hp": 60, "dmg": 0, "speed": 140.0,
		"cost": 50, "build_time": 8.0, "pop": 1, "worker": true,
	},
	"huoshishou": {  # M1-2 战斗单位占位
		"name": "火矢手", "element": "火", "hp": 80, "dmg": 9, "range": 180.0, "speed": 150.0,
		"cost": 90, "build_time": 12.0, "pop": 1,
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
	"yanzhen": {  # 焰阵：兵营（M1-2 解锁生产）
		"name": "焰阵", "size": Vector2(96, 80), "hp": 600,
		"cost": 120, "build_time": 18.0, "trains": [],
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
