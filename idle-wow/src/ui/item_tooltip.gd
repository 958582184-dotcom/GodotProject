class_name ItemTooltip
extends PanelContainer

var _box: VBoxContainer
var _built := false


func _ready() -> void:
	_build()


func _build() -> void:
	_built = true
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 200
	add_theme_stylebox_override("panel", UiKit.stylebox(Color(0.031, 0.040, 0.055, 1.0), UiKit.COL_GOLD_DIM, 2, 12))
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 3)
	add_child(_box)


func _clear() -> void:
	for c in _box.get_children():
		_box.remove_child(c)
		c.queue_free()


func show_item(item: GameItem, compare: GameItem, class_id: String, hint: String = "", show_compare: bool = true) -> void:
	if not _built:
		_build()
	if item == null:
		hide_tip()
		return
	_clear()
	visible = true
	var title := UiKit.label(item.item_name, 18, item.quality_color())
	_box.add_child(title)
	var sub := UiKit.label("装等 %d  ·  %s  ·  %s" % [item.ilvl, item.slot_name(), item.quality_name()], 12, UiKit.COL_MUTED)
	_box.add_child(sub)
	_box.add_child(UiKit.hsep())

	for key in ["strength", "agility", "intellect", "stamina"]:
		if item.stats.has(key):
			_box.add_child(UiKit.label(Data.fmt_primary(key, float(item.stats[key])), 14, UiKit.stat_color(key)))
	if item.stats.has("armor"):
		_box.add_child(UiKit.label("护甲 +%d" % int(item.stats["armor"]), 14, UiKit.COL_TEXT))
	if item.weapon_max > 0.0:
		_box.add_child(UiKit.label("伤害 %d - %d" % [int(item.weapon_min), int(item.weapon_max)], 14, UiKit.COL_TEXT))
	for key in Data.AFFIX_KEYS:
		if item.stats.has(key):
			_box.add_child(UiKit.label(Data.fmt_affix(key, float(item.stats[key])), 14, UiKit.COL_TEAL))

	if show_compare:
		_box.add_child(UiKit.hsep())
		if compare == null:
			_box.add_child(UiKit.label("当前部位为空", 12, UiKit.COL_MUTED))
			_box.add_child(UiKit.label("评分 +%.1f" % item.score(class_id), 13, UiKit.COL_GREEN))
		else:
			var delta := item.score(class_id) - compare.score(class_id)
			var delta_text := "评分 %+.1f" % delta
			var color := UiKit.COL_GREEN if delta > 0.05 else (UiKit.COL_RED if delta < -0.05 else UiKit.COL_MUTED)
			_box.add_child(UiKit.label(delta_text, 14, color))
			var ilvl_delta := item.ilvl - compare.ilvl
			_box.add_child(UiKit.label("装等 %+d  ·  当前：%s" % [ilvl_delta, compare.item_name], 11, UiKit.COL_MUTED))

	if hint != "":
		_box.add_child(UiKit.label(hint, 11, UiKit.COL_DIM))
	_box.add_child(UiKit.hsep())
	_box.add_child(UiKit.label("售价 %d 金币" % item.sell_value(), 11, UiKit.COL_GOLD))

	_layout()


func _layout() -> void:
	var need := _box.get_combined_minimum_size()
	var w := 330.0
	var h := maxf(need.y + 24.0, 56.0)
	size = Vector2(w, h)
	var vp := get_viewport_rect().size
	var mouse := get_viewport().get_mouse_position()
	var pos := mouse + Vector2(18, 16)
	if pos.x + w > vp.x - 8.0:
		pos.x = mouse.x - w - 18.0
	if pos.y + h > vp.y - 8.0:
		pos.y = vp.y - h - 8.0
	pos.x = maxf(8.0, pos.x)
	pos.y = maxf(8.0, pos.y)
	position = pos.round()


func hide_tip() -> void:
	visible = false
