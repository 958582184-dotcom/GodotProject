class_name StatsWindow
extends BaseWindow


func _init() -> void:
	title = "统计"
	window_size = Vector2(440, 360)


func _refresh_body(box: VBoxContainer) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()

	var title_row := HBoxContainer.new()
	title_row.add_child(UiKit.label("统计看板", 16, UiKit.COL_GOLD))
	title_row.add_child(UiKit.spacer())
	box.add_child(title_row)
	box.add_child(UiKit.hsep())
	box.add_child(UiKit.label("累计数据", 10, UiKit.COL_MUTED))

	var rows := [
		["累计通关副本", UiKit.num(int(Game.metrics.get("dungeons", 0))), UiKit.COL_GREEN],
		["累计死亡", UiKit.num(int(Game.metrics.get("deaths", 0))), UiKit.COL_RED],
		["累计击杀", UiKit.num(int(Game.metrics.get("kills", 0))), UiKit.COL_TEXT],
		["首领击杀", UiKit.num(int(Game.metrics.get("bosses", 0))), UiKit.COL_GOLD],
		["获得装备", UiKit.num(int(Game.metrics.get("items", 0))), UiKit.COL_TEAL],
	]
	for row in rows:
		box.add_child(_stat_row(String(row[0]), String(row[1]), row[2]))

	box.add_child(UiKit.hsep())
	box.add_child(UiKit.label("当前状态", 10, UiKit.COL_MUTED))
	box.add_child(_stat_row("等级", "Lv.%d" % Game.level, UiKit.COL_GOLD))
	box.add_child(_stat_row("金币", UiKit.num(Game.gold), UiKit.COL_GOLD))
	box.add_child(_stat_row("当前区域", String(Game.current_area()["name"]), UiKit.COL_TEXT))
	box.add_child(_stat_row("区域探索度", "%d%%" % int(Game.exploration), UiKit.COL_GREEN))
	box.add_child(UiKit.spacer())


func _stat_row(name_text: String, value_text: String, color: Color) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_child(UiKit.label(name_text, 11, UiKit.COL_MUTED))
	h.add_child(UiKit.spacer())
	h.add_child(UiKit.label(value_text, 13, color))
	return h
