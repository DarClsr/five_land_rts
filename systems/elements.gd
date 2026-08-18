class_name Elements
extends RefCounted
"""五行克制表与伤害计算。凡品（建筑/造物/民夫）不吃克制。"""

const COUNTER := {
	"金": "木",  # 金克木
	"木": "土",  # 木克土
	"土": "水",  # 土克水
	"水": "火",  # 水克火
	"火": "金",  # 火克金
}

const COUNTER_BONUS := 1.25        # 克制伤害加成
const BURN_DPS := 3.0              # 灼烧每秒伤害
const BURN_TIME := 3.0             # 灼烧持续
const SLOW_TIME := 2.0             # 冰凌减速持续
const SLOW_FACTOR := 0.6           # 减速乘数
const QUENCH_TIME_MS := 8000       # 「熄」：灼烧免疫时长
const ELEMENT_COLORS := {
	"金": Color(0.75, 0.75, 0.72),
	"木": Color(0.22, 0.50, 0.35),
	"水": Color(0.25, 0.32, 0.45),
	"火": Color(0.72, 0.18, 0.14),
	"土": Color(0.60, 0.50, 0.30),
	"凡": Color(0.45, 0.45, 0.45),
}


static func multiplier(attacker_element: String, defender_element: String) -> float:
	if defender_element == "凡":
		return 1.0
	return COUNTER_BONUS if COUNTER.get(attacker_element, "") == defender_element else 1.0


static func element_color(e: String) -> Color:
	return ELEMENT_COLORS.get(e, ELEMENT_COLORS["凡"])
