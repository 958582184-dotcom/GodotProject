class_name MoreWindow
extends BaseWindow

var _reset_armed := false


func _init() -> void:
	title = "设置"
	window_size = Vector2(520, 300)


func _refresh_body(box: VBoxContainer) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()

	var title_row := HBoxContainer.new()
	title_row.add_child(UiKit.label("设置", 15, UiKit.COL_GOLD))
	title_row.add_child(UiKit.spacer())
	box.add_child(title_row)
	box.add_child(UiKit.hsep())

	box.add_child(UiKit.label("B 背包 · M 副本 · S 商店 · I 信息 · F 刷新", 10, UiKit.COL_DIM))
	box.add_child(UiKit.hsep())

	var save_btn := UiKit.button("立即保存", 13)
	save_btn.custom_minimum_size = Vector2(0, 30)
	save_btn.pressed.connect(_save_now)
	box.add_child(save_btn)
	var reset_btn := UiKit.button("再次点击确认清空存档" if _reset_armed else "重新开始（清空存档）", 13)
	reset_btn.custom_minimum_size = Vector2(0, 30)
	reset_btn.add_theme_color_override("font_color", UiKit.COL_RED)
	reset_btn.pressed.connect(_reset_progress)
	box.add_child(reset_btn)
	box.add_child(UiKit.spacer())

	var quit_btn := UiKit.button("保存并退出游戏", 13)
	quit_btn.custom_minimum_size = Vector2(0, 30)
	quit_btn.pressed.connect(_quit_game)
	box.add_child(quit_btn)


func _save_now() -> void:
	Game.save_game()
	Game.push_log("已保存", UiKit.COL_MUTED)


func _reset_progress() -> void:
	if not _reset_armed:
		_reset_armed = true
		refresh()
		return
	Game.reset_all()


func _quit_game() -> void:
	Game.save_game()
	get_tree().quit()
