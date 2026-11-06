class_name Data
extends RefCounted

const TITLE := "余烬行者"
const VERSION := "0.29.0"
const SAVE_PATH := "user://ember_walker_save.json"
const INVENTORY_SIZE := 100
const MAX_LEVEL := 60

const CLASS_ORDER := ["warrior", "mage", "archer"]
const CHARACTER_ORDER := ["warrior", "mage", "archer", "warden", "oracle", "ranger"]

const CHARACTERS := {
	"warrior": {
		"name": "罗兰", "title": "铁壁", "tag": "重装 · 坚韧",
		"color": "#e0a24a", "archetype": "warrior",
		"sprite": "res://assets/characters/roland_walk.png",
		"portrait": "res://assets/characters/roland_face.png",
		"tint": "#ffffff", "frame_w": 16, "frame_h": 16,
		"desc": "以生命和护甲硬抗伤害，适合稳扎稳打的长时间战斗。",
		"bonus_text": "生命上限 +15%\n护甲 +10%",
		"hp_pct": 0.15, "armor_pct": 0.10,
	},
	"mage": {
		"name": "梅林", "title": "奥术", "tag": "秘法 · 爆发",
		"color": "#ffad66", "archetype": "mage",
		"sprite": "res://assets/characters/merlin_walk.png",
		"portrait": "res://assets/characters/merlin_face.png",
		"tint": "#ffffff", "frame_w": 16, "frame_h": 16,
		"desc": "把智力转化为纯粹的法术强度，并用少量暴击放大爆发。",
		"bonus_text": "法术强度 +15%\n暴击 +5%",
		"power_pct": 0.15, "crit": 0.05,
	},
	"archer": {
		"name": "艾拉", "title": "疾风", "tag": "游侠 · 迅捷",
		"color": "#79d17c", "archetype": "archer",
		"sprite": "res://assets/characters/ella_walk.png",
		"portrait": "res://assets/characters/ella_face.png",
		"tint": "#ffffff", "frame_w": 16, "frame_h": 16,
		"desc": "靠高频攻击和暴击滚雪球，持续输出能力最强。",
		"bonus_text": "暴击 +8%\n急速 +8%",
		"crit": 0.08, "haste": 0.08,
	},
	"warden": {
		"name": "布伦", "title": "狂战", "tag": "重装 · 狂战",
		"color": "#ff7b5e", "archetype": "warrior",
		"sprite": "res://assets/characters/wren_walk.png",
		"portrait": "res://assets/characters/wren_face.png",
		"tint": "#ffffff", "frame_w": 16, "frame_h": 16,
		"desc": "放弃部分防守换取更凶的进攻，用力量与速度压过敌人。",
		"bonus_text": "攻击强度 +10%\n急速 +3%",
		"power_pct": 0.10, "haste": 0.03,
	},
	"oracle": {
		"name": "塞拉", "title": "月辉", "tag": "秘法 · 月辉",
		"color": "#d18cff", "archetype": "mage",
		"sprite": "res://assets/characters/sera_walk.png",
		"portrait": "res://assets/characters/sera_face.png",
		"tint": "#ffffff", "frame_w": 16, "frame_h": 16,
		"desc": "用月光维持生命，把造成的伤害转成自己的续航。",
		"bonus_text": "吸血 +6%\n生命上限 +5%",
		"lifesteal": 0.06, "hp_pct": 0.05,
	},
	"ranger": {
		"name": "凯", "title": "破甲", "tag": "游侠 · 破甲",
		"color": "#5ec8d8", "archetype": "archer",
		"sprite": "res://assets/characters/kai_walk.png",
		"portrait": "res://assets/characters/kai_face.png",
		"tint": "#ffffff", "frame_w": 16, "frame_h": 16,
		"desc": "专注射穿护甲，面对高防御目标时伤害更稳定。",
		"bonus_text": "护甲穿透 +10%",
		"pen": 0.10,
	},
}

const CLASSES := {
	"warrior": {
		"name": "战士",
		"role": "板甲 / 重甲 · 力量",
		"desc": "力量与耐力。高护甲、高生命，用最朴素的方式碾过敌阵。",
		"sprite": "res://assets/characters/roland_walk.png",
		"color": "#e0a24a",
		"main": "strength",
		"attack_type": "physical",
		"armor_types": ["plate", "heavy"],
		"weapon_types": ["sword", "mace"],
		"offhand_type": "shield",
		"attack_interval": 2.2,
		"base_hp": 70,
		"base": {"strength": 13, "agility": 4, "intellect": 2, "stamina": 13},
		"growth": {"strength": 2.7, "agility": 0.35, "intellect": 0.30, "stamina": 1.9},
	},
	"mage": {
		"name": "法师",
		"role": "布甲 / 轻甲 · 智力",
		"desc": "智力与奥术。脆皮，但法术强度与穿透让伤害曲线陡得吓人。",
		"sprite": "res://assets/characters/merlin_walk.png",
		"color": "#6fa8ff",
		"main": "intellect",
		"attack_type": "magic",
		"armor_types": ["cloth", "light"],
		"weapon_types": ["wand", "codex"],
		"offhand_type": "tome",
		"attack_interval": 2.4,
		"base_hp": 50,
		"base": {"strength": 3, "agility": 5, "intellect": 14, "stamina": 8},
		"growth": {"strength": 0.30, "agility": 0.40, "intellect": 2.9, "stamina": 1.4},
	},
	"archer": {
		"name": "弓箭手",
		"role": "皮甲 / 锁甲 · 敏捷",
		"desc": "敏捷与猎弓。攻速快、暴击高、闪避好，靠持续输出滚雪球。",
		"sprite": "res://assets/characters/ella_walk.png",
		"color": "#79d17c",
		"main": "agility",
		"attack_type": "physical",
		"armor_types": ["leather", "mail"],
		"weapon_types": ["shortbow", "longbow"],
		"offhand_type": "quiver",
		"attack_interval": 1.7,
		"base_hp": 60,
		"base": {"strength": 4, "agility": 14, "intellect": 3, "stamina": 9},
		"growth": {"strength": 0.35, "agility": 2.9, "intellect": 0.35, "stamina": 1.5},
	},
}

const ARMOR_NAMES := {"plate": "板甲", "heavy": "重甲", "cloth": "布甲", "light": "轻甲", "leather": "皮甲", "mail": "锁甲"}
const ARMOR_SLOT_NAMES := {"head": "头盔", "chest": "胸甲", "hands": "护手", "legs": "护腿", "feet": "战靴"}
const WEAPON_NAMES := {"sword": "长剑", "axe": "战斧", "mace": "战锤", "staff": "法杖", "wand": "魔杖",
	"codex": "法典", "bow": "长弓", "shortbow": "短弓", "longbow": "长弓"}
const OFFHAND_NAMES := {"shield": "盾牌", "tome": "魔典", "quiver": "箭袋"}

const SLOT_INFO := {
	"head": {"name": "头盔", "short": "头盔", "kind": "armor"},
	"chest": {"name": "胸甲", "short": "胸甲", "kind": "armor"},
	"hands": {"name": "手套", "short": "手套", "kind": "armor"},
	"legs": {"name": "腿甲", "short": "腿甲", "kind": "armor"},
	"feet": {"name": "鞋子", "short": "鞋子", "kind": "armor"},
	"main": {"name": "主武器", "short": "主武器", "kind": "weapon"},
	"off": {"name": "副武器", "short": "副武器", "kind": "offhand"},
	"neck": {"name": "项链", "short": "项链", "kind": "jewel"},
	"trinket": {"name": "饰品", "short": "饰品", "kind": "jewel"},
	"ring": {"name": "戒指", "short": "戒指", "kind": "jewel"},
	"rune": {"name": "符文", "short": "符文", "kind": "rune"},
	"ring1": {"name": "戒指", "short": "戒指", "kind": "jewel"},
	"ring2": {"name": "戒指", "short": "戒指", "kind": "jewel"},
	"rune1": {"name": "符文", "short": "符文", "kind": "rune"},
	"rune2": {"name": "符文", "short": "符文", "kind": "rune"},
	"rune3": {"name": "符文", "short": "符文", "kind": "rune"},
}

const EQUIP_ORDER := ["head", "neck", "chest", "main", "off", "hands", "legs",
	"ring1", "ring2", "trinket", "feet", "rune1", "rune2", "rune3"]

const QUALITIES := [
	{"name": "普通", "color": "#b9c2d0", "mult": 1.00, "affixes": 1},
	{"name": "优秀", "color": "#4fe06a", "mult": 1.06, "affixes": 2},
	{"name": "精良", "color": "#4aa3ff", "mult": 1.14, "affixes": 3},
	{"name": "史诗", "color": "#b96bff", "mult": 1.26, "affixes": 4},
	{"name": "传说", "color": "#ff9f43", "mult": 1.42, "affixes": 5},
]

const QUALITY_PREFIX := ["磨损的", "坚固的", "精工的", "史诗的", "传世的"]

const AFFIX_KIND := {
	"crit": {"name": "暴击", "title": "锐利", "div": 8.0, "percent": true},
	"haste": {"name": "急速", "title": "疾风", "div": 10.0, "percent": true},
	"hit": {"name": "命中", "title": "猎手", "div": 10.0, "percent": true},
	"dodge": {"name": "闪避", "title": "灵巧", "div": 16.0, "percent": true},
	"parry": {"name": "招架", "title": "铁壁", "div": 16.0, "percent": true},
	"block": {"name": "格挡", "title": "壁垒", "div": 16.0, "percent": true},
	"vers": {"name": "全能", "title": "均衡", "div": 12.0, "percent": true},
	"lifesteal": {"name": "吸血", "title": "汲血", "div": 15.0, "percent": true},
	"pen": {"name": "穿透", "title": "破甲", "div": 10.0, "percent": true},
	"crit_dmg": {"name": "暴击伤害", "title": "致命", "div": 10.0, "percent": true},
	"attack_power": {"name": "攻击强度", "title": "蛮力", "div": 1.0, "percent": false},
	"spell_power": {"name": "法术强度", "title": "奥术", "div": 1.0, "percent": false},
	"hp": {"name": "生命", "title": "坚韧", "div": 1.0, "percent": false},
	"hp_regen": {"name": "生命回复", "title": "复苏", "div": 1.0, "percent": false},
	"extra_attack": {"name": "额外攻击", "title": "回响", "div": 1.0, "percent": true},
}

const AFFIX_BASE := {
	"crit": 2.0, "haste": 2.0, "hit": 1.5, "dodge": 2.0, "parry": 2.0, "block": 2.0,
	"vers": 1.5, "lifesteal": 1.2, "pen": 1.5, "crit_dmg": 3.0,
	"attack_power": 4.0, "spell_power": 4.0, "hp": 10.0, "hp_regen": 1.5,
	"extra_attack": 1.0,
}
const AFFIX_SCALE := {
	"crit": 0.80, "haste": 0.85, "hit": 0.60, "dodge": 0.65, "parry": 0.65, "block": 0.65,
	"vers": 0.55, "lifesteal": 0.45, "pen": 0.60, "crit_dmg": 1.00,
	"attack_power": 1.20, "spell_power": 1.20, "hp": 5.00, "hp_regen": 0.45,
	"extra_attack": 0.10,
}

const AFFIX_WEIGHTS := {
	"warrior": {"crit": 14, "haste": 9, "hit": 8, "dodge": 2, "parry": 8, "block": 8,
		"vers": 8, "lifesteal": 6, "pen": 7, "crit_dmg": 8, "attack_power": 12,
		"spell_power": 0, "hp": 10, "hp_regen": 6},
	"mage": {"crit": 13, "haste": 12, "hit": 8, "dodge": 3, "parry": 2, "block": 0,
		"vers": 8, "lifesteal": 5, "pen": 9, "crit_dmg": 8, "attack_power": 0,
		"spell_power": 13, "hp": 8, "hp_regen": 5, "extra_attack": 4},
	"archer": {"crit": 15, "haste": 13, "hit": 8, "dodge": 8, "parry": 3, "block": 0,
		"vers": 8, "lifesteal": 7, "pen": 7, "crit_dmg": 8, "attack_power": 12,
		"spell_power": 0, "hp": 8, "hp_regen": 5},
}

const AFFIX_KEYS := ["crit", "haste", "hit", "dodge", "parry", "block", "vers",
	"lifesteal", "pen", "crit_dmg", "attack_power", "spell_power", "hp", "hp_regen",
	"extra_attack"]

const AFFIX_TIERS := {
	"crit": "S", "haste": "S", "crit_dmg": "S", "pen": "S", "lifesteal": "S", "extra_attack": "S",
	"hit": "A", "dodge": "A", "parry": "A", "block": "A", "vers": "A",
	"attack_power": "A", "spell_power": "A",
	"hp": "B", "hp_regen": "B",
}
const AFFIX_TIER_WEIGHT := {"S": 0.65, "A": 1.0, "B": 1.25}
const AFFIX_TIER_VALUE := {"S": 0.80, "A": 1.0, "B": 1.15}

const STYLE_AFFIX_POOL := {
	"knight": ["parry", "block", "hp"],
	"berserker": ["attack_power", "crit_dmg", "pen"],
	"arcane": ["spell_power", "crit", "crit_dmg"],
	"moon": ["hp", "lifesteal", "hp_regen"],
	"swift": ["crit", "haste", "hit"],
	"hunt": ["crit", "crit_dmg", "pen"],
	"jewel_attack": ["crit", "haste", "pen"],
	"jewel_defense": ["dodge", "parry", "hp"],
}

const PRIMARY_NAMES := {"strength": "力量", "agility": "敏捷", "intellect": "智力", "stamina": "耐力"}

const WEAPON_STYLE := {
	"sword": "knight", "mace": "berserker", "axe": "berserker",
	"wand": "arcane", "codex": "moon", "staff": "arcane", "bow": "swift",
	"shortbow": "swift", "longbow": "hunt",
	"shield": "knight", "tome": "arcane", "quiver": "swift",
}
const ARMOR_STYLE_BY_TYPE := {
	"plate": "knight", "heavy": "berserker",
	"cloth": "arcane", "light": "moon",
	"leather": "swift", "mail": "hunt",
}
const LEGACY_STYLE_MAP := {
	"guard": "knight", "assault": "berserker", "ward": "moon",
	"ranger": "swift", "scout": "hunt",
}
const JEWEL_STYLES := ["jewel_attack", "jewel_defense"]
const STYLE_INFO := {
	"knight": {"name": "骑士", "desc": "偏防御：护甲 / 招架 / 格挡 / 生命"},
	"berserker": {"name": "狂战士", "desc": "偏攻击：攻击强度 / 暴击伤害 / 穿透"},
	"arcane": {"name": "奥术", "desc": "纯输出：法术强度 / 暴击 / 暴伤，有概率额外攻击一次"},
	"moon": {"name": "月辉", "desc": "半生存：法术伤害转护盾，生命 / 吸血 / 回复"},
	"swift": {"name": "疾风", "desc": "高攻速：急速 / 暴击，每 3 次攻击造成额外伤害"},
	"hunt": {"name": "猎杀", "desc": "高攻击：暴击 / 暴伤 / 穿透，不依赖攻击次数"},
	"jewel_attack": {"name": "锐利", "desc": "攻击向饰品：攻击属性 / 暴击 / 急速"},
	"jewel_defense": {"name": "守护", "desc": "防御向饰品：耐力 / 护甲 / 闪避"},
	"rune": {"name": "战斗符文", "desc": "只提供战斗属性，不提供主属性"},
}
const RUNE_STATS := ["crit", "haste", "hit", "dodge", "parry", "block",
	"vers", "lifesteal", "pen", "crit_dmg", "hp_regen"]
const RUNE_AFFIX_KEYS := ["crit", "haste", "hit", "dodge", "parry", "block",
	"vers", "lifesteal", "pen", "crit_dmg", "hp_regen", "extra_attack"]

const DIFF_ORDER := ["normal", "elite", "hero"]
const DIFFICULTIES := {
	"normal": {"name": "普通", "color": "#c8d2df", "hp": 1.00, "dmg": 1.00, "reward": 1.0, "quality_shift": 0},
	"elite": {"name": "精英", "color": "#f0c060", "hp": 2.70, "dmg": 2.44, "reward": 1.6, "quality_shift": 1},
	"hero": {"name": "英雄", "color": "#ff6b5e", "hp": 7.40, "dmg": 6.20, "reward": 2.4, "quality_shift": 2},
}

const MONSTER_TYPES := {
	"normal": {"name": "小怪", "hp": 1.0, "dmg": 1.0, "exp": 1.0, "gold": 1.0,
		"explore": 0.75, "drop_chance": 0.25, "quality": [55, 30, 12, 3, 0]},
	"elite": {"name": "精英", "hp": 1.9, "dmg": 1.35, "exp": 3.2, "gold": 4.0,
		"explore": 2.5, "drop_chance": 1.0, "quality": [0, 40, 40, 18, 2]},
	"boss": {"name": "区域首领", "hp": 19.0, "dmg": 4.5, "exp": 14.0, "gold": 25.0,
		"explore": 0.0, "drop_chance": 1.0, "quality": [0, 0, 18, 55, 27]},
}

const AREAS := [
	{"name": "灰烬平原", "min_level": 1, "max_level": 10, "color": "#c8a05a",
		"desc": "被余烬覆盖的旧战场，低阶怪物的猎场"},
	{"name": "霜风冰原", "min_level": 11, "max_level": 20, "color": "#7fc8e8",
		"desc": "风雪中的冻土，精英与首领盘踞"},
	{"name": "熔岩裂谷", "min_level": 21, "max_level": 30, "color": "#ff7b52",
		"desc": "地火撕裂的深谷，只有最硬的装备能走下去"},
]
const CONTENT_MAX_LEVEL := 30
const EXPLORE_CLEAR_GAIN := {"normal": 1.0, "elite": 2.0, "hero": 4.0}

const SHOP_STOCK_SIZE := 8
const SHOP_LEVEL_RANGE := 10
const SHOP_FREE_PER_HOUR := 5
const SHOP_PAID_COST := 100
const SHOP_QUALITY_WEIGHTS := [58, 30, 9.5, 2.0, 0.5]
const QUALITY_PRICE_MULT := [1.0, 2.2, 5.0, 12.0, 28.0]

# 副本掉落：0-2 件，稀有度整体压低紫色及以上
const DUNGEON_DROP_COUNT_WEIGHTS := [30, 50, 20]
const DUNGEON_QUALITY_WEIGHTS := [52, 32, 12, 3.5, 0.5]
const DROP_CATEGORY_WEIGHTS := [70, 22, 8]
const DROP_EQUIP_SLOTS := ["head", "chest", "hands", "legs", "feet", "main", "off"]
const DROP_EQUIP_WEIGHTS := [9, 9, 9, 9, 9, 13, 8]
const DROP_JEWEL_SLOTS := ["neck", "trinket", "ring"]
const DROP_JEWEL_WEIGHTS := [7, 6, 9]


static func area_def(index: int) -> Dictionary:
	return AREAS[clampi(index, 0, AREAS.size() - 1)]


static func area_unlocked(index: int, player_level: int) -> bool:
	if index < 0 or index >= AREAS.size():
		return false
	if index == 0:
		return true
	return player_level >= int(AREAS[index]["min_level"])


static func class_def(class_id: String) -> Dictionary:
	if CLASSES.has(class_id):
		return CLASSES[class_id]
	var arch := String(character_def(class_id).get("archetype", "warrior"))
	return CLASSES.get(arch, CLASSES["warrior"])


static func character_def(class_id: String) -> Dictionary:
	return CHARACTERS.get(class_id, CHARACTERS["warrior"])


static func character_name(class_id: String) -> String:
	return String(character_def(class_id)["name"])


static func quality_color(q: int) -> Color:
	return Color(QUALITIES[clampi(q, 0, 4)]["color"])


static func quality_name(q: int) -> String:
	return QUALITIES[clampi(q, 0, 4)]["name"]


static func difficulty_color(diff: String) -> Color:
	return Color(DIFFICULTIES.get(diff, DIFFICULTIES["normal"])["color"])


static func slot_label(slot: String) -> String:
	return SLOT_INFO.get(slot, {}).get("name", slot)


static func slot_short(slot: String) -> String:
	return SLOT_INFO.get(slot, {}).get("short", "?")


static func base_slot(slot: String) -> String:
	if slot.begins_with("ring"):
		return "ring"
	if slot.begins_with("rune"):
		return "rune"
	return slot


static func affix_percent(key: String, value: float) -> float:
	var div: float = AFFIX_KIND.get(key, {}).get("div", 1.0)
	return value / div


static func fmt_affix(key: String, value: float) -> String:
	var info: Dictionary = AFFIX_KIND.get(key, {})
	var nm: String = info.get("name", key)
	if info.get("percent", false):
		return "%s +%.1f%%" % [nm, value / float(info.get("div", 1.0))]
	return "%s +%d" % [nm, int(round(value))]


static func fmt_primary(key: String, value: float) -> String:
	return "%s +%d" % [PRIMARY_NAMES.get(key, key), int(round(value))]


static func exp_to_next(level: int) -> int:
	return int(round(70.0 * pow(float(level), 1.45)))


static func dungeon_level_range(player_level: int, area: Dictionary) -> Vector2i:
	var amin := int(area["min_level"])
	var amax := int(area["max_level"])
	var hi: int = mini(amax, player_level + 4)
	var lo: int = maxi(amin, player_level - 4)
	if lo > hi:
		lo = hi
	if hi < amin:
		hi = amin
	if lo > amax:
		lo = amax
	return Vector2i(lo, hi)


static func monster_hp(type_id: String, level: int, diff: String) -> float:
	var t: Dictionary = MONSTER_TYPES[type_id]
	var d: Dictionary = DIFFICULTIES[diff]
	return (38.0 + 22.0 * level) * 1.8 * float(t["hp"]) * float(d["hp"])


static func monster_damage(type_id: String, level: int, diff: String) -> float:
	var t: Dictionary = MONSTER_TYPES[type_id]
	var d: Dictionary = DIFFICULTIES[diff]
	return (3.0 + 1.65 * level) * 5.0 * float(t["dmg"]) * float(d["dmg"])


static func monster_armor(level: int) -> float:
	return 8.0 + 3.5 * level


static func exp_reward(type_id: String, level: int, diff: String) -> int:
	var t: Dictionary = MONSTER_TYPES[type_id]
	var d: Dictionary = DIFFICULTIES[diff]
	return int(round((7.0 + 4.2 * level) * float(t["exp"]) * float(d["reward"])))


static func gold_reward(type_id: String, level: int, diff: String) -> int:
	var t: Dictionary = MONSTER_TYPES[type_id]
	var d: Dictionary = DIFFICULTIES[diff]
	return int(round((2.0 + 1.3 * level) * float(t["gold"]) * float(d["reward"])))


static func weighted_pick(rng: RandomNumberGenerator, weights: Array) -> int:
	var total := 0.0
	for w in weights:
		total += float(w)
	if total <= 0.0:
		return 0
	var r := rng.randf() * total
	for i in weights.size():
		r -= float(weights[i])
		if r <= 0.0:
			return i
	return weights.size() - 1


static func roll_quality(rng: RandomNumberGenerator, weights: Array, shift: int) -> int:
	var q := weighted_pick(rng, weights)
	return clampi(q + shift, 0, 4)


static func monster_display_name(type_id: String, level: int) -> String:
	var base: String = MONSTER_TYPES[type_id]["name"]
	return "Lv.%d %s" % [level, base]


static func dungeon_title(d: Dictionary) -> String:
	return "%s Lv.%d" % [String(d.get("zone", "山谷")), int(d.get("level", 1))]


static func boss_title(level: int) -> String:
	return "区域首领 Lv.%d" % level
