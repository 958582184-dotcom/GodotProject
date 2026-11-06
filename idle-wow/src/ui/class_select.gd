class_name ClassSelect
extends Control

signal chosen(class_id: String)

var _built := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()


func _build() -> void:
	_built = true
	var dim := ColorRect.new()
	dim.color = Color(0.016, 0.021, 0.031, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var panel := UiKit.panel(Color(0.055, 0.071, 0.098, 0.99), UiKit.COL_GOLD_DIM, 2, 0)
	panel.size = Vector2(1160, 620)
	panel.position = Vector2(60, 50)
	add_child(panel)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)
	panel.add_child(outer)

	var accent := ColorRect.new()
	accent.color = UiKit.COL_GOLD
	accent.custom_minimum_size = Vector2(0, 3)
	outer.add_child(accent)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	outer.add_child(margin)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	margin.add_child(v)

	var title := UiKit.label(Data.TITLE, 44, UiKit.COL_GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var sub := UiKit.label("挂机 · 刷装备 · 像素远征     选择职业后本局不可更换", 14, UiKit.COL_MUTED)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	v.add_child(UiKit.hsep())
	v.add_child(UiKit.spacer())

	var cards := HBoxContainer.new()
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation", 20)
	cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(cards)
	for cid in Data.CLASS_ORDER:
		cards.add_child(_make_card(cid))

	v.add_child(UiKit.spacer())
	var foot := UiKit.label("参考魔兽：没有技能，只有职业倾向与一身装备。", 12, UiKit.COL_DIM)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(foot)


func _make_card(cid: String) -> PanelContainer:
	var cls: Dictionary = Data.CLASSES[cid]
	var col := Color(cls["color"])
	var p := UiKit.panel(UiKit.COL_PANEL_2, col.darkened(0.25), 2, 18)
	p.custom_minimum_size = Vector2(340, 430)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	p.add_child(v)

	var portrait_frame := UiKit.panel(Color(0.035, 0.047, 0.067), col.darkened(0.4), 1, 8)
	portrait_frame.custom_minimum_size = Vector2(112, 112)
	portrait_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var at := AtlasTexture.new()
	at.atlas = load(String(cls["sprite"]))
	at.region = Rect2(48, 0, 16, 16)
	var pic := TextureRect.new()
	pic.texture = at
	pic.custom_minimum_size = Vector2(88, 88)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait_frame.add_child(pic)
	v.add_child(portrait_frame)

	var name_label := UiKit.label(String(cls["name"]), 28, col)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(name_label)
	var role := UiKit.label(String(cls["role"]), 13, UiKit.COL_GOLD)
	role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(role)

	var desc := UiKit.label(String(cls["desc"]), 13, UiKit.COL_TEXT)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(290, 62)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(desc)

	var base: Dictionary = cls["base"]
	var sg := GridContainer.new()
	sg.columns = 2
	sg.add_theme_constant_override("h_separation", 24)
	sg.add_theme_constant_override("v_separation", 2)
	sg.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for key in ["strength", "agility", "intellect", "stamina"]:
		sg.add_child(UiKit.label("%s %d" % [Data.PRIMARY_NAMES[key], int(base[key])], 12, UiKit.stat_color(key)))
	v.add_child(sg)

	v.add_child(UiKit.spacer())
	var btn := UiKit.button("选择 %s" % cls["name"], 16)
	btn.custom_minimum_size = Vector2(0, 42)
	btn.pressed.connect(chosen.emit.bind(cid))
	v.add_child(btn)
	return p
