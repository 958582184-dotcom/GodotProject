extends Node

signal stats_changed
signal inventory_changed
signal equipment_changed
signal gold_changed
signal exploration_changed
signal dungeons_changed
signal shop_changed
signal level_up(new_level)
signal toast(text, color)
signal busy_changed(is_busy)
signal auto_mode_changed(mode)
signal area_changed(index)
signal log_added(text, color)
signal metrics_changed

const AUTO_MODES := ["repeat", "next", "off"]

var rng := RandomNumberGenerator.new()

var class_id := ""
var level := 1
var exp := 0
var gold := 0
var materials := 0
var area_index := 0
var area_exploration: Array[float] = [0.0, 0.0, 0.0]
var area_clear_counts: Array[int] = [0, 0, 0]
var exploration: float:
	get:
		return area_exploration[clampi(area_index, 0, area_exploration.size() - 1)]
	set(value):
		area_exploration[clampi(area_index, 0, area_exploration.size() - 1)] = value
var area_clears: int:
	get:
		return area_clear_counts[clampi(area_index, 0, area_clear_counts.size() - 1)]
	set(value):
		area_clear_counts[clampi(area_index, 0, area_clear_counts.size() - 1)] = value
var log_history: Array = []
var inventory: Array = []
var equipment: Dictionary = {}
var dungeons: Array = []
var shop_stock: Array = []
var shop_free_left := Data.SHOP_FREE_PER_HOUR
var shop_reset_at := 0.0
var speed_mult := 1.0
var auto_mode := "next"
var auto_equip := true
var auto_sell := false
var current_dungeon: Dictionary = {}
var busy := false
var loaded := false
var test_items_added := false
var metrics := {
	"dungeons": 0, "deaths": 0, "kills": 0, "bosses": 0, "items": 0,
}

var _dirty := false
var _autosave_t := 0.0


func _ready() -> void:
	rng.randomize()
	inventory.resize(Data.INVENTORY_SIZE)
	_clear_equipment()
	loaded = load_game()
	if loaded:
		refresh_dungeons(false)
		if shop_reset_at <= 0.0:
			shop_reset_at = Time.get_unix_time_from_system() + 3600.0
		if shop_stock.is_empty():
			_generate_shop_stock()
	set_process(true)


func _process(delta: float) -> void:
	if not _dirty or class_id == "":
		return
	_autosave_t += delta
	if _autosave_t >= 12.0:
		save_game()


# ---------- 新游戏 / 存档 ----------

func has_save() -> bool:
	return FileAccess.file_exists(Data.SAVE_PATH)


func new_game(cid: String) -> void:
	class_id = cid
	level = 1
	exp = 0
	gold = 0
	materials = 0
	area_index = 0
	area_exploration = [0.0, 0.0, 0.0]
	area_clear_counts = [0, 0, 0]
	metrics = {"dungeons": 0, "deaths": 0, "kills": 0, "bosses": 0, "items": 0}
	log_history.clear()
	auto_mode = "next"
	auto_equip = true
	auto_sell = false
	current_dungeon = {}
	shop_free_left = Data.SHOP_FREE_PER_HOUR
	shop_reset_at = Time.get_unix_time_from_system() + 3600.0
	inventory.clear()
	inventory.resize(Data.INVENTORY_SIZE)
	_clear_equipment()

	var starter_slots := ["main", "chest", "legs", "feet"]
	for s in starter_slots:
		var it := GameItem.create(rng, 1, 0, cid, s, "starter")
		equipment[s] = it
	_grant_test_weapons()
	test_items_added = true

	refresh_dungeons(false)
	_generate_shop_stock()
	_dirty = true
	loaded = true
	_emit_all()
	toast.emit("欢迎，%s。按 M 打开副本选一个开始" % Data.character_name(cid), Color("#e0b45a"))


func _grant_test_weapons() -> void:
	if inventory.size() < Data.INVENTORY_SIZE:
		inventory.resize(Data.INVENTORY_SIZE)
	for q in 5:
		var it := GameItem.create(rng, maxi(1, level), q, class_id, "main", "test")
		for i in inventory.size():
			if inventory[i] == null:
				inventory[i] = it
				break
	inventory_changed.emit()


func _clear_equipment() -> void:
	equipment.clear()
	for key in Data.EQUIP_ORDER:
		equipment[key] = null


func save_game() -> void:
	if class_id == "":
		return
	var eq := {}
	for key in Data.EQUIP_ORDER:
		if equipment.get(key) != null:
			eq[key] = equipment[key].to_dict()
	var inv: Array = []
	for it in inventory:
		inv.append(null if it == null else it.to_dict())
	var payload := {
		"version": 3,
		"class": class_id,
		"level": level,
		"exp": exp,
		"gold": gold,
		"materials": materials,
		"area_index": area_index,
		"area_explore": area_exploration,
		"area_clears": area_clear_counts,
		"explore": exploration,
		"clears": area_clears,
		"metrics": metrics.duplicate(),
		"equip": eq,
		"inv": inv,
		"speed": speed_mult,
		"auto_mode": auto_mode,
		"auto_equip": auto_equip,
		"auto_sell": auto_sell,
		"test_items": test_items_added,
		"shop_free": shop_free_left,
		"shop_reset": shop_reset_at,
		"shop": _shop_to_array(),
	}
	var f := FileAccess.open(Data.SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(payload))
	f.close()
	_dirty = false
	_autosave_t = 0.0


func _shop_to_array() -> Array:
	var out: Array = []
	for it in shop_stock:
		out.append(null if it == null else it.to_dict())
	return out


func load_game() -> bool:
	if not FileAccess.file_exists(Data.SAVE_PATH):
		return false
	var f := FileAccess.open(Data.SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var text := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var d: Dictionary = parsed
	class_id = String(d.get("class", ""))
	if class_id == "" or not Data.CHARACTERS.has(class_id):
		return false
	level = int(d.get("level", 1))
	exp = int(d.get("exp", 0))
	gold = int(d.get("gold", 0))
	materials = int(d.get("materials", 0))
	area_index = clampi(int(d.get("area_index", 0)), 0, Data.AREAS.size() - 1)
	area_exploration = [0.0, 0.0, 0.0]
	area_clear_counts = [0, 0, 0]
	var saved_explore: Array = d.get("area_explore", [])
	for i in mini(saved_explore.size(), area_exploration.size()):
		area_exploration[i] = float(saved_explore[i])
	var saved_clears: Array = d.get("area_clears", [])
	for i in mini(saved_clears.size(), area_clear_counts.size()):
		area_clear_counts[i] = int(saved_clears[i])
	if saved_explore.is_empty():
		area_exploration[area_index] = float(d.get("explore", 0.0))
	if saved_clears.is_empty():
		area_clear_counts[area_index] = int(d.get("clears", 0))
	var saved_metrics: Dictionary = d.get("metrics", {})
	for key in metrics:
		metrics[key] = int(saved_metrics.get(key, 0))
	speed_mult = float(d.get("speed", 1.0))
	auto_mode = String(d.get("auto_mode", "next"))
	if not AUTO_MODES.has(auto_mode):
		auto_mode = "next"
	auto_equip = bool(d.get("auto_equip", true))
	auto_sell = bool(d.get("auto_sell", false))
	shop_free_left = clampi(int(d.get("shop_free", Data.SHOP_FREE_PER_HOUR)), 0, Data.SHOP_FREE_PER_HOUR)
	shop_reset_at = float(d.get("shop_reset", 0.0))
	shop_stock.clear()
	var saved_shop: Array = d.get("shop", [])
	for s in saved_shop:
		if s != null:
			shop_stock.append(GameItem.from_dict(s))
	_clear_equipment()
	var eq: Dictionary = d.get("equip", {})
	for key in eq:
		if equipment.has(key) and eq[key] != null:
			equipment[key] = GameItem.from_dict(eq[key])
	var inv: Array = d.get("inv", [])
	inventory.clear()
	inventory.resize(Data.INVENTORY_SIZE)
	for i in mini(inv.size(), Data.INVENTORY_SIZE):
		if inv[i] != null:
			inventory[i] = GameItem.from_dict(inv[i])
	test_items_added = bool(d.get("test_items", false))
	if not test_items_added:
		_grant_test_weapons()
		test_items_added = true
		_dirty = true
	loaded = true
	return true


func reset_all() -> void:
	class_id = ""
	loaded = false
	_dirty = false
	var abs_path := ProjectSettings.globalize_path(Data.SAVE_PATH)
	if FileAccess.file_exists(Data.SAVE_PATH):
		DirAccess.remove_absolute(abs_path)
	get_tree().reload_current_scene()


# ---------- 属性计算 ----------

func compute_stats() -> Dictionary:
	var s := {
		"strength": 0.0, "agility": 0.0, "intellect": 0.0, "stamina": 0.0,
		"armor": 0.0, "attack_power": 0.0, "spell_power": 0.0,
		"crit": 0.0, "haste": 0.0, "hit": 0.0, "dodge": 0.0, "parry": 0.0,
		"block": 0.0, "vers": 0.0, "lifesteal": 0.0, "pen": 0.0,
		"crit_dmg": 0.0, "hp": 0.0, "hp_regen": 0.0, "extra_attack": 0.0,
	}
	if class_id == "":
		return s
	var cls: Dictionary = Data.class_def(class_id)
	var base: Dictionary = cls["base"]
	var growth: Dictionary = cls["growth"]
	for key in base:
		s[key] += float(base[key]) + float(growth[key]) * float(level - 1)

	var weapon_min := 3.0
	var weapon_max := 6.0
	var main_item: GameItem = equipment.get("main")
	if main_item != null:
		weapon_min = main_item.weapon_min
		weapon_max = main_item.weapon_max

	var item_count := 0
	var ilvl_sum := 0.0
	for key in Data.EQUIP_ORDER:
		var it: GameItem = equipment.get(key)
		if it == null:
			continue
		item_count += 1
		ilvl_sum += it.ilvl
		for stat_key in it.stats:
			if s.has(stat_key):
				s[stat_key] += float(it.stats[stat_key])

	var main_key: String = cls["main"]
	var power := 0.0
	if cls["attack_type"] == "magic":
		power = float(s["spell_power"]) + float(s["intellect"]) * 2.35
	else:
		if main_key == "agility":
			power = float(s["attack_power"]) + float(s["agility"]) * 2.15 + float(s["strength"]) * 0.5
		else:
			power = float(s["attack_power"]) + float(s["strength"]) * 2.2 + float(s["agility"]) * 0.5

	var crit: float = 0.05 + float(s["crit"]) / 800.0
	if main_key == "agility":
		crit += float(s["agility"]) * 0.0015
	elif main_key == "intellect":
		crit += float(s["intellect"]) * 0.0010
	crit = clampf(crit, 0.02, 0.60)

	var crit_dmg: float = 1.5 + float(s["crit_dmg"]) / 1000.0
	var haste: float = float(s["haste"]) / 1000.0
	var ch: Dictionary = Data.character_def(class_id)
	power *= 1.0 + float(ch.get("power_pct", 0.0))
	crit = clampf(crit + float(ch.get("crit", 0.0)), 0.02, 0.60)
	haste += float(ch.get("haste", 0.0))
	var hit: float = clampf(0.95 + float(s["hit"]) / 2000.0, 0.50, 1.0)
	var dodge: float = 0.02 + float(s["dodge"]) / 1600.0
	var parry: float = 0.01 + float(s["parry"]) / 1600.0
	var block: float = float(s["block"]) / 1600.0
	if main_key == "agility":
		dodge += 0.02
	if main_key == "strength":
		parry += 0.02
		block += 0.02
	dodge = clampf(dodge, 0.0, 0.45)
	parry = clampf(parry, 0.0, 0.45)
	block = clampf(block, 0.0, 0.45)
	var vers: float = clampf(float(s["vers"]) / 1200.0, 0.0, 0.30)
	var lifesteal: float = clampf(float(s["lifesteal"]) / 1500.0 + float(ch.get("lifesteal", 0.0)), 0.0, 0.30)
	var pen: float = clampf(float(s["pen"]) / 1000.0 + float(ch.get("pen", 0.0)), 0.0, 0.65)
	var hp_regen: float = maxf(0.0, float(s["hp_regen"]))
	var extra_attack_pct: float = clampf(float(s["extra_attack"]) / 100.0, 0.0, 0.30)

	var avg_hit := (weapon_min + weapon_max) * 0.5
	var power_mult := 1.0 + power / 28.0
	var crit_mult: float = 1.0 + crit * (crit_dmg - 1.0)
	var interval: float = float(cls["attack_interval"])
	var dps: float = avg_hit * power_mult * crit_mult * hit * (1.0 + haste) / interval * (1.0 + vers)

	var stamina: float = float(s["stamina"])
	var hp: float = float(cls["base_hp"]) + stamina * 10.0 + level * 6.0 + float(s["hp"])
	hp *= 1.0 + float(ch.get("hp_pct", 0.0))
	var armor: float = 10.0 + level * 2.0 + float(s["armor"])
	armor *= 1.0 + float(ch.get("armor_pct", 0.0))
	var mit: float = armor / (armor + 90.0 + 12.0 * level)
	mit = clampf(mit, 0.0, 0.75)
	var ehp: float = hp / maxf(0.01, (1.0 - mit) * (1.0 - dodge) * (1.0 - parry) * (1.0 - block))

	var out := s.duplicate()
	out["ap"] = power if cls["attack_type"] == "physical" else 0.0
	out["sp"] = power if cls["attack_type"] == "magic" else 0.0
	out["power"] = power
	out["dps"] = dps
	out["hp_max"] = hp
	out["armor_total"] = armor
	out["mitigation"] = mit
	out["crit_pct"] = crit
	out["crit_dmg_pct"] = crit_dmg
	out["haste_pct"] = haste
	out["hit_pct"] = hit
	out["dodge_pct"] = dodge
	out["parry_pct"] = parry
	out["block_pct"] = block
	out["vers_pct"] = vers
	out["lifesteal_pct"] = lifesteal
	out["pen_pct"] = pen
	out["hp_regen"] = hp_regen
	out["extra_attack_pct"] = extra_attack_pct
	out["weapon_min"] = weapon_min
	out["weapon_max"] = weapon_max
	out["ilvl"] = int(round(ilvl_sum / maxf(1.0, float(item_count)))) if item_count > 0 else 1
	out["ehp"] = ehp
	out["interval"] = interval
	return out


func class_name_text() -> String:
	return Data.character_name(class_id) if class_id != "" else "—"


# ---------- 装备 / 背包 ----------

func add_item(item: GameItem) -> bool:
	for i in inventory.size():
		if inventory[i] == null:
			inventory[i] = item
			inventory_changed.emit()
			_dirty = true
			return true
	toast.emit("背包已满，装备未能拾取", Color("#ff7b72"))
	return false


func receive_drop(item: GameItem) -> void:
	if item == null or class_id == "":
		return
	var equipped := false
	if auto_equip:
		var key := _auto_equip_key(item)
		var old: GameItem = equipment.get(key)
		if old == null or (not old.locked and item.score(class_id) > old.score(class_id) + 0.001):
			equipment[key] = item
			equipped = true
			_dirty = true
			equipment_changed.emit()
			stats_changed.emit()
			toast.emit("自动装备 %s" % item.item_name, item.quality_color())
			if old != null:
				if auto_sell and not old.locked:
					var old_gold := old.sell_value()
					gold += old_gold
					gold_changed.emit()
					toast.emit("自动出售替换下的 %s  +%d 金币" % [old.item_name, old_gold], Color("#e0b45a"))
				elif not add_item(old):
					var old_gold2 := old.sell_value()
					gold += old_gold2
					gold_changed.emit()
					toast.emit("背包已满，替换下的装备已自动出售  +%d 金币" % old_gold2, Color("#e0b45a"))
	if not equipped:
		if auto_sell:
			var value := item.sell_value()
			gold += value
			gold_changed.emit()
			_dirty = true
			toast.emit("自动出售 %s  +%d 金币" % [item.item_name, value], Color("#e0b45a"))
		else:
			if add_item(item):
				toast.emit("拾取 %s（%s）" % [item.item_name, item.quality_name()], item.quality_color())


func _auto_equip_key(item: GameItem) -> String:
	match item.slot:
		"ring":
			for key in ["ring1", "ring2"]:
				if equipment.get(key) == null:
					return key
			var r1: GameItem = equipment["ring1"]
			var r2: GameItem = equipment["ring2"]
			return "ring1" if r1.score(class_id) <= r2.score(class_id) else "ring2"
		"rune":
			for key in ["rune1", "rune2", "rune3"]:
				if equipment.get(key) == null:
					return key
			var weakest := "rune1"
			var weakest_score := 1e20
			for key in ["rune1", "rune2", "rune3"]:
				var it: GameItem = equipment[key]
				if it.score(class_id) < weakest_score:
					weakest_score = it.score(class_id)
					weakest = key
			return weakest
		_:
			return item.slot


func set_auto_equip(value: bool) -> void:
	auto_equip = value
	_dirty = true
	toast.emit("自动替换装备：%s" % ("开" if value else "关"), Color("#c8d2df"))


func set_auto_sell(value: bool) -> void:
	auto_sell = value
	_dirty = true
	toast.emit("自动出售装备：%s" % ("开" if value else "关"), Color("#c8d2df"))


func set_auto_mode(mode: String) -> void:
	if not AUTO_MODES.has(mode):
		return
	auto_mode = mode
	_dirty = true
	toast.emit("自动副本：%s" % auto_mode_label(), Color("#c8d2df"))
	auto_mode_changed.emit(mode)


func auto_mode_label() -> String:
	match auto_mode:
		"repeat":
			return "重复当前"
		"off":
			return "关闭"
		_:
			return "下一关"


func current_area() -> Dictionary:
	return Data.area_def(area_index)


func area_unlocked(index: int) -> bool:
	return Data.area_unlocked(index, level)


func set_area(index: int) -> bool:
	if index < 0 or index >= Data.AREAS.size():
		return false
	if index == area_index:
		return false
	if not area_unlocked(index):
		var need_level := int(Data.AREAS[index]["min_level"])
		toast.emit("需要 Lv.%d 解锁 %s" % [need_level, String(Data.AREAS[index]["name"])], Color("#ff7b72"))
		return false
	area_index = index
	current_dungeon = {}
	refresh_dungeons()
	area_changed.emit(area_index)
	exploration_changed.emit()
	_dirty = true
	toast.emit("进入 %s" % String(current_area()["name"]), Color("#e0b45a"))
	return true


func push_log(text: String, color: Color = Color("#c8d2df")) -> void:
	log_history.append({"text": text, "color": color})
	log_added.emit(text, color)


func clear_logs() -> void:
	log_history.clear()


func inventory_count() -> int:
	var n := 0
	for it in inventory:
		if it != null:
			n += 1
	return n


func find_equip_key(item: GameItem) -> String:
	match item.slot:
		"ring":
			for key in ["ring1", "ring2"]:
				if equipment.get(key) == null:
					return key
			return "ring1"
		"rune":
			for key in ["rune1", "rune2", "rune3"]:
				if equipment.get(key) == null:
					return key
			return "rune1"
		_:
			return item.slot


func compare_item(item: GameItem) -> GameItem:
	if item == null:
		return null
	var key := find_equip_key(item)
	if item.slot == "ring":
		if equipment.get("ring1") != null:
			return equipment["ring1"]
		if equipment.get("ring2") != null:
			return equipment["ring2"]
	if item.slot == "rune":
		for k in ["rune1", "rune2", "rune3"]:
			if equipment.get(k) != null:
				return equipment[k]
	return equipment.get(key)


func equip_item(item: GameItem) -> void:
	if item == null or class_id == "":
		return
	var idx := -1
	for i in inventory.size():
		if inventory[i] == item:
			idx = i
			break
	if idx < 0:
		return
	var key := find_equip_key(item)
	var old: GameItem = equipment.get(key)
	inventory[idx] = null
	equipment[key] = item
	if old != null:
		add_item(old)
	equipment_changed.emit()
	inventory_changed.emit()
	stats_changed.emit()
	_dirty = true
	toast.emit("已装备 %s" % item.item_name, item.quality_color())


func unequip(key: String) -> void:
	var it: GameItem = equipment.get(key)
	if it == null:
		return
	if inventory_count() >= Data.INVENTORY_SIZE:
		toast.emit("背包已满", Color("#ff7b72"))
		return
	equipment[key] = null
	add_item(it)
	equipment_changed.emit()
	inventory_changed.emit()
	stats_changed.emit()
	_dirty = true


func can_equip_to(item: GameItem, key: String) -> bool:
	if item == null:
		return false
	match item.slot:
		"ring":
			return key == "ring1" or key == "ring2"
		"rune":
			return key in ["rune1", "rune2", "rune3"]
		_:
			return key == item.slot


func equip_at(item: GameItem, index: int, key: String) -> bool:
	if item == null or index < 0 or index >= inventory.size() or inventory[index] != item:
		return false
	if not can_equip_to(item, key):
		toast.emit("这件装备不能放入该栏位", Color("#ff7b72"))
		return false
	var old: GameItem = equipment.get(key)
	inventory[index] = old
	equipment[key] = item
	equipment_changed.emit()
	inventory_changed.emit()
	stats_changed.emit()
	_dirty = true
	toast.emit("已装备 %s" % item.item_name, item.quality_color())
	return true


func unequip_to(key: String, index: int) -> bool:
	var it: GameItem = equipment.get(key)
	if it == null or index < 0 or index >= inventory.size():
		return false
	var other: GameItem = inventory[index]
	if other != null and not can_equip_to(other, key):
		toast.emit("目标物品不能放入该装备栏", Color("#ff7b72"))
		return false
	equipment[key] = other
	inventory[index] = it
	equipment_changed.emit()
	inventory_changed.emit()
	stats_changed.emit()
	_dirty = true
	toast.emit("已卸下 %s" % it.item_name, it.quality_color())
	return true


func swap_equipment_slots(from_key: String, to_key: String) -> bool:
	if from_key == to_key:
		return false
	var a: GameItem = equipment.get(from_key)
	var b: GameItem = equipment.get(to_key)
	if a == null or b == null:
		return false
	if not can_equip_to(a, to_key) or not can_equip_to(b, from_key):
		toast.emit("这两件装备不能交换栏位", Color("#ff7b72"))
		return false
	equipment[from_key] = b
	equipment[to_key] = a
	equipment_changed.emit()
	stats_changed.emit()
	_dirty = true
	return true


func move_inventory(from_index: int, to_index: int) -> bool:
	if from_index < 0 or to_index < 0 or from_index >= inventory.size() or to_index >= inventory.size():
		return false
	if from_index == to_index:
		return false
	var tmp: GameItem = inventory[from_index]
	inventory[from_index] = inventory[to_index]
	inventory[to_index] = tmp
	inventory_changed.emit()
	_dirty = true
	return true


func sell_item(item: GameItem) -> void:
	if item == null:
		return
	if item.locked:
		toast.emit("%s 已锁定，先解锁再出售" % item.item_name, Color("#ff7b72"))
		return
	var idx := -1
	for i in inventory.size():
		if inventory[i] == item:
			idx = i
			break
	if idx < 0:
		return
	var value := item.sell_value()
	inventory[idx] = null
	gold += value
	inventory_changed.emit()
	gold_changed.emit()
	_dirty = true
	toast.emit("出售 %s  +%d 金币" % [item.item_name, value], Color("#e0b45a"))


func dismantle_item(item: GameItem) -> void:
	if item == null:
		return
	if item.locked:
		toast.emit("%s 已锁定，先解锁再分解" % item.item_name, Color("#ff7b72"))
		return
	var idx := -1
	for i in inventory.size():
		if inventory[i] == item:
			idx = i
			break
	if idx < 0:
		return
	var gain := maxi(1, int(round(item.sell_value() * 0.5)))
	inventory[idx] = null
	materials += gain
	inventory_changed.emit()
	_dirty = true
	toast.emit("分解 %s  +%d 材料" % [item.item_name, gain], Color("#8fd3c7"))


func toggle_lock(item: GameItem) -> void:
	if item == null:
		return
	item.locked = not item.locked
	inventory_changed.emit()
	_dirty = true
	toast.emit("%s：%s" % [item.item_name, "已锁定" if item.locked else "已解锁"],
		UiKit.COL_GOLD if item.locked else UiKit.COL_MUTED)


func sort_inventory() -> void:
	var items: Array = []
	for it in inventory:
		if it != null:
			items.append(it)
	items.sort_custom(func(a, b):
		if a.quality != b.quality:
			return a.quality > b.quality
		if a.ilvl != b.ilvl:
			return a.ilvl > b.ilvl
		return a.slot < b.slot)
	inventory.clear()
	for it in items:
		inventory.append(it)
	while inventory.size() < Data.INVENTORY_SIZE:
		inventory.append(null)
	inventory_changed.emit()


# ---------- 经验 / 掉落 ----------

func add_exp(amount: int) -> void:
	if amount <= 0:
		return
	exp += amount
	var leveled := false
	while level < Data.MAX_LEVEL:
		var need := Data.exp_to_next(level)
		if exp < need:
			break
		exp -= need
		level += 1
		leveled = true
	if leveled:
		level_up.emit(level)
		toast.emit("升级！现在是 Lv.%d" % level, Color("#ffd76a"))
		stats_changed.emit()
	_dirty = true


func add_gold(amount: int) -> void:
	gold = maxi(0, gold + amount)
	gold_changed.emit()
	_dirty = true


func add_exploration(amount: float) -> void:
	if amount <= 0.0:
		return
	var was_ready := exploration >= 100.0
	exploration = clampf(exploration + amount, 0.0, 100.0)
	exploration_changed.emit()
	_dirty = true
	if not was_ready and exploration >= 100.0:
		toast.emit("区域首领已出现，自动副本暂停", Color("#ff6b5e"))


func boss_ready() -> bool:
	return exploration >= 100.0


func bump_metric(key: String, amount: int = 1) -> void:
	if not metrics.has(key):
		return
	metrics[key] = int(metrics[key]) + amount
	metrics_changed.emit()
	_dirty = true


func grant_kill(mon: Dictionary, diff: String) -> Dictionary:
	var type_id: String = mon["type"]
	var mon_level: int = mon["level"]
	var t: Dictionary = Data.MONSTER_TYPES[type_id]
	var d: Dictionary = Data.DIFFICULTIES[diff]
	var exp_gain := int(round(float(Data.exp_reward(type_id, mon_level, diff)) * 0.5))
	if mon_level < level:
		exp_gain = int(round(float(exp_gain) * 0.3))
	var gold_gain := int(round(Data.gold_reward(type_id, mon_level, diff) * rng.randf_range(0.85, 1.2)))
	bump_metric("kills")
	if type_id == "boss":
		bump_metric("bosses")

	if type_id == "boss":
		add_gold(gold_gain + 150)
		add_exp(exp_gain + 100)
		exploration = 0.0
		area_clears += 1
		exploration_changed.emit()
		toast.emit("区域首领被击败，探索度已重置", Color("#ff9f43"))
	else:
		add_gold(gold_gain)
		add_exp(exp_gain)
	_dirty = true
	return {"exp": exp_gain, "gold": gold_gain, "drops": [], "explore": 0.0}


func grant_dungeon_loot(level: int) -> Array:
	var count := Data.weighted_pick(rng, Data.DUNGEON_DROP_COUNT_WEIGHTS)
	var drops: Array = []
	for i in count:
		var q := Data.roll_quality(rng, Data.DUNGEON_QUALITY_WEIGHTS, 0)
		var drop := GameItem.create_dungeon_drop(rng, level, q, class_id)
		receive_drop(drop)
		drops.append(drop)
	if count > 0:
		bump_metric("items", count)
	return drops


func build_battle(mon: Dictionary, diff: String, start_hp: float = -1.0) -> Dictionary:
	var s := compute_stats()
	var mon_level: int = mon["level"]
	var type_id: String = mon["type"]
	var total_hp := Data.monster_hp(type_id, mon_level, diff)
	var mon_dmg := Data.monster_damage(type_id, mon_level, diff)
	var level_gap := clampi(mon_level - level, 0, 6)
	total_hp *= 1.0 + 0.08 * float(level_gap)
	mon_dmg *= 1.0 + 0.06 * float(level_gap)
	var mon_armor := Data.monster_armor(mon_level)
	var eff_armor := mon_armor * (1.0 - float(s["pen_pct"]))
	var armor_mit := eff_armor / (eff_armor + 90.0 + 12.0 * mon_level)
	armor_mit = clampf(armor_mit, 0.0, 0.75)
	var player_hit := maxf(1.0, float(s["dps"]) * float(s["interval"]) * (1.0 - armor_mit))

	var player_armor: float = float(s["armor_total"])
	var pmit := player_armor / (player_armor + 90.0 + 12.0 * mon_level)
	pmit = clampf(pmit, 0.0, 0.75)
	var avoid := (1.0 - pmit) * (1.0 - float(s["dodge_pct"])) \
		* (1.0 - float(s["parry_pct"])) * (1.0 - float(s["block_pct"]))
	var monster_hit := maxf(1.0, mon_dmg * avoid)

	var main_item: GameItem = equipment.get("main")
	var school := String(main_item.style) if main_item != null else ""
	school = String(Data.LEGACY_STYLE_MAP.get(school, school))
	if school == "":
		school = "knight" if class_id in ["warrior", "warden"] else ("arcane" if class_id in ["mage", "oracle"] else "swift")
	var arcane_chance := 0.0
	if school == "arcane" and main_item != null:
		arcane_chance = clampf(0.03 + 0.003 * float(main_item.ilvl) + 0.012 * float(main_item.quality) \
			+ float(s["extra_attack_pct"]), 0.0, 0.50)

	var hp_max: float = float(s["hp_max"])
	var player_hp := hp_max if start_hp < 0.0 else clampf(start_hp, 0.0, hp_max)
	var player_shield := 0.0
	var attack_count := 0
	var monster_hp := total_hp
	var turns: Array = []
	var guard := 0
	while monster_hp > 0.0 and player_hp > 0.0 and guard < 120:
		guard += 1
		attack_count += 1
		var dmg := maxi(1, int(round(player_hit * rng.randf_range(0.90, 1.10))))
		var note := ""
		if school == "swift" and attack_count % 3 == 0:
			var extra := maxi(1, int(round(float(dmg) * 0.6)))
			dmg += extra
			note = "疾风额外伤害 +%d" % extra
		if school == "arcane" and arcane_chance > 0.0 and rng.randf() < arcane_chance:
			var echo := maxi(1, int(round(float(player_hit) * rng.randf_range(0.90, 1.10))))
			dmg += echo
			note = "奥术回响 +%d" % echo
		dmg = mini(dmg, int(ceil(monster_hp)))
		monster_hp = maxf(0.0, monster_hp - dmg)
		player_hp = minf(hp_max, player_hp + float(dmg) * float(s["lifesteal_pct"]) + float(s["hp_regen"]))
		if school == "moon":
			var gained := float(dmg) * 0.06
			player_shield = minf(hp_max * 0.20, player_shield + gained)
			if note == "":
				note = "月辉护盾 +%d" % int(round(gained))
		turns.append({
			"side": "player", "dmg": dmg,
			"monster_hp": int(ceil(monster_hp)), "player_hp": int(ceil(player_hp)),
			"shield": int(ceil(player_shield)), "note": note,
		})
		if monster_hp <= 0.0:
			break
		var mdmg := maxi(1, int(round(monster_hit * rng.randf_range(0.90, 1.10))))
		var absorbed := mini(mdmg, int(floor(player_shield)))
		player_shield -= float(absorbed)
		player_hp = maxf(0.0, player_hp - float(mdmg - absorbed))
		turns.append({
			"side": "monster", "dmg": mdmg, "absorbed": absorbed,
			"monster_hp": int(ceil(monster_hp)), "player_hp": int(ceil(player_hp)),
			"shield": int(ceil(player_shield)),
		})

	return {
		"win": monster_hp <= 0.0 and player_hp > 0.0,
		"turns": turns,
		"monster_hp_total": int(ceil(total_hp)),
		"monster_hp_left": int(ceil(monster_hp)),
		"player_hp_max": int(ceil(hp_max)),
		"player_hp_start": int(ceil(player_hp)),
		"player_hp_left": int(ceil(player_hp)),
		"player_shield_left": int(ceil(player_shield)),
		"school": school,
		"rounds": guard,
		"player_hit": player_hit,
		"monster_hit": monster_hit,
	}


# ---------- 副本 ----------

func refresh_dungeons(emit_signal: bool = true) -> void:
	dungeons.clear()
	var area := current_area()
	var count := rng.randi_range(5, 10)
	for i in count:
		dungeons.append(_roll_dungeon())
	# 保证至少一个低等级的普通本，避免新角色无本可刷
	var rng_range: Vector2i = Data.dungeon_level_range(level, area)
	var has_easy := false
	for d in dungeons:
		if int(d["level"]) <= level + 1 and String(d["difficulty"]) == "normal":
			has_easy = true
			break
	if not has_easy and not dungeons.is_empty():
		var easy := _roll_dungeon()
		easy["level"] = rng_range.x
		easy["difficulty"] = "normal"
		dungeons[dungeons.size() - 1] = easy
	dungeons.sort_custom(func(a, b):
		if int(a["level"]) != int(b["level"]):
			return int(a["level"]) < int(b["level"])
		return Data.DIFF_ORDER.find(String(a["difficulty"])) < Data.DIFF_ORDER.find(String(b["difficulty"])))
	if emit_signal:
		dungeons_changed.emit()
	_dirty = true


func _roll_dungeon() -> Dictionary:
	var area := current_area()
	var rng_range: Vector2i = Data.dungeon_level_range(level, area)
	var weights: Array = []
	for lv in range(rng_range.x, rng_range.y + 1):
		weights.append(float(rng_range.y - lv + 4))
	var dlevel: int = rng_range.x + Data.weighted_pick(rng, weights)
	var diff: String = Data.DIFF_ORDER[Data.weighted_pick(rng, [68, 25, 7])]
	return {
		"uid": rng.randi(),
		"zone": String(area["name"]),
		"level": dlevel,
		"difficulty": diff,
		"kind": "normal",
		"monsters": ["normal", "normal", "normal", "elite"],
	}


func make_boss_dungeon() -> Dictionary:
	var area := current_area()
	var boss_level := clampi(level, int(area["min_level"]), int(area["max_level"]))
	return {
		"uid": rng.randi(),
		"zone": "区域首领",
		"level": boss_level,
		"difficulty": "elite",
		"kind": "boss",
		"monsters": ["boss"],
	}


func next_dungeon() -> Dictionary:
	if dungeons.is_empty():
		refresh_dungeons(false)
	if dungeons.is_empty():
		return {}
	if current_dungeon.is_empty() or String(current_dungeon.get("kind", "normal")) == "boss":
		return dungeons[0]
	var cur_uid: int = int(current_dungeon.get("uid", -1))
	for i in dungeons.size():
		if int(dungeons[i].get("uid", -2)) == cur_uid:
			if i + 1 < dungeons.size():
				return dungeons[i + 1]
			refresh_dungeons(false)
			return dungeons[0] if not dungeons.is_empty() else {}
	refresh_dungeons(false)
	return dungeons[0] if not dungeons.is_empty() else {}


func repeat_dungeon() -> Dictionary:
	if current_dungeon.is_empty():
		return next_level_dungeon()
	var d := current_dungeon.duplicate(true)
	d["uid"] = rng.randi()
	return d


func next_level_dungeon() -> Dictionary:
	var lv := level + 1
	var diff := "normal"
	if not current_dungeon.is_empty():
		lv = int(current_dungeon.get("level", level)) + 1
		diff = String(current_dungeon.get("difficulty", "normal"))
	lv = clampi(lv, 1, Data.CONTENT_MAX_LEVEL)
	var area := current_area()
	return {
		"uid": rng.randi(),
		"zone": String(area["name"]),
		"level": lv,
		"difficulty": diff,
		"kind": "normal",
		"monsters": ["normal", "normal", "normal", "elite"],
	}


func pick_auto_dungeon() -> Dictionary:
	match auto_mode:
		"repeat":
			return repeat_dungeon()
		"next":
			return next_level_dungeon()
		_:
			return {}


func exp_to_next() -> int:
	return Data.exp_to_next(level)


# ---------- 商店 ----------

func _check_shop_reset() -> void:
	var now := Time.get_unix_time_from_system()
	if shop_reset_at <= 0.0:
		shop_reset_at = now + 3600.0
	if now >= shop_reset_at:
		shop_free_left = Data.SHOP_FREE_PER_HOUR
		shop_reset_at = now + 3600.0


func _generate_shop_stock() -> void:
	shop_stock.clear()
	for i in Data.SHOP_STOCK_SIZE:
		var lvl := clampi(level + rng.randi_range(-Data.SHOP_LEVEL_RANGE, Data.SHOP_LEVEL_RANGE),
			1, Data.CONTENT_MAX_LEVEL)
		var q := Data.roll_quality(rng, Data.SHOP_QUALITY_WEIGHTS, 0)
		var it := GameItem.create(rng, lvl, q, class_id, "", "shop")
		it.shop_factor = 1.0 + rng.randf_range(-0.10, 0.10)
		shop_stock.append(it)


func refresh_shop(consume_free: bool = true) -> bool:
	_check_shop_reset()
	var used_paid := false
	if consume_free:
		if shop_free_left > 0:
			shop_free_left -= 1
		else:
			if gold < Data.SHOP_PAID_COST:
				toast.emit("金币不足，刷新需要 %d 金币" % Data.SHOP_PAID_COST, Color("#ff7b72"))
				return false
			gold -= Data.SHOP_PAID_COST
			gold_changed.emit()
			used_paid = true
	_generate_shop_stock()
	_dirty = true
	shop_changed.emit()
	if consume_free:
		if used_paid:
			toast.emit("商店已刷新（花费 %d 金币）" % Data.SHOP_PAID_COST, Color("#e0b45a"))
		else:
			toast.emit("商店已刷新（免费，剩余 %d 次）" % shop_free_left, Color("#e0b45a"))
	return true


func shop_free_count() -> int:
	_check_shop_reset()
	return shop_free_left


func shop_refresh_text() -> String:
	_check_shop_reset()
	if shop_free_left > 0:
		return "免费刷新（%d/%d）" % [shop_free_left, Data.SHOP_FREE_PER_HOUR]
	return "刷新货架（%d 金币）" % Data.SHOP_PAID_COST


func shop_reset_seconds() -> int:
	_check_shop_reset()
	return maxi(0, int(shop_reset_at - Time.get_unix_time_from_system()))


func buy_shop(index: int) -> void:
	if index < 0 or index >= shop_stock.size():
		return
	var it: GameItem = shop_stock[index]
	if it == null:
		return
	var cost := it.shop_price_value()
	if gold < cost:
		toast.emit("金币不足", Color("#ff7b72"))
		return
	if inventory_count() >= Data.INVENTORY_SIZE:
		toast.emit("背包已满", Color("#ff7b72"))
		return
	gold -= cost
	gold_changed.emit()
	add_item(it)
	shop_stock.remove_at(index)
	shop_changed.emit()
	_dirty = true
	toast.emit("购入 %s（%d 金币）" % [it.item_name, cost], it.quality_color())


# ---------- 其它 ----------

func set_busy(value: bool) -> void:
	busy = value
	busy_changed.emit(value)


func _emit_all() -> void:
	stats_changed.emit()
	inventory_changed.emit()
	equipment_changed.emit()
	gold_changed.emit()
	exploration_changed.emit()
	dungeons_changed.emit()
	shop_changed.emit()
	area_changed.emit(area_index)


func debug_seed() -> void:
	class_id = "archer"
	level = 12
	exp = 640
	gold = 2340
	materials = 0
	area_index = 0
	area_exploration = [46.0, 0.0, 0.0]
	area_clear_counts = [0, 0, 0]
	metrics = {"dungeons": 24, "deaths": 3, "kills": 186, "bosses": 4, "items": 37}
	auto_mode = "off"
	auto_equip = true
	auto_sell = false
	current_dungeon = {}
	shop_free_left = Data.SHOP_FREE_PER_HOUR
	shop_reset_at = Time.get_unix_time_from_system() + 3600.0
	_clear_equipment()
	inventory.clear()
	inventory.resize(Data.INVENTORY_SIZE)
	test_items_added = true
	_grant_test_weapons()
	var slots := ["head", "chest", "hands", "legs", "feet", "main", "off", "neck", "ring", "rune"]
	for i in 9:
		var slot: String = slots[i % slots.size()]
		var q := 1 + (i % 4)
		var it := GameItem.create(rng, 8 + (i % 6), q, class_id, slot, "debug")
		equipment[slot if slot != "ring" and slot != "rune" else ("ring1" if slot == "ring" else "rune1")] = it
	for i in 34:
		var it2 := GameItem.create(rng, 6 + (i % 10), i % 5, class_id)
		for j in inventory.size():
			if inventory[j] == null:
				inventory[j] = it2
				break
	loaded = true
	refresh_dungeons(false)
	_generate_shop_stock()
	_emit_all()


func debug_report() -> void:
	print("=== 属性 ===")
	for cid in Data.CLASS_ORDER:
		class_id = cid
		for lv in [1, 5, 10, 15, 20]:
			level = lv
			_clear_equipment()
			for s in ["main", "chest", "legs", "feet"]:
				equipment[s] = GameItem.create(rng, lv, 1, cid, s, "test")
			var st := compute_stats()
			print("%s Lv.%d  dps=%.1f hp=%.0f ehp=%.0f ilvl=%d" % [
				cid, lv, st["dps"], st["hp_max"], st["ehp"], st["ilvl"]])
	print("=== 胜率 ===")
	for cid in Data.CLASS_ORDER:
		class_id = cid
		for lv in [5, 10, 15]:
			level = lv
			_clear_equipment()
			for s in ["main", "chest", "legs", "feet"]:
				equipment[s] = GameItem.create(rng, lv, 2, cid, s, "test")
			var line := "%s Lv.%d" % [cid, lv]
			for diff in Data.DIFF_ORDER:
				for dl in [lv - 3, lv, lv + 3]:
					var mon := {"level": clampi(dl, 1, 20), "type": "elite"}
					var res := build_battle(mon, diff)
					line += "  %s@%d:%s(%d回合/剩%d血)" % [diff, dl, "W" if res["win"] else "L",
						res["rounds"], res["player_hp_left"]]
			print(line)
