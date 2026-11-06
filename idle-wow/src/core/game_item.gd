class_name GameItem
extends RefCounted

static var _uid_seq := 1

var uid: int = 0
var item_name: String = ""
var slot: String = "head"
var ilvl: int = 1
var quality: int = 0
var armor_type: String = ""
var weapon_type: String = ""
var weapon_min: float = 0.0
var weapon_max: float = 0.0
var stats: Dictionary = {}
var price: int = 10
var source: String = "drop"
var locked := false
var style := ""
var rune_stat := ""
var shop_factor := 1.0


static func create(rng: RandomNumberGenerator, level: int, q: int, class_id: String,
		slot_hint: String = "", source_tag: String = "drop") -> GameItem:
	var it := GameItem.new()
	it.uid = _uid_seq
	_uid_seq += 1
	it.ilvl = maxi(1, level)
	it.quality = clampi(q, 0, 4)
	it.source = source_tag
	it.slot = slot_hint if slot_hint != "" else _pick_slot(rng)
	var cls: Dictionary = Data.class_def(class_id)
	var qm: float = float(Data.QUALITIES[it.quality]["mult"])
	var kind: String = Data.SLOT_INFO.get(it.slot, {}).get("kind", "armor")
	var archetype := String(Data.character_def(class_id).get("archetype", class_id))
	var is_rune := kind == "rune"

	it.stats = {}
	var primary_total := _primary_budget(kind, it.ilvl)
	if primary_total > 0:
		var main_value := int(floor(float(primary_total) * 0.5))
		if source_tag != "starter":
			main_value = rng.randi_range(0, primary_total)
		it.stats[cls["main"]] = main_value
		it.stats["stamina"] = primary_total - main_value

	match kind:
		"armor":
			it.armor_type = String(cls["armor_types"][rng.randi_range(0, cls["armor_types"].size() - 1)])
			it.style = String(Data.ARMOR_STYLE_BY_TYPE.get(it.armor_type, "knight"))
			it.stats["armor"] = round((8.0 + it.ilvl * 5.5) * qm * _armor_type_scale(it.armor_type))
		"weapon":
			it.weapon_type = cls["weapon_types"][rng.randi_range(0, cls["weapon_types"].size() - 1)]
			it.style = String(Data.WEAPON_STYLE.get(it.weapon_type, "knight"))
			var scale := 1.0
			if cls["main"] == "strength":
				scale = 1.12
			elif cls["main"] == "agility":
				scale = 0.92
			else:
				scale = 1.02
			scale *= _weapon_type_scale(it.weapon_type)
			it.weapon_min = round((5.0 + it.ilvl * 1.8) * qm * scale)
			it.weapon_max = round((9.0 + it.ilvl * 2.9) * qm * scale)
		"offhand":
			it.weapon_type = cls["offhand_type"]
			it.style = String(Data.WEAPON_STYLE.get(it.weapon_type, "knight"))
			if it.weapon_type == "shield":
				it.stats["armor"] = round((10.0 + it.ilvl * 5.0) * qm)
		"jewel":
			it.armor_type = ""
			it.style = String(Data.JEWEL_STYLES[rng.randi_range(0, Data.JEWEL_STYLES.size() - 1)])
		"rune":
			it.armor_type = ""
			it.style = "rune"
			it.rune_stat = String(Data.RUNE_STATS[rng.randi_range(0, Data.RUNE_STATS.size() - 1)])
			it.stats[it.rune_stat] = round((3.0 + it.ilvl * 1.15) * qm)

	var affix_count: int = int(Data.QUALITIES[it.quality]["affixes"])
	var pool: Array = Data.RUNE_AFFIX_KEYS.duplicate() if is_rune else Data.AFFIX_KEYS.duplicate()
	var weights: Dictionary = Data.AFFIX_WEIGHTS.get(archetype, {}).duplicate()
	_style_weights(weights, it.style)
	var remaining := affix_count

	# 至少一条流派倾向词条
	var style_pool: Array = Data.STYLE_AFFIX_POOL.get(it.style, [])
	if remaining > 0 and not style_pool.is_empty():
		var style_keys: Array = []
		var style_weights: Array = []
		for key in style_pool:
			var w: float = float(weights.get(key, 0))
			if w > 0.0 and not it.stats.has(key):
				style_keys.append(key)
				style_weights.append(w)
		if not style_keys.is_empty():
			var pick: int = Data.weighted_pick(rng, style_weights)
			var key: String = style_keys[pick]
			_add_affix(it, key, rng, qm)
			pool.erase(key)
			remaining -= 1

	for i in remaining:
		var usable: Array = []
		var use_weights: Array = []
		for key in pool:
			if key == "extra_attack" and kind != "jewel" and kind != "rune":
				continue
			var tier := String(Data.AFFIX_TIERS.get(key, "A"))
			var w: float = float(weights.get(key, 0)) * float(Data.AFFIX_TIER_WEIGHT.get(tier, 1.0))
			if w > 0.0 and not it.stats.has(key):
				usable.append(key)
				use_weights.append(w)
		if usable.is_empty():
			break
		var pick: int = Data.weighted_pick(rng, use_weights)
		var key: String = usable[pick]
		_add_affix(it, key, rng, qm)
		pool.erase(key)

	it.item_name = _make_name(it, cls, rng)
	it.price = int(round((40.0 + it.ilvl * 24.0) * float(Data.QUALITY_PRICE_MULT[it.quality])))
	return it


static func _primary_budget(kind: String, ilvl: int) -> int:
	var base := 10.0
	var per_level := 2.0
	match kind:
		"armor":
			per_level = 2.2
		"offhand", "jewel":
			base = 8.0
			per_level = 1.8
		"rune":
			return 0
	return int(round(base + float(ilvl - 1) * per_level))


static func _weapon_type_scale(type_id: String) -> float:
	match type_id:
		"sword":
			return 0.94
		"mace":
			return 1.15
		"axe":
			return 1.06
		"staff":
			return 1.03
		"wand":
			return 0.92
		"codex":
			return 1.03
		"shortbow":
			return 0.90
		"longbow":
			return 1.15
		_:
			return 1.0


static func _armor_type_scale(type_id: String) -> float:
	match type_id:
		"plate":
			return 1.10
		"heavy":
			return 1.25
		"cloth":
			return 0.85
		"light":
			return 1.00
		"leather":
			return 0.95
		"mail":
			return 1.15
		_:
			return 1.0


static func _apply_style(it: GameItem, cls: Dictionary, magic: bool, qm: float) -> void:
	var ilvl := float(it.ilvl)
	var main: String = String(cls["main"])
	var kind: String = Data.SLOT_INFO.get(it.slot, {}).get("kind", "armor")
	var is_weapon := kind == "weapon" or kind == "offhand"
	match it.style:
		"knight":
			it.stats["parry"] = int(it.stats.get("parry", 0)) + int(round((1.5 + ilvl * 0.45) * qm))
			it.stats["block"] = int(it.stats.get("block", 0)) + int(round((1.2 + ilvl * 0.35) * qm))
			it.stats["stamina"] = int(it.stats.get("stamina", 0)) + int(round((1.5 + ilvl * 0.5) * qm))
			if kind == "armor":
				it.stats["armor"] = int(it.stats.get("armor", 0)) + int(round((7.0 + ilvl * 2.5) * qm))
			if is_weapon:
				it.stats["hp"] = int(it.stats.get("hp", 0)) + int(round((4.0 + ilvl * 2.0) * qm))
		"berserker":
			if magic:
				it.stats["spell_power"] = int(it.stats.get("spell_power", 0)) + int(round((2.0 + ilvl * 0.9) * qm))
			else:
				it.stats["attack_power"] = int(it.stats.get("attack_power", 0)) + int(round((2.0 + ilvl * 0.9) * qm))
			it.stats["crit_dmg"] = int(it.stats.get("crit_dmg", 0)) + int(round((3.0 + ilvl * 0.5) * qm))
			it.stats["pen"] = int(it.stats.get("pen", 0)) + int(round((1.0 + ilvl * 0.35) * qm))
			if kind == "armor":
				it.stats[main] = int(it.stats.get(main, 0)) + int(round((2.0 + ilvl * 0.7) * qm))
				it.stats["crit"] = int(it.stats.get("crit", 0)) + int(round((1.0 + ilvl * 0.25) * qm))
		"arcane":
			it.stats["spell_power"] = int(it.stats.get("spell_power", 0)) + int(round((2.5 + ilvl * 1.0) * qm))
			it.stats["crit"] = int(it.stats.get("crit", 0)) + int(round((1.2 + ilvl * 0.35) * qm))
			it.stats["crit_dmg"] = int(it.stats.get("crit_dmg", 0)) + int(round((2.0 + ilvl * 0.4) * qm))
			if kind == "armor":
				it.stats["intellect"] = int(it.stats.get("intellect", 0)) + int(round((1.5 + ilvl * 0.6) * qm))
		"moon":
			it.stats["hp"] = int(it.stats.get("hp", 0)) + int(round((7.0 + ilvl * 3.0) * qm))
			it.stats["stamina"] = int(it.stats.get("stamina", 0)) + int(round((1.0 + ilvl * 0.4) * qm))
			it.stats["lifesteal"] = int(it.stats.get("lifesteal", 0)) + int(round((1.0 + ilvl * 0.35) * qm))
			it.stats["hp_regen"] = int(it.stats.get("hp_regen", 0)) + int(round((1.0 + ilvl * 0.3) * qm))
			if kind == "armor":
				it.stats["armor"] = int(it.stats.get("armor", 0)) + int(round((3.0 + ilvl * 1.2) * qm))
		"swift":
			it.stats["crit"] = int(it.stats.get("crit", 0)) + int(round((1.0 + ilvl * 0.3) * qm))
			it.stats["haste"] = int(it.stats.get("haste", 0)) + int(round((1.3 + ilvl * 0.45) * qm))
			if kind == "armor":
				it.stats["agility"] = int(it.stats.get("agility", 0)) + int(round((1.2 + ilvl * 0.5) * qm))
		"hunt":
			it.stats["crit"] = int(it.stats.get("crit", 0)) + int(round((1.2 + ilvl * 0.35) * qm))
			it.stats["crit_dmg"] = int(it.stats.get("crit_dmg", 0)) + int(round((2.0 + ilvl * 0.45) * qm))
			it.stats["pen"] = int(it.stats.get("pen", 0)) + int(round((1.0 + ilvl * 0.3) * qm))
			if kind == "armor":
				it.stats["agility"] = int(it.stats.get("agility", 0)) + int(round((1.0 + ilvl * 0.4) * qm))
		"jewel_attack":
			if magic:
				it.stats["spell_power"] = int(it.stats.get("spell_power", 0)) + int(round((2.0 + ilvl * 0.8) * qm))
			else:
				it.stats["attack_power"] = int(it.stats.get("attack_power", 0)) + int(round((2.0 + ilvl * 0.8) * qm))
			it.stats["crit"] = int(it.stats.get("crit", 0)) + int(round((1.0 + ilvl * 0.25) * qm))
			it.stats["haste"] = int(it.stats.get("haste", 0)) + int(round((1.0 + ilvl * 0.3) * qm))
		"jewel_defense":
			it.stats["stamina"] = int(it.stats.get("stamina", 0)) + int(round((1.5 + ilvl * 0.5) * qm))
			it.stats["hp"] = int(it.stats.get("hp", 0)) + int(round((5.0 + ilvl * 2.0) * qm))
			it.stats["armor"] = int(it.stats.get("armor", 0)) + int(round((5.0 + ilvl * 2.0) * qm))
			it.stats["dodge"] = int(it.stats.get("dodge", 0)) + int(round((1.0 + ilvl * 0.3) * qm))


static func _style_weights(weights: Dictionary, style: String) -> void:
	var boosts := {}
	match style:
		"knight":
			boosts = {"parry": 16, "block": 14, "hp": 8, "lifesteal": 3}
		"berserker":
			boosts = {"attack_power": 10, "crit_dmg": 12, "pen": 7}
		"arcane":
			boosts = {"spell_power": 12, "crit": 8, "crit_dmg": 5}
		"moon":
			boosts = {"hp": 10, "lifesteal": 8, "hp_regen": 6}
		"swift":
			boosts = {"crit": 8, "haste": 9, "hit": 3}
		"hunt":
			boosts = {"crit": 5, "crit_dmg": 10, "pen": 8}
		"jewel_attack":
			boosts = {"crit": 8, "haste": 8, "pen": 4}
		"jewel_defense":
			boosts = {"dodge": 7, "parry": 7, "hp": 6}
	for key in boosts:
		weights[key] = int(weights.get(key, 0)) + int(boosts[key])


static func _add_affix(it: GameItem, key: String, rng: RandomNumberGenerator, qm: float) -> void:
	var base: float = float(Data.AFFIX_BASE[key])
	var scale: float = float(Data.AFFIX_SCALE[key])
	var tier := String(Data.AFFIX_TIERS.get(key, "A"))
	var value: float = (base + it.ilvl * scale) * qm \
		* float(Data.AFFIX_TIER_VALUE.get(tier, 1.0)) * rng.randf_range(0.85, 1.15)
	it.stats[key] = round(value)


static func create_dungeon_drop(rng: RandomNumberGenerator, level: int, q: int, class_id: String) -> GameItem:
	var slot := "rune"
	var cat := Data.weighted_pick(rng, Data.DROP_CATEGORY_WEIGHTS)
	if cat == 0:
		slot = Data.DROP_EQUIP_SLOTS[Data.weighted_pick(rng, Data.DROP_EQUIP_WEIGHTS)]
	elif cat == 1:
		slot = Data.DROP_JEWEL_SLOTS[Data.weighted_pick(rng, Data.DROP_JEWEL_WEIGHTS)]
	return create(rng, level, q, class_id, slot, "drop")


static func _pick_slot(rng: RandomNumberGenerator) -> String:
	var slots := ["head", "chest", "hands", "legs", "feet", "main", "off", "neck", "trinket", "ring", "rune"]
	var weights := [9, 9, 9, 9, 9, 13, 8, 7, 6, 9, 12]
	return slots[Data.weighted_pick(rng, weights)]


static func _make_name(it: GameItem, cls: Dictionary, rng: RandomNumberGenerator) -> String:
	var base := ""
	if it.slot == "rune":
		var rune_name := String(Data.AFFIX_KIND.get(it.rune_stat, {}).get("name", "战斗"))
		return rune_name + "符文"
	match it.slot:
		"head", "chest", "hands", "legs", "feet":
			base = String(Data.ARMOR_SLOT_NAMES.get(it.slot, "护甲"))
		"main":
			base = String(Data.WEAPON_NAMES.get(it.weapon_type, "武器"))
		"off":
			base = String(Data.OFFHAND_NAMES.get(it.weapon_type, "副手"))
		"neck":
			base = "项链"
		"trinket":
			base = "饰品"
		"ring":
			base = "戒指"
	if it.source == "starter":
		return "新手" + base
	var style_name := String(Data.STYLE_INFO.get(it.style, {}).get("name", ""))
	if style_name == "":
		return base
	if it.slot == "main" or it.slot == "off" or it.slot in ["neck", "trinket", "ring"]:
		return style_name + base
	var connector := ""
	if it.style == "knight" or it.style == "berserker":
		connector = "的"
	elif it.style == "arcane" or it.style == "moon":
		connector = "之"
	return style_name + connector + base


func style_title() -> String:
	if slot == "rune":
		if rune_stat == "":
			return ""
		return "战斗符文 · %s" % String(Data.AFFIX_KIND.get(rune_stat, {}).get("name", "战斗"))
	var info: Dictionary = Data.STYLE_INFO.get(style, {})
	if info.is_empty():
		return ""
	return "流派 · %s" % String(info.get("name", ""))


func style_desc() -> String:
	if slot == "rune":
		return "" if rune_stat == "" else "只提供战斗属性，不提供主属性"
	var info: Dictionary = Data.STYLE_INFO.get(style, {})
	return String(info.get("desc", ""))


func slot_name() -> String:
	return Data.slot_label(slot)


func quality_name() -> String:
	return Data.quality_name(quality)


func quality_color() -> Color:
	return Data.quality_color(quality)


func icon_key() -> String:
	if slot == "main" or slot == "off":
		match weapon_type:
			"codex":
				return "tome"
			"shortbow", "longbow":
				return "bow"
			_:
				return weapon_type
	match slot:
		"head": return "helmet"
		"chest": return "chest"
		"hands": return "gloves"
		"legs": return "legs"
		"feet": return "boots"
		"neck": return "necklace"
		"trinket": return "trinket"
		"ring": return "ring"
		"rune": return "rune"
	return "rune"


func display_lines() -> Array:
	var lines: Array = []
	for key in ["strength", "agility", "intellect", "stamina"]:
		if stats.has(key):
			lines.append("[属性] %s" % Data.fmt_primary(key, float(stats[key])))
	if stats.has("armor"):
		lines.append("[护甲] %d" % int(stats["armor"]))
	if weapon_max > 0.0:
		lines.append("[伤害] %d - %d" % [int(weapon_min), int(weapon_max)])
	for key in Data.AFFIX_KEYS:
		if stats.has(key):
			lines.append("[词条] %s" % Data.fmt_affix(key, float(stats[key])))
	return lines


func stat_total(key: String) -> float:
	return float(stats.get(key, 0))


func sell_value() -> int:
	return maxi(1, int(round((2.0 + ilvl * 0.8) * (1.0 + quality * 0.5))))


func shop_price_value() -> int:
	return maxi(1, int(round(float(price) * shop_factor)))


func sell_text() -> String:
	return "售出 %d 金币" % sell_value()


func score(class_id: String) -> float:
	var cls: Dictionary = Data.class_def(class_id)
	var s := 0.0
	s += stat_total(cls["main"]) * 2.2
	s += stat_total("stamina") * 1.1
	s += stat_total("attack_power") * 1.0
	s += stat_total("spell_power") * 1.0
	s += stat_total("crit") * 0.55
	s += stat_total("haste") * 0.50
	s += stat_total("hit") * 0.35
	s += stat_total("crit_dmg") * 0.40
	s += stat_total("vers") * 0.45
	s += stat_total("pen") * 0.40
	s += stat_total("lifesteal") * 0.35
	s += stat_total("hp_regen") * 0.30
	s += stat_total("extra_attack") * 0.40
	s += stat_total("dodge") * 0.30
	s += stat_total("parry") * 0.30
	s += stat_total("block") * 0.30
	s += stat_total("armor") * 0.10
	s += stat_total("hp") * 0.025
	s += (weapon_min + weapon_max) * 0.5 * 1.5
	return s


func to_dict() -> Dictionary:
	return {
		"uid": uid, "name": item_name, "slot": slot, "ilvl": ilvl, "q": quality,
		"at": armor_type, "wt": weapon_type, "wmin": weapon_min, "wmax": weapon_max,
		"stats": stats.duplicate(), "price": price, "src": source, "locked": locked,
		"style": style, "rune": rune_stat,
		"spf": shop_factor,
	}


static func from_dict(d: Dictionary) -> GameItem:
	var it := GameItem.new()
	it.uid = int(d.get("uid", 0))
	it.item_name = String(d.get("name", "物品"))
	it.slot = String(d.get("slot", "head"))
	it.ilvl = int(d.get("ilvl", 1))
	it.quality = int(d.get("q", 0))
	it.armor_type = String(d.get("at", ""))
	it.weapon_type = String(d.get("wt", ""))
	it.weapon_min = float(d.get("wmin", 0.0))
	it.weapon_max = float(d.get("wmax", 0.0))
	it.stats = {}
	for k in d.get("stats", {}):
		it.stats[k] = float(d["stats"][k])
	it.price = int(d.get("price", 10))
	it.source = String(d.get("src", "drop"))
	it.locked = bool(d.get("locked", false))
	var raw_style := String(d.get("style", ""))
	it.style = String(Data.LEGACY_STYLE_MAP.get(raw_style, raw_style))
	if it.style == "":
		if it.weapon_type != "":
			it.style = String(Data.WEAPON_STYLE.get(it.weapon_type, ""))
		elif it.armor_type != "":
			it.style = String(Data.ARMOR_STYLE_BY_TYPE.get(it.armor_type, ""))
	it.rune_stat = String(d.get("rune", ""))
	it.shop_factor = clampf(float(d.get("spf", 1.0)), 0.9, 1.1)
	return it
