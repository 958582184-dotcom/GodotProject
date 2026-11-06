class_name BackpackWindow
extends BaseWindow

const EQ_CELL := 50
const INV_CELL := 36
const EQ_POS := {
	"head": Vector2(140, 0),
	"neck": Vector2(140, 56),
	"main": Vector2(50, 112),
	"chest": Vector2(140, 112),
	"off": Vector2(230, 112),
	"hands": Vector2(50, 168),
	"legs": Vector2(140, 168),
	"ring1": Vector2(230, 168),
	"trinket": Vector2(50, 224),
	"feet": Vector2(140, 280),
	"ring2": Vector2(230, 224),
	"rune1": Vector2(300, 112),
	"rune2": Vector2(300, 168),
	"rune3": Vector2(300, 224),
}

var _tip: ItemTooltip
var _menu: PopupMenu
var _menu_item: GameItem
var _stats_open := true


func _init() -> void:
	title = "背包"
	window_size = Vector2(800, 600)


func _after_build() -> void:
	_tip = ItemTooltip.new()
	add_child(_tip)
	_menu = PopupMenu.new()
	_menu.id_pressed.connect(_on_menu_id)
	add_child(_menu)


func _refresh_body(box: VBoxContainer) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()
	for c in _footer_left.get_children():
		_footer_left.remove_child(c)
		c.queue_free()
	if _tip != null:
		_tip.hide_tip()
	if _menu != null:
		_menu.hide()

	_footer_left.add_child(UiKit.label("金币 %s" % UiKit.num(Game.gold), 11, UiKit.COL_GOLD))
	_footer_left.add_child(UiKit.label("材料 %d" % Game.materials, 11, Color("#8fd3c7")))

	var title_row := HBoxContainer.new()
	title_row.add_child(UiKit.label("背包", 15, UiKit.COL_GOLD))
	title_row.add_child(UiKit.spacer())
	box.add_child(title_row)

	var main := HBoxContainer.new()
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation", 12)
	box.add_child(main)

	# 左：装备 + 背包
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(350, 0)
	left.add_theme_constant_override("separation", 6)
	main.add_child(left)

	var doll := PaperDoll.new()
	doll.custom_minimum_size = Vector2(350, 340)
	left.add_child(doll)
	var equip_lv := UiKit.label("装备等级 %d" % int(Game.compute_stats().get("ilvl", 1)), 10, UiKit.COL_GOLD)
	equip_lv.position = Vector2(6, 4)
	doll.add_child(equip_lv)
	var toggle := UiKit.button("◀" if _stats_open else "▶", 12)
	toggle.position = Vector2(322, 4)
	toggle.custom_minimum_size = Vector2(24, 24)
	toggle.tooltip_text = "收起属性" if _stats_open else "展开属性"
	toggle.add_theme_color_override("font_color", UiKit.COL_GOLD)
	toggle.add_theme_stylebox_override("normal", UiKit.stylebox(Color(0.10, 0.12, 0.16, 0.9), Color(0.30, 0.26, 0.20), 1, 2))
	toggle.add_theme_stylebox_override("hover", UiKit.stylebox(Color(0.16, 0.14, 0.11, 0.95), UiKit.COL_GOLD, 1, 2))
	toggle.pressed.connect(_toggle_stats)
	doll.add_child(toggle)
	for key in Data.EQUIP_ORDER:
		var slot := ItemSlot.new(EQ_CELL, key)
		slot.position = EQ_POS.get(key, Vector2.ZERO)
		slot.set_item(Game.equipment.get(key))
		slot.clicked.connect(_on_equip_clicked)
		slot.hovered.connect(_on_slot_hovered)
		slot.unhovered.connect(_on_slot_unhovered)
		slot.dropped.connect(_on_item_dropped)
		doll.add_child(slot)

	var inv_head := HBoxContainer.new()
	inv_head.custom_minimum_size = Vector2(350, 22)
	inv_head.add_theme_constant_override("separation", 5)
	inv_head.add_child(UiKit.label("背包", 11, UiKit.COL_GOLD))
	inv_head.add_child(UiKit.label("%d/%d" % [Game.inventory_count(), Data.INVENTORY_SIZE], 9, UiKit.COL_MUTED))
	inv_head.add_child(UiKit.spacer())
	var sort_btn := UiKit.button("整理", 9)
	sort_btn.custom_minimum_size = Vector2(34, 20)
	sort_btn.pressed.connect(func(): Game.sort_inventory())
	inv_head.add_child(sort_btn)
	left.add_child(inv_head)

	var inv_scroll := ScrollContainer.new()
	inv_scroll.custom_minimum_size = Vector2(350, 140)
	inv_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inv_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	left.add_child(inv_scroll)

	var inv_grid := GridContainer.new()
	inv_grid.columns = 8
	inv_grid.add_theme_constant_override("h_separation", 4)
	inv_grid.add_theme_constant_override("v_separation", 4)
	var inv_center := CenterContainer.new()
	inv_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inv_scroll.add_child(inv_center)
	inv_center.add_child(inv_grid)
	for i in Data.INVENTORY_SIZE:
		var slot := ItemSlot.new(INV_CELL, "")
		slot.inv_index = i
		slot.set_item(Game.inventory[i] if i < Game.inventory.size() else null)
		slot.clicked.connect(_on_inv_clicked)
		slot.hovered.connect(_on_slot_hovered)
		slot.unhovered.connect(_on_slot_unhovered)
		slot.dropped.connect(_on_item_dropped)
		inv_grid.add_child(slot)

	if not _stats_open:
		return

	# 右：人物 + 属性
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(400, 0)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)

	var stats := Game.compute_stats()
	var cls: Dictionary = Data.class_def(Game.class_id)
	var ch: Dictionary = Data.character_def(Game.class_id)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	var portrait := PanelContainer.new()
	portrait.custom_minimum_size = Vector2(60, 60)
	portrait.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	portrait.add_theme_stylebox_override("panel", UiKit.stylebox(UiKit.COL_PANEL_2, UiKit.COL_BORDER, 1, 3))
	var avatar := TextureRect.new()
	var avatar_path := String(ch.get("portrait", ch["sprite"]))
	var sheet := load(avatar_path) as Texture2D
	if sheet != null:
		avatar.texture = sheet
	avatar.custom_minimum_size = Vector2(54, 54)
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	avatar.modulate = Color(String(ch.get("tint", "#ffffff")))
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.add_child(avatar)
	header.add_child(portrait)

	var info := VBoxContainer.new()
	info.custom_minimum_size = Vector2(280, 60)
	info.add_theme_constant_override("separation", 4)
	var char_head := HBoxContainer.new()
	var name_pad := Control.new()
	name_pad.custom_minimum_size = Vector2(3, 0)
	name_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	char_head.add_child(name_pad)
	char_head.add_child(UiKit.label(Data.character_name(Game.class_id), 18, Color(String(ch["color"]))))
	var level_label := UiKit.label("Lv.%d" % Game.level, 12, UiKit.COL_MUTED)
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	level_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	char_head.add_child(level_label)
	char_head.add_child(UiKit.spacer())
	info.add_child(char_head)
	var exp_bar := UiKit.progress(Game.exp, Game.exp_to_next(), 6, UiKit.COL_TEAL)
	exp_bar.custom_minimum_size = Vector2(280, 6)
	exp_bar.size = Vector2(280, 6)
	exp_bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	info.add_child(exp_bar)

	var auto_row := HBoxContainer.new()
	auto_row.add_theme_constant_override("separation", 6)
	var auto_eq := UiKit.button("自动替换：%s" % ("开" if Game.auto_equip else "关"), 10)
	auto_eq.custom_minimum_size = Vector2(0, 22)
	auto_eq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	auto_eq.add_theme_color_override("font_color", UiKit.COL_GREEN if Game.auto_equip else UiKit.COL_MUTED)
	auto_eq.pressed.connect(_toggle_auto_equip)
	auto_row.add_child(auto_eq)
	var auto_sell := UiKit.button("自动出售：%s" % ("开" if Game.auto_sell else "关"), 10)
	auto_sell.custom_minimum_size = Vector2(0, 22)
	auto_sell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	auto_sell.add_theme_color_override("font_color", UiKit.COL_GREEN if Game.auto_sell else UiKit.COL_MUTED)
	auto_sell.pressed.connect(_toggle_auto_sell)
	auto_row.add_child(auto_sell)
	info.add_child(auto_row)
	header.add_child(info)
	right.add_child(header)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(scroll)

	var rv := VBoxContainer.new()
	rv.custom_minimum_size = Vector2(380, 0)
	rv.add_theme_constant_override("separation", 3)
	scroll.add_child(rv)

	var prim_grid := GridContainer.new()
	prim_grid.columns = 4
	prim_grid.add_theme_constant_override("h_separation", 14)
	prim_grid.add_theme_constant_override("v_separation", 1)
	rv.add_child(prim_grid)
	for key in ["strength", "agility", "intellect", "stamina"]:
		prim_grid.add_child(UiKit.label("%s %d" % [Data.PRIMARY_NAMES[key], int(stats.get(key, 0))], 11, UiKit.stat_color(key)))

	rv.add_child(UiKit.hsep())
	rv.add_child(UiKit.label("战斗属性", 11, UiKit.COL_GOLD))
	var rows := [
		["每秒伤害", UiKit.num(int(stats["dps"])), UiKit.COL_GOLD],
		["生命上限", UiKit.num(int(stats["hp_max"])), UiKit.COL_GREEN],
		["护甲", UiKit.num(int(stats["armor_total"])), UiKit.COL_TEXT],
		["攻击强度", UiKit.num(int(stats["ap"])) if float(stats["ap"]) > 0.0 else "—", UiKit.COL_TEXT],
		["法术强度", UiKit.num(int(stats["sp"])) if float(stats["sp"]) > 0.0 else "—", UiKit.COL_TEXT],
		["暴击", UiKit.pct(stats["crit_pct"]), UiKit.COL_TEXT],
		["暴击伤害", "%d%%" % int(round(float(stats["crit_dmg_pct"]) * 100.0)), UiKit.COL_TEXT],
		["急速", UiKit.pct(stats["haste_pct"]), UiKit.COL_TEXT],
		["命中", UiKit.pct(stats["hit_pct"]), UiKit.COL_TEXT],
		["闪避", UiKit.pct(stats["dodge_pct"]), UiKit.COL_TEXT],
		["招架", UiKit.pct(stats["parry_pct"]), UiKit.COL_TEXT],
		["格挡", UiKit.pct(stats["block_pct"]), UiKit.COL_TEXT],
		["全能", UiKit.pct(stats["vers_pct"]), UiKit.COL_TEXT],
		["吸血", UiKit.pct(stats["lifesteal_pct"]), UiKit.COL_TEXT],
		["生命回复", UiKit.num(int(stats["hp_regen"])), UiKit.COL_GREEN],
		["额外攻击", UiKit.pct(stats["extra_attack_pct"]), UiKit.COL_TEAL],
		["穿透", UiKit.pct(stats["pen_pct"]), UiKit.COL_TEXT],
		["有效生命", UiKit.num(int(stats["ehp"])), UiKit.COL_MUTED],
	]
	var pair_grid := GridContainer.new()
	pair_grid.columns = 1
	pair_grid.add_theme_constant_override("h_separation", 0)
	pair_grid.add_theme_constant_override("v_separation", 1)
	rv.add_child(pair_grid)
	for row in rows:
		var row_h := _stat_row(row[0], row[1], row[2])
		if row[0] == "有效生命":
			row_h.tooltip_text = "按生命上限、护甲减伤、闪避、招架和格挡综合折算的承伤能力，不是直接血量"
		pair_grid.add_child(row_h)

	if _stats_open:
		main.add_child(right)
	else:
		right.free()


func _stat_row(name_text: String, value_text: String, color: Color) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.custom_minimum_size = Vector2(380, 0)
	h.mouse_filter = Control.MOUSE_FILTER_STOP
	var name_label := UiKit.label(name_text, 10, UiKit.COL_MUTED)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(name_label)
	h.add_child(UiKit.spacer())
	var v := UiKit.label(value_text, 11, color)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(v)
	return h


func _toggle_stats() -> void:
	_stats_open = not _stats_open
	resize_keep_origin(Vector2(800, 600) if _stats_open else Vector2(390, 600), true, true)
	refresh()


func _toggle_auto_equip() -> void:
	Game.set_auto_equip(not Game.auto_equip)
	refresh()


func _toggle_auto_sell() -> void:
	Game.set_auto_sell(not Game.auto_sell)
	refresh()


func _on_equip_clicked(slot: ItemSlot, item: GameItem, _button: int) -> void:
	if item == null:
		return
	Game.unequip(slot.slot_id)


func _on_inv_clicked(_slot: ItemSlot, item: GameItem, button: int) -> void:
	if item == null:
		return
	if button == MOUSE_BUTTON_RIGHT:
		_open_item_menu(item)
		return
	Game.equip_item(item)


func _on_item_dropped(source: ItemSlot, target: ItemSlot) -> void:
	if source == null or target == null or source.item == null:
		return
	if source.inv_index >= 0 and target.inv_index >= 0:
		Game.move_inventory(source.inv_index, target.inv_index)
	elif source.inv_index >= 0 and target.slot_id != "":
		Game.equip_at(source.item, source.inv_index, target.slot_id)
	elif source.slot_id != "" and target.inv_index >= 0:
		Game.unequip_to(source.slot_id, target.inv_index)
	elif source.slot_id != "" and target.slot_id != "":
		Game.swap_equipment_slots(source.slot_id, target.slot_id)
	refresh()


func _open_item_menu(item: GameItem) -> void:
	_menu_item = item
	_menu.clear()
	_menu.add_item("装备", 0)
	_menu.add_item("出售  +%d 金币" % item.sell_value(), 1)
	_menu.set_item_disabled(1, item.locked)
	_menu.add_item("解锁" if item.locked else "锁定", 2)
	_menu.add_item("分解  +%d 材料" % maxi(1, int(round(item.sell_value() * 0.5))), 3)
	_menu.set_item_disabled(3, item.locked)
	_menu.reset_size()
	var gp := get_global_mouse_position()
	_menu.popup(Rect2i(Vector2i(gp), Vector2i(1, 1)))


func _on_menu_id(id: int) -> void:
	var item := _menu_item
	if item == null:
		return
	match id:
		0:
			Game.equip_item(item)
		1:
			Game.sell_item(item)
		2:
			Game.toggle_lock(item)
		3:
			Game.dismantle_item(item)
	refresh()


func _on_slot_hovered(slot: ItemSlot, item: GameItem) -> void:
	if item == null or _tip == null:
		if _tip != null:
			_tip.hide_tip()
		return
	if slot.slot_id != "":
		_tip.show_item(item, null, Game.class_id, "点击卸下 / 拖动换位", false)
	else:
		_tip.show_item(item, Game.compare_item(item), Game.class_id, "左键装备 / 拖动换位 · 右键菜单")


func _on_slot_unhovered(_slot: ItemSlot) -> void:
	if _tip != null:
		_tip.hide_tip()
