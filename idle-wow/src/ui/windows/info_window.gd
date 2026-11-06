class_name InfoWindow
extends BaseWindow

var _scroll: ScrollContainer


func _init() -> void:
	title = "信息"
	window_size = Vector2(260, 240)


func _after_build() -> void:
	Game.log_added.connect(_on_log_added)
	var clear_btn := UiKit.button("清除", 10)
	clear_btn.custom_minimum_size = Vector2(46, 24)
	clear_btn.add_theme_color_override("font_color", UiKit.COL_MUTED)
	clear_btn.pressed.connect(_clear_logs)
	_footer_left.add_child(clear_btn)


func _on_log_added(_text: String, _color: Color) -> void:
	if visible:
		refresh()


func _refresh_body(box: VBoxContainer) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()

	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_scroll)

	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 6)
	rv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(rv)

	if Game.log_history.is_empty():
		rv.add_child(UiKit.label("还没有记录。", 11, UiKit.COL_DIM))
	for entry in Game.log_history:
		var l := UiKit.label(String(entry["text"]), 11, entry["color"])
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rv.add_child(l)
	_scroll_to_bottom()


func _scroll_to_bottom() -> void:
	await get_tree().process_frame
	if _scroll != null:
		_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)


func _clear_logs() -> void:
	Game.clear_logs()
	refresh()
