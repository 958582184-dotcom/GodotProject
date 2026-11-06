class_name ShopWindow
extends BaseWindow

var _tip: ItemTooltip


func _init() -> void:
	title = "商店"
	window_size = Vector2(440, 250)


func _after_build() -> void:
	_tip = ItemTooltip.new()
	add_child(_tip)


func _refresh_body(box: VBoxContainer) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()
	for c in _footer_left.get_children():
		_footer_left.remove_child(c)
		c.queue_free()
	if _tip != null:
		_tip.hide_tip()

	var title_row := HBoxContainer.new()
	title_row.add_child(UiKit.label("商店", 15, UiKit.COL_GOLD))
	title_row.add_child(UiKit.spacer())
	title_row.add_child(UiKit.label("金币 %s" % UiKit.num(Game.gold), 11, UiKit.COL_GOLD))
	box.add_child(title_row)
	box.add_child(UiKit.hsep())

	if Game.shop_stock.is_empty():
		var empty := UiKit.panel(UiKit.COL_PANEL_2, UiKit.COL_BORDER_DIM, 1, 16)
		empty.custom_minimum_size = Vector2(0, 120)
		empty.add_child(UiKit.label("已售罄", 11, UiKit.COL_MUTED))
		box.add_child(empty)
	else:
		var grid := GridContainer.new()
		grid.columns = 4
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 6)
		grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(grid)
		for i in Game.shop_stock.size():
			grid.add_child(_make_cell(Game.shop_stock[i], i))

	var free_left := Game.shop_free_count()
	var refresh := UiKit.button(("刷新 · 免费 %d" % free_left) if free_left > 0 else ("刷新 · %d" % Data.SHOP_PAID_COST), 10)
	refresh.custom_minimum_size = Vector2(130, 24)
	refresh.add_theme_color_override("font_color", UiKit.COL_GOLD)
	refresh.pressed.connect(func(): Game.refresh_shop())
	_footer_left.add_child(refresh)


func _make_cell(item: GameItem, index: int) -> PanelContainer:
	var qcol := item.quality_color()
	var p := UiKit.panel(UiKit.COL_PANEL_2.lerp(qcol, 0.05), qcol.darkened(0.35), 1, 4)
	p.custom_minimum_size = Vector2(96, 74)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	p.add_child(v)
	var center := CenterContainer.new()
	center.custom_minimum_size = Vector2(0, 40)
	v.add_child(center)
	var icon := TextureRect.new()
	icon.texture = UiKit.icon_for_item(item)
	icon.custom_minimum_size = Vector2(36, 36)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_STOP
	icon.mouse_entered.connect(_show_tip.bind(item))
	icon.mouse_exited.connect(_hide_tip)
	center.add_child(icon)
	if item.shop_factor > 1.08 or item.shop_factor < 0.92:
		var up := item.shop_factor > 1.08
		var arrow := UiKit.label("↑" if up else "↓", 14, Color("#ff6b5e") if up else Color("#63c76a"))
		arrow.position = Vector2(26, -5)
		arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.add_child(arrow)

	var cost := item.shop_price_value()
	var price := UiKit.button(str(cost), 10)
	price.custom_minimum_size = Vector2(56, 20)
	price.add_theme_color_override("font_color", UiKit.COL_GOLD)
	var flat := UiKit.stylebox(Color(0.10, 0.085, 0.07, 0.55), Color(0, 0, 0, 0), 0, 2)
	price.add_theme_stylebox_override("normal", flat)
	price.add_theme_stylebox_override("hover", UiKit.stylebox(Color(0.16, 0.13, 0.10, 0.9), UiKit.COL_GOLD, 1, 2))
	price.add_theme_stylebox_override("pressed", flat)
	price.disabled = Game.gold < cost
	price.pressed.connect(Game.buy_shop.bind(index))
	price.mouse_entered.connect(_show_tip.bind(item))
	price.mouse_exited.connect(_hide_tip)
	v.add_child(price)
	return p


func _show_tip(item: GameItem) -> void:
	if _tip != null:
		_tip.show_item(item, null, Game.class_id, "点击价格购买", false)


func _hide_tip() -> void:
	if _tip != null:
		_tip.hide_tip()
