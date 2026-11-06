class_name HUD
extends CanvasLayer

var world: Node

var _bottom: PanelContainer
var _status_label: Label
var _buttons: Dictionary = {}
var _button_icons: Dictionary = {}
var _windows: Dictionary = {}
var _current: BaseWindow = null
var _manual_started := false

var _bag: BackpackWindow
var _dungeon: MapWindow
var _shop: ShopWindow
var _info: InfoWindow
var _more: MoreWindow
var _stats: StatsWindow


func _ready() -> void:
	layer = 5
	_build_bottom()
	_build_windows()
	_connect_game()
	update_badges()
	update_status_line()
	add_log("挂机刷装备 · 点图标查看背包 / 副本 / 商店 / 信息")


func _build_bottom() -> void:
	_bottom = PanelContainer.new()
	add_child(_bottom)
	_bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_bottom.offset_left = 390
	_bottom.offset_right = -390
	_bottom.offset_top = -56
	_bottom.offset_bottom = 0
	var sb := UiKit.stylebox(Color(0.024, 0.031, 0.043, 0.94), UiKit.COL_BORDER_DIM, 1, 4)
	sb.border_width_top = 1
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	_bottom.add_theme_stylebox_override("panel", sb)

	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_BEGIN
	h.add_theme_constant_override("separation", 4)
	_bottom.add_child(h)
	var defs := [
		["bag", "bag_2x", "背包（B）", "bag"],
		["dungeon", "map_2x", "副本（M）", "dungeon"],
		["shop", "shop_2x", "商店（S）", "shop"],
		["info", "info_32", "信息（I）", "info"],
		["stats", "chart_32", "统计", "stats"],
		["more", "dots_2x", "设置", "more"],
	]
	for d in defs:
		var key := String(d[0])
		var action := String(d[3])
		var btn := UiKit.button("", 14)
		btn.custom_minimum_size = Vector2(40, 40)
		btn.tooltip_text = String(d[2])
		btn.pressed.connect(toggle_window.bind(action))
		h.add_child(btn)
		var center := CenterContainer.new()
		center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(center)
		var icon := TextureRect.new()
		icon.texture = UiKit.icon(String(d[1]))
		icon.custom_minimum_size = Vector2(36 if key == "bag" else 32, 36 if key == "bag" else 32)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		center.add_child(icon)
		_buttons[key] = btn
		_button_icons[key] = icon

	_status_label = UiKit.label("", 12, UiKit.COL_MUTED)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_label.clip_text = true
	_status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(_status_label)


func _build_windows() -> void:
	_bag = BackpackWindow.new()
	add_child(_bag)
	_bag.closed.connect(_on_window_closed.bind("bag"))

	_dungeon = MapWindow.new()
	add_child(_dungeon)
	_dungeon.closed.connect(_on_window_closed.bind("dungeon"))
	_dungeon.enter_dungeon.connect(_start_dungeon)
	_dungeon.boss_requested.connect(_start_boss)

	_shop = ShopWindow.new()
	add_child(_shop)
	_shop.closed.connect(_on_window_closed.bind("shop"))

	_info = InfoWindow.new()
	add_child(_info)
	_info.closed.connect(_on_window_closed.bind("info"))

	_more = MoreWindow.new()
	add_child(_more)
	_more.closed.connect(_on_window_closed.bind("more"))

	_stats = StatsWindow.new()
	add_child(_stats)
	_stats.closed.connect(_on_window_closed.bind("stats"))

	_windows = {"bag": _bag, "dungeon": _dungeon, "shop": _shop, "info": _info, "more": _more, "stats": _stats}


func _connect_game() -> void:
	Game.stats_changed.connect(_on_state_changed)
	Game.inventory_changed.connect(_on_state_changed)
	Game.equipment_changed.connect(_on_state_changed)
	Game.gold_changed.connect(_on_state_changed)
	Game.exploration_changed.connect(_on_state_changed)
	Game.dungeons_changed.connect(_on_dungeons_changed)
	Game.area_changed.connect(_on_area_changed)
	Game.shop_changed.connect(_on_shop_changed)
	Game.metrics_changed.connect(_on_state_changed)
	Game.auto_mode_changed.connect(func(_m): update_badges())
	Game.toast.connect(add_log)
	Game.busy_changed.connect(_on_busy_changed)


func add_log(text: String, color: Color = Color("#c8d2df")) -> void:
	Game.push_log(text, color)


func set_stage(_text: String) -> void:
	pass


func clear_stage() -> void:
	pass


func update_badges() -> void:
	var dungeon_icon: TextureRect = _button_icons.get("dungeon")
	var dungeon_btn: Button = _buttons.get("dungeon")
	if dungeon_icon != null:
		dungeon_icon.modulate = UiKit.COL_RED if Game.boss_ready() else Color.WHITE
	if dungeon_btn != null:
		dungeon_btn.tooltip_text = "副本（首领待战）" if Game.boss_ready() else "副本（M）"
	var bag_icon: TextureRect = _button_icons.get("bag")
	var bag_btn: Button = _buttons.get("bag")
	var full := Game.inventory_count() >= Data.INVENTORY_SIZE and not Game.auto_sell
	if bag_icon != null:
		bag_icon.modulate = UiKit.COL_RED if full else Color.WHITE
	if bag_btn != null:
		bag_btn.tooltip_text = "背包（已满）" if full else "背包（B）"


func update_status_line() -> void:
	if _status_label == null:
		return
	var text := "Lv.%d" % Game.level
	if Game.current_dungeon.is_empty():
		text += " · 未选择副本"
	elif String(Game.current_dungeon.get("kind", "normal")) == "boss":
		text += " · 首领 Lv.%d" % int(Game.current_dungeon.get("level", 1))
	else:
		text += " · %s" % Data.dungeon_title(Game.current_dungeon)
		var diff := String(Game.current_dungeon.get("difficulty", "normal"))
		if diff != "normal":
			text += " %s" % String(Data.DIFFICULTIES[diff]["name"])
	_status_label.text = text
	_status_label.add_theme_color_override("font_color",
		UiKit.COL_RED if Game.boss_ready() else UiKit.COL_MUTED)


func _on_state_changed() -> void:
	update_badges()
	update_status_line()
	if _bag != null and _bag.visible:
		_bag.refresh()
	if _shop != null and _shop.visible:
		_shop.refresh()
	if _info != null and _info.visible:
		_info.refresh()
	if _stats != null and _stats.visible:
		_stats.refresh()


func _on_dungeons_changed() -> void:
	update_status_line()
	if _dungeon != null and _dungeon.visible:
		_dungeon.refresh()


func _on_area_changed(_index: int) -> void:
	update_status_line()
	if _dungeon != null and _dungeon.visible:
		_dungeon.refresh()
	update_badges()


func _on_shop_changed() -> void:
	if _shop != null and _shop.visible:
		_shop.refresh()


func _on_busy_changed(_value: bool) -> void:
	update_status_line()
	if _dungeon != null and _dungeon.visible:
		_dungeon.refresh()


func toggle_window(name: String) -> void:
	if Game.class_id == "":
		return
	var w: BaseWindow = _windows.get(name)
	if w == null:
		return
	if name == "info" or name == "stats":
		if w.visible:
			w.close()
		else:
			w.open()
			w.refresh()
		return
	if w.visible:
		w.close()
		return
	for key in ["bag", "dungeon", "more"]:
		if key == name:
			continue
		var other: BaseWindow = _windows.get(key)
		if other != null and other.visible:
			other.close()
	_current = w
	w.open()


func close_current() -> void:
	if _current != null and _current.visible:
		_current.close()
	elif _shop != null and _shop.visible:
		_shop.close()
	elif _info != null and _info.visible:
		_info.close()


func has_open_window() -> bool:
	for key in _windows:
		var w: BaseWindow = _windows[key]
		if w != null and w.visible:
			return true
	return false


func refresh_dungeon() -> void:
	if _dungeon != null and _dungeon.visible:
		Game.refresh_dungeons()


func _on_window_closed(_name: String) -> void:
	if has_open_window():
		return
	_current = null
	if not _manual_started:
		return
	if world != null and Game.auto_mode != "off":
		world.resume_auto(0.8)


func _start_dungeon(d: Dictionary) -> void:
	_manual_started = true
	_close_all_now()
	if world != null:
		world.start_dungeon(d)


func _start_boss() -> void:
	_manual_started = true
	_close_all_now()
	if world != null:
		world.start_dungeon(Game.make_boss_dungeon())


func _close_all_now() -> void:
	for key in ["bag", "dungeon", "shop", "more", "stats"]:
		var w: BaseWindow = _windows.get(key)
		if w != null:
			w.visible = false
	_current = null
