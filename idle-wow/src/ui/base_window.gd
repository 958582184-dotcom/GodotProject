class_name BaseWindow
extends Control

signal closed

var title := "窗口"
var subtitle := ""
var window_size := Vector2(800, 500)

var _panel: PanelContainer
var _body: VBoxContainer
var _footer: HBoxContainer
var _footer_left: HBoxContainer
var _drag_edges: Array[Control] = []
var _built := false
var _fading := false
var _panel_dragging := false
var _drag_start_panel := Vector2.ZERO
var _drag_start_mouse := Vector2.ZERO


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	if not _built:
		_build()


func _build() -> void:
	_built = true
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UiKit.stylebox(UiKit.COL_PANEL, UiKit.COL_BORDER, 2, 0))
	_panel.custom_minimum_size = window_size
	_panel.size = window_size
	_panel.position = ((_viewport_size() - window_size) * 0.5).round()
	add_child(_panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 0)
	_panel.add_child(root)

	var body_margin := MarginContainer.new()
	body_margin.add_theme_constant_override("margin_left", 16)
	body_margin.add_theme_constant_override("margin_right", 16)
	body_margin.add_theme_constant_override("margin_top", 12)
	body_margin.add_theme_constant_override("margin_bottom", 4)
	body_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body_margin)

	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 8)
	body_margin.add_child(_body)

	root.add_child(UiKit.hsep())

	var footer_margin := MarginContainer.new()
	footer_margin.add_theme_constant_override("margin_left", 12)
	footer_margin.add_theme_constant_override("margin_right", 6)
	footer_margin.add_theme_constant_override("margin_top", 2)
	footer_margin.add_theme_constant_override("margin_bottom", 3)
	root.add_child(footer_margin)

	_footer = HBoxContainer.new()
	_footer.add_theme_constant_override("separation", 8)
	footer_margin.add_child(_footer)
	_footer_left = HBoxContainer.new()
	_footer_left.add_theme_constant_override("separation", 12)
	_footer_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_footer.add_child(_footer_left)

	var close_btn := UiKit.button("×", 17)
	close_btn.custom_minimum_size = Vector2(30, 28)
	close_btn.add_theme_color_override("font_color", UiKit.COL_MUTED)
	var close_flat := UiKit.stylebox(Color(0.10, 0.12, 0.15, 0.7), Color(0, 0, 0, 0), 0, 4)
	close_btn.add_theme_stylebox_override("normal", close_flat)
	close_btn.add_theme_stylebox_override("hover", UiKit.stylebox(Color(0.18, 0.15, 0.12, 0.95), UiKit.COL_GOLD, 1, 4))
	close_btn.add_theme_stylebox_override("pressed", close_flat)
	close_btn.tooltip_text = "关闭"
	close_btn.pressed.connect(close)
	_footer.add_child(close_btn)

	for i in 4:
		var edge := Control.new()
		edge.mouse_filter = Control.MOUSE_FILTER_STOP
		edge.gui_input.connect(_on_edge_input)
		add_child(edge)
		_drag_edges.append(edge)

	resized.connect(_recenter)
	_after_build()
	_update_edges()


func _viewport_size() -> Vector2:
	var vp := get_viewport()
	if vp == null:
		return Vector2(1280, 720)
	return vp.get_visible_rect().size


func _recenter() -> void:
	if _panel != null:
		_panel.position = ((_viewport_size() - window_size) * 0.5).round()
		_update_edges()


func _update_edges() -> void:
	if _panel == null or _drag_edges.size() < 4:
		return
	var p := _panel.position
	var s := _panel.size
	_drag_edges[0].position = Vector2(p.x - 6, p.y - 6)
	_drag_edges[0].size = Vector2(s.x + 12, 12)
	_drag_edges[1].position = Vector2(p.x - 6, p.y + s.y - 6)
	_drag_edges[1].size = Vector2(s.x + 12, 12)
	_drag_edges[2].position = Vector2(p.x - 6, p.y + 6)
	_drag_edges[2].size = Vector2(12, s.y - 12)
	_drag_edges[3].position = Vector2(p.x + s.x - 6, p.y + 6)
	_drag_edges[3].size = Vector2(12, s.y - 12)


func set_window_size(new_size: Vector2) -> void:
	window_size = new_size
	if _panel != null:
		_panel.custom_minimum_size = new_size
		_panel.size = new_size
		_panel.set_deferred("size", new_size)
		_recenter()
		call_deferred("_recenter")


func resize_keep_origin(new_size: Vector2, keep_left := true, keep_top := true) -> void:
	if _panel == null:
		return
	var old_pos := _panel.position
	window_size = new_size
	_panel.custom_minimum_size = new_size
	_panel.size = new_size
	_panel.set_deferred("size", new_size)
	var vp := _viewport_size()
	var new_pos := old_pos
	if not keep_left:
		new_pos.x = (vp.x - new_size.x) * 0.5
	if not keep_top:
		new_pos.y = (vp.y - new_size.y) * 0.5
	_panel.position = new_pos
	_panel.set_deferred("position", new_pos)
	_update_edges()
	call_deferred("_update_edges")


func _on_edge_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_panel_dragging = true
		_drag_start_panel = _panel.position
		_drag_start_mouse = get_global_mouse_position()
		accept_event()


func _input(event: InputEvent) -> void:
	if not _panel_dragging:
		return
	if event is InputEventMouseMotion:
		var np := _drag_start_panel + (get_global_mouse_position() - _drag_start_mouse)
		var vp := _viewport_size()
		np.x = clampf(np.x, 0.0, maxf(0.0, vp.x - _panel.size.x))
		np.y = clampf(np.y, 0.0, maxf(0.0, vp.y - _panel.size.y))
		_panel.position = np.round()
		_update_edges()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_panel_dragging = false
		get_viewport().set_input_as_handled()


func set_subtitle(_text: String) -> void:
	pass


func open() -> void:
	if visible:
		return
	visible = true
	modulate.a = 0.0
	_fading = true
	refresh()
	var t := create_tween()
	t.tween_property(self, "modulate:a", 1.0, 0.12)
	t.finished.connect(_finish_open)


func _finish_open() -> void:
	_fading = false


func close() -> void:
	if not visible:
		return
	_fading = true
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.09)
	t.tween_callback(_finish_close)


func _finish_close() -> void:
	visible = false
	modulate.a = 1.0
	_fading = false
	closed.emit()


func _after_build() -> void:
	pass


func refresh() -> void:
	if not _built:
		return
	_refresh_body(_body)


func _refresh_body(_box: VBoxContainer) -> void:
	pass
