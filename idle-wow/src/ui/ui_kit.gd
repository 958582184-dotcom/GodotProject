class_name UiKit
extends RefCounted

const COL_BG := Color(0.043, 0.055, 0.086)
const COL_PANEL := Color(0.071, 0.090, 0.125, 0.98)
const COL_PANEL_2 := Color(0.102, 0.129, 0.173, 1.0)
const COL_PANEL_3 := Color(0.137, 0.169, 0.220, 1.0)
const COL_BORDER := Color(0.235, 0.286, 0.353)
const COL_BORDER_DIM := Color(0.145, 0.180, 0.230)
const COL_GOLD := Color(0.878, 0.706, 0.353)
const COL_GOLD_DIM := Color(0.549, 0.435, 0.216)
const COL_TEXT := Color(0.855, 0.882, 0.918)
const COL_MUTED := Color(0.541, 0.596, 0.663)
const COL_DIM := Color(0.365, 0.412, 0.475)
const COL_RED := Color(0.945, 0.357, 0.333)
const COL_GREEN := Color(0.420, 0.847, 0.455)
const COL_TEAL := Color(0.373, 0.816, 0.753)
const COL_BLUE := Color(0.357, 0.639, 0.933)

static var _theme: Theme
static var _font: Font
static var _icons: Dictionary = {}


static func font() -> Font:
	if _font != null:
		return _font
	var sys := SystemFont.new()
	sys.font_names = PackedStringArray(["Microsoft YaHei UI", "Microsoft YaHei", "Segoe UI", "Noto Sans CJK SC", "sans-serif"])
	sys.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	sys.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
	sys.font_weight = 600
	_font = sys
	return _font


static func theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font = font()
	t.default_font_size = 19
	t.set_color("font_color", "Label", COL_TEXT)
	t.set_color("font_color", "RichTextLabel", COL_TEXT)
	t.set_stylebox("panel", "PanelContainer", stylebox(COL_PANEL, COL_BORDER, 1, 0))

	var normal := stylebox(COL_PANEL_2, COL_BORDER, 1, 12)
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	var hover := stylebox(COL_PANEL_3, COL_GOLD, 1, 12)
	hover.content_margin_top = 8
	hover.content_margin_bottom = 8
	var pressed := stylebox(COL_BG, COL_GOLD, 1, 12)
	pressed.content_margin_top = 9
	pressed.content_margin_bottom = 7
	var disabled := stylebox(Color(0.09, 0.10, 0.13, 0.7), COL_BORDER_DIM, 1, 12)
	disabled.content_margin_top = 8
	disabled.content_margin_bottom = 8
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("disabled", "Button", disabled)
	t.set_stylebox("focus", "Button", stylebox(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0))
	t.set_color("font_color", "Button", COL_TEXT)
	t.set_color("font_hover_color", "Button", Color(1.0, 0.918, 0.745))
	t.set_color("font_pressed_color", "Button", COL_GOLD)
	t.set_color("font_disabled_color", "Button", COL_DIM)
	t.set_font_size("font_size", "Button", 19)

	var bar_bg := stylebox(Color(0.035, 0.043, 0.063, 0.95), COL_BORDER_DIM, 1, 0)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = COL_GOLD
	bar_fill.set_border_width_all(0)
	t.set_stylebox("background", "ProgressBar", bar_bg)
	t.set_stylebox("fill", "ProgressBar", bar_fill)
	t.set_color("font_color", "ProgressBar", COL_TEXT)

	var sb_bg := StyleBoxFlat.new()
	sb_bg.bg_color = Color(0.06, 0.075, 0.10)
	t.set_stylebox("scroll", "VScrollBar", sb_bg)
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = COL_BORDER
	t.set_stylebox("grabber", "VScrollBar", grabber)
	var grabber_hl := StyleBoxFlat.new()
	grabber_hl.bg_color = COL_GOLD_DIM
	t.set_stylebox("grabber_highlight", "VScrollBar", grabber_hl)
	t.set_stylebox("grabber_pressed", "VScrollBar", grabber_hl)
	_theme = t
	return t


static func stylebox(bg: Color, border: Color, bw: int = 1, pad: int = 10) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(0)
	sb.anti_aliasing = false
	sb.content_margin_left = pad
	sb.content_margin_right = pad
	sb.content_margin_top = pad
	sb.content_margin_bottom = pad
	return sb


static func label(text: String, size: int = 15, color: Color = COL_TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font())
	l.add_theme_font_size_override("font_size", size + 4)
	l.add_theme_color_override("font_color", color)
	return l


static func rich(text: String) -> Label:
	var l := label(text)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func button(text: String, size: int = 15) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", font())
	b.add_theme_font_size_override("font_size", size + 4)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return b


static func icon_button(icon_name: String, tip: String = "", px: int = 20) -> Button:
	var b := button("")
	b.icon = icon(icon_name)
	b.expand_icon = true
	b.custom_minimum_size = Vector2(px + 16, px + 12)
	if tip != "":
		b.tooltip_text = tip
	return b


static func panel(bg: Color = COL_PANEL, border: Color = COL_BORDER, bw: int = 1, pad: int = 12) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", stylebox(bg, border, bw, pad))
	return p


static func hsep(color: Color = COL_BORDER_DIM) -> Control:
	var line := ColorRect.new()
	line.color = color
	line.custom_minimum_size = Vector2(0, 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line


static func spacer() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func icon(icon_name: String) -> Texture2D:
	if _icons.has(icon_name):
		return _icons[icon_name]
	var path := "res://assets/icons/%s.png" % icon_name
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path)
	_icons[icon_name] = tex
	return tex


static func icon_for_item(item: GameItem) -> Texture2D:
	if item == null:
		return null
	return icon(item.icon_key())


static func progress(value: float, max_value: float, height: int = 8, fill: Color = COL_GOLD) -> ProgressBar:
	var p := ProgressBar.new()
	p.max_value = max_value
	p.value = value
	p.show_percentage = false
	p.custom_minimum_size = Vector2(0, height)
	p.add_theme_stylebox_override("background", stylebox(Color(0.035, 0.043, 0.063, 0.95), COL_BORDER_DIM, 1, 0))
	var f := StyleBoxFlat.new()
	f.bg_color = fill
	f.set_border_width_all(0)
	p.add_theme_stylebox_override("fill", f)
	return p


static func num(value: int) -> String:
	var neg := value < 0
	var digits := str(absi(value))
	var out := ""
	var count := 0
	for i in range(digits.length() - 1, -1, -1):
		out = digits[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if neg else "") + out


static func pct(value: float, digits: int = 1) -> String:
	return ("%." + str(digits) + "f%%") % (value * 100.0)


static func stat_color(key: String) -> Color:
	match key:
		"strength": return Color(0.95, 0.55, 0.45)
		"agility": return Color(0.55, 0.90, 0.55)
		"intellect": return Color(0.55, 0.72, 1.0)
		"stamina": return Color(0.95, 0.80, 0.45)
		_: return COL_TEXT
