class_name CharacterSelect
extends Control

signal character_chosen(character_id)

var _selected := "warrior"
var _cards: Dictionary = {}
var _detail_name: Label
var _detail_talent: Label
var _detail_bonus: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var overlay := ColorRect.new()
	overlay.color = Color(0.015, 0.020, 0.028, 0.82)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 590)
	panel.add_theme_stylebox_override("panel", UiKit.stylebox(Color(0.055, 0.068, 0.082, 0.98), Color(0.30, 0.34, 0.38, 0.95), 2, 0))
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)
	root.add_child(UiKit.label("选择角色", 28, UiKit.COL_GOLD))

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.add_child(grid)
	for cid in Data.CHARACTER_ORDER:
		grid.add_child(_make_card(cid))

	var detail := PanelContainer.new()
	detail.custom_minimum_size = Vector2(0, 104)
	detail.add_theme_stylebox_override("panel", UiKit.stylebox(Color(0.035, 0.044, 0.058, 0.96), Color(0.20, 0.24, 0.28, 0.9), 1, 12))
	root.add_child(detail)
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 4)
	detail.add_child(dv)
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 10)
	dv.add_child(name_row)
	_detail_name = UiKit.label("", 21, UiKit.COL_GOLD)
	name_row.add_child(_detail_name)
	_detail_talent = UiKit.label("", 15, UiKit.COL_GOLD)
	dv.add_child(_detail_talent)
	_detail_bonus = UiKit.label("", 13, UiKit.COL_TEXT)
	dv.add_child(_detail_bonus)

	var footer := HBoxContainer.new()
	root.add_child(footer)
	footer.add_child(UiKit.spacer())
	var confirm := UiKit.button("开始旅程", 18)
	confirm.custom_minimum_size = Vector2(180, 42)
	confirm.add_theme_color_override("font_color", UiKit.COL_GOLD)
	confirm.pressed.connect(_confirm)
	footer.add_child(confirm)

	_update_detail(_selected)
	_refresh_cards()


func _make_card(cid: String) -> Button:
	var ch := Data.character_def(cid)
	var col := Color(String(ch["color"]))
	var b := Button.new()
	b.custom_minimum_size = Vector2(140, 140)
	b.focus_mode = Control.FOCUS_NONE
	b.text = ""
	b.add_theme_stylebox_override("normal", _card_style(col, false))
	b.add_theme_stylebox_override("hover", _card_style(col, true))
	b.add_theme_stylebox_override("pressed", UiKit.stylebox(Color(0.045, 0.055, 0.07, 0.98), UiKit.COL_GOLD, 2, 8))
	b.pressed.connect(_select.bind(cid))
	_cards[cid] = b

	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	b.add_child(v)
	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(110, 110)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.modulate = Color(String(ch.get("tint", "#ffffff")))
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var portrait_path := String(ch.get("portrait", ""))
	if portrait_path != "":
		var face := load(portrait_path) as Texture2D
		if face != null:
			portrait.texture = face
	else:
		var sheet := load(String(ch["sprite"])) as Texture2D
		if sheet != null:
			if bool(ch.get("static", false)):
				portrait.texture = sheet
			else:
				var frame := AtlasTexture.new()
				frame.atlas = sheet
				frame.region = Rect2(0, 0, 16, 16)
				portrait.texture = frame
	v.add_child(portrait)
	return b


func _card_style(col: Color, hover: bool) -> StyleBoxFlat:
	var bg := Color(0.055, 0.068, 0.085, 0.96)
	if hover:
		bg = Color(0.085, 0.10, 0.12, 0.98)
	var border := col.lightened(0.18) if hover else col
	return UiKit.stylebox(bg, border, 2, 8)


func _select(cid: String) -> void:
	_selected = cid
	_update_detail(cid)
	_refresh_cards()


func _refresh_cards() -> void:
	for cid in _cards:
		var b: Button = _cards[cid]
		var ch := Data.character_def(cid)
		var col := Color(String(ch["color"]))
		var border_col := UiKit.COL_GOLD if cid == _selected else col
		b.add_theme_stylebox_override("normal", UiKit.stylebox(Color(0.055, 0.068, 0.085, 0.96), border_col, 2, 8))
		b.add_theme_stylebox_override("hover", UiKit.stylebox(Color(0.085, 0.10, 0.12, 0.98), border_col, 2, 8))
		b.add_theme_stylebox_override("pressed", UiKit.stylebox(Color(0.045, 0.055, 0.07, 0.98), UiKit.COL_GOLD, 2, 8))


func _update_detail(cid: String) -> void:
	var ch := Data.character_def(cid)
	_detail_name.text = String(ch["name"])
	_detail_name.add_theme_color_override("font_color", Color(String(ch["color"])))
	_detail_talent.text = "天赋 · %s" % String(ch["title"])
	_detail_bonus.text = String(ch["bonus_text"]).replace("\n", "    ")


func _confirm() -> void:
	character_chosen.emit(_selected)
