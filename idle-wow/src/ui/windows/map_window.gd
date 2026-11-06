class_name MapWindow
extends BaseWindow

signal enter_dungeon(dungeon: Dictionary)
signal boss_requested

var _auto_btn: Button
var _auto_menu: PopupMenu
const AUTO_MODES := ["repeat", "next", "off"]
const AUTO_LABELS := ["重复当前", "下一关", "关闭"]


func _init() -> void:
	title = "副本"
	window_size = Vector2(840, 480)


func _after_build() -> void:
	_auto_btn = UiKit.button("", 10)
	_auto_btn.custom_minimum_size = Vector2(132, 24)
	_auto_btn.add_theme_color_override("font_color", UiKit.COL_GOLD)
	_auto_btn.add_theme_stylebox_override("normal", UiKit.stylebox(Color(0.08, 0.09, 0.11, 0.85), Color(0.28, 0.24, 0.18), 1, 6))
	_auto_btn.add_theme_stylebox_override("hover", UiKit.stylebox(Color(0.14, 0.12, 0.09, 0.95), UiKit.COL_GOLD, 1, 6))
	_auto_btn.tooltip_text = "选择自动副本模式"
	_auto_btn.pressed.connect(_open_auto_menu)
	_footer_left.add_child(_auto_btn)

	_auto_menu = PopupMenu.new()
	_auto_menu.add_item(AUTO_LABELS[0], 0)
	_auto_menu.add_item(AUTO_LABELS[1], 1)
	_auto_menu.add_item(AUTO_LABELS[2], 2)
	_auto_menu.id_pressed.connect(_on_auto_id)
	add_child(_auto_menu)
	_update_auto_btn()


func _refresh_body(box: VBoxContainer) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()

	var title_row := HBoxContainer.new()
	title_row.add_child(UiKit.label("副本", 15, UiKit.COL_GOLD))
	title_row.add_child(UiKit.spacer())
	box.add_child(title_row)
	box.add_child(UiKit.hsep())
	box.add_child(_area_bar())

	var map := DungeonMap.new()
	map.custom_minimum_size = Vector2(808, 320)
	map.node_pressed.connect(_on_node_pressed)
	box.add_child(map)
	map.setup(Game.dungeons)
	_add_refresh_overlay(map)
	_update_auto_btn()


func _area_bar() -> PanelContainer:
	var p := UiKit.panel(Color(0.055, 0.070, 0.082, 0.96), Color(0.22, 0.27, 0.31, 0.9), 1, 0)
	p.custom_minimum_size = Vector2(808, 66)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	p.add_child(margin)
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 0)
	margin.add_child(h)
	h.add_child(_area_side(Game.area_index - 1, "上一区域", true, 100))
	var left_gap := Control.new()
	left_gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(left_gap)
	h.add_child(_area_current(320))
	var right_gap := Control.new()
	right_gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(right_gap)
	h.add_child(_area_side(Game.area_index + 1, "下一区域", false, 100))
	return p


func _area_sep() -> ColorRect:
	var line := ColorRect.new()
	line.color = Color(0.20, 0.24, 0.27, 0.75)
	line.custom_minimum_size = Vector2(1, 32)
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line


func _area_side(index: int, role: String, left: bool, width: int) -> Button:
	var valid := index >= 0 and index < Data.AREAS.size()
	var unlocked := valid and Game.area_unlocked(index)
	var area: Dictionary = Data.area_def(index) if valid else {}
	var b := Button.new()
	b.custom_minimum_size = Vector2(width, 56)
	b.text = ""
	b.disabled = not valid or not unlocked
	b.tooltip_text = "" if valid else "没有更多区域"
	b.pressed.connect(_switch_area.bind(index))
	var clear := UiKit.stylebox(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 6)
	b.add_theme_stylebox_override("normal", clear)
	b.add_theme_stylebox_override("hover", UiKit.stylebox(Color(0.10, 0.12, 0.10, 0.65), Color(0.32, 0.30, 0.22, 0.9), 1, 6))
	b.add_theme_stylebox_override("pressed", UiKit.stylebox(Color(0.06, 0.07, 0.06, 0.75), UiKit.COL_GOLD, 1, 6))
	b.add_theme_stylebox_override("disabled", clear)

	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 1)
	b.add_child(v)
	var role_label := UiKit.label(role, 9, UiKit.COL_DIM)
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(role_label)

	var name_text := "—"
	var name_col := UiKit.COL_MUTED
	var hint := ""
	if valid:
		name_text = String(area["name"])
		name_col = Color(String(area["color"])) if unlocked else UiKit.COL_DIM
		if not unlocked:
			hint = "需 Lv.%d" % int(area["min_level"])
	b.tooltip_text = hint if hint != "" else b.tooltip_text
	var name_label := UiKit.label(name_text, 13, name_col)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(name_label)
	return b


func _area_current(width: int) -> VBoxContainer:
	var area := Game.current_area()
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(width, 62)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 1)
	v.add_child(_center_label("当前区域", 9, UiKit.COL_DIM))
	v.add_child(_center_label(String(area["name"]), 17, UiKit.COL_GOLD))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 7)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(gap)
	var bar := UiKit.progress(Game.exploration, 100.0, 6, Color("#6fbf4a"))
	bar.add_theme_stylebox_override("background", UiKit.stylebox(Color("#8d865a"), Color(0.45, 0.42, 0.28, 0.9), 1, 0))
	bar.custom_minimum_size = Vector2(280, 6)
	bar.size = Vector2(280, 6)
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(bar)
	v.add_child(_center_label("%d%%" % int(Game.exploration), 10, UiKit.COL_GOLD))
	return v


func _center_label(text: String, font_size: int, color: Color) -> Label:
	var l := UiKit.label(text, font_size, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l



func _switch_area(index: int) -> void:
	if Game.set_area(index):
		refresh()


func _on_node_pressed(d: Dictionary) -> void:
	if String(d.get("kind", "normal")) == "boss":
		boss_requested.emit()
	else:
		enter_dungeon.emit(d)


func _update_auto_btn() -> void:
	if _auto_btn == null:
		return
	_auto_btn.text = "自动：%s ▲" % Game.auto_mode_label()
	if _auto_menu != null:
		for i in AUTO_MODES.size():
			_auto_menu.set_item_checked(i, Game.auto_mode == AUTO_MODES[i])


func _open_auto_menu() -> void:
	_update_auto_btn()
	_auto_menu.reset_size()
	var sz := _auto_menu.get_contents_minimum_size()
	var gp := _auto_btn.get_global_rect().position
	var pos := Vector2i(int(gp.x), int(gp.y - sz.y - 4))
	_auto_menu.popup(Rect2i(pos, Vector2i(1, 1)))


func _on_auto_id(id: int) -> void:
	if id >= 0 and id < AUTO_MODES.size():
		Game.set_auto_mode(AUTO_MODES[id])
		refresh()


func _add_refresh_overlay(map: DungeonMap) -> void:
	var b := UiKit.button("刷新", 10)
	b.custom_minimum_size = Vector2(60, 28)
	b.position = Vector2(736, 282)
	b.tooltip_text = "刷新副本"
	b.add_theme_color_override("font_color", UiKit.COL_GOLD)
	b.add_theme_stylebox_override("normal", UiKit.stylebox(Color(0.02, 0.02, 0.02, 0.9), Color(0.62, 0.50, 0.30, 0.95), 1, 4))
	b.add_theme_stylebox_override("hover", UiKit.stylebox(Color(0.12, 0.10, 0.08, 0.95), UiKit.COL_GOLD, 1, 4))
	b.pressed.connect(func(): Game.refresh_dungeons())
	map.add_child(b)
