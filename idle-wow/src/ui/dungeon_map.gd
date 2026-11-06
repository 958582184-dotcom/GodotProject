class_name DungeonMap
extends Control

signal node_pressed(dungeon)

const MAP_W := 808.0
const MAP_H := 320.0
const NODE_W := 60.0
const NODE_H := 68.0

var _nodes: Array[Button] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	custom_minimum_size = Vector2(MAP_W, MAP_H)
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	queue_redraw()


func setup(dungeons: Array) -> void:
	for n in _nodes:
		if is_instance_valid(n):
			n.queue_free()
	_nodes.clear()
	_rng.seed = 7100 + Game.area_index * 977 + (int(dungeons[0]["uid"]) if not dungeons.is_empty() else Time.get_ticks_usec())
	var used: Array[Vector2] = []
	for d in dungeons:
		var pos := _find_pos(used)
		used.append(pos)
		_add_node(d, pos)
	if Game.boss_ready():
		var pos := _find_pos(used, 64.0, 74.0)
		var area := Game.current_area()
		var boss_level := clampi(Game.level, int(area["min_level"]), int(area["max_level"]))
		_add_boss_node(pos, boss_level)
	queue_redraw()


func _find_pos(used: Array[Vector2], nw: float = NODE_W, nh: float = NODE_H) -> Vector2:
	var pos := Vector2.ZERO
	for attempt in 60:
		pos = Vector2(
			_rng.randf_range(22.0, MAP_W - nw - 22.0),
			_rng.randf_range(26.0, 218.0 - nh))
		var ok := true
		for u in used:
			if pos.distance_to(u) < 66.0:
				ok = false
				break
		if ok:
			break
	return pos


func _add_node(d: Dictionary, pos: Vector2) -> void:
	var diff := String(d["difficulty"])
	var col := Data.difficulty_color(diff)
	var is_current := int(Game.current_dungeon.get("uid", -1)) == int(d.get("uid", -2))
	var b := Button.new()
	b.custom_minimum_size = Vector2(NODE_W, NODE_H)
	b.size = Vector2(NODE_W, NODE_H)
	b.position = pos
	b.text = ""
	var border := UiKit.COL_GOLD if is_current else col
	b.add_theme_stylebox_override("normal", UiKit.stylebox(Color(0.075, 0.065, 0.055, 0.94), border, 2, 3))
	b.add_theme_stylebox_override("hover", UiKit.stylebox(Color(0.10, 0.085, 0.07, 0.98), UiKit.COL_GOLD, 2, 3))
	b.add_theme_stylebox_override("pressed", UiKit.stylebox(Color(0.06, 0.052, 0.045, 0.98), UiKit.COL_GOLD, 2, 3))
	b.tooltip_text = "%s · %s\n3 小怪 + 1 精英" % [Data.dungeon_title(d), Data.DIFFICULTIES[diff]["name"]]
	b.pressed.connect(_on_node.bind(d))

	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 0)
	b.add_child(v)
	var icon := TextureRect.new()
	icon.texture = _icon_for(diff)
	icon.custom_minimum_size = Vector2(30, 30)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.modulate = _icon_tint(diff)
	v.add_child(icon)
	var lab := UiKit.label(_node_label(d), 10, col)
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(lab)
	add_child(b)
	_nodes.append(b)


func _add_boss_node(pos: Vector2, boss_level: int) -> void:
	var b := Button.new()
	b.custom_minimum_size = Vector2(64, 74)
	b.size = Vector2(64, 74)
	b.position = pos
	b.text = ""
	b.add_theme_stylebox_override("normal", UiKit.stylebox(Color(0.09, 0.045, 0.04, 0.96), UiKit.COL_RED, 2, 3))
	b.add_theme_stylebox_override("hover", UiKit.stylebox(Color(0.13, 0.06, 0.05, 0.98), UiKit.COL_GOLD, 2, 3))
	b.add_theme_stylebox_override("pressed", UiKit.stylebox(Color(0.07, 0.035, 0.03, 0.98), UiKit.COL_GOLD, 2, 3))
	b.tooltip_text = "%s\n探索度已满，击败后清零" % Data.boss_title(boss_level)
	b.pressed.connect(func(): node_pressed.emit({"kind": "boss"}))

	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 0)
	b.add_child(v)
	var icon := TextureRect.new()
	icon.texture = _icon_for("boss")
	icon.custom_minimum_size = Vector2(32, 32)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(icon)
	var lab := UiKit.label("Lv.%d\n首领" % boss_level, 10, UiKit.COL_RED)
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(lab)
	add_child(b)
	_nodes.append(b)


func _icon_for(diff: String) -> Texture2D:
	var path := "res://assets/monsters/slime.png"
	var region := Rect2(0, 0, 16, 16)
	if diff == "elite" or diff == "hero":
		path = "res://assets/monsters/cyclope.png"
	elif diff == "boss":
		path = "res://assets/monsters/boss_walk.png"
		region = Rect2(0, 0, 50, 50)
	var at := AtlasTexture.new()
	at.atlas = load(path)
	at.region = region
	return at


func _icon_tint(diff: String) -> Color:
	match diff:
		"elite":
			return Color(1.0, 0.88, 0.62)
		"hero":
			return Color(1.0, 0.62, 0.52)
		_:
			return Color.WHITE


func _node_label(d: Dictionary) -> String:
	var lvl := str(int(d["level"]))
	match String(d["difficulty"]):
		"elite":
			return "Lv.%s\n精英" % lvl
		"hero":
			return "Lv.%s\n英雄" % lvl
		_:
			return "Lv.%s" % lvl


func _on_node(d: Dictionary) -> void:
	node_pressed.emit(d)


func _draw() -> void:
	var w := maxf(size.x, MAP_W)
	var h := maxf(size.y, MAP_H)
	var pal := _palette()
	var paper: Color = pal["paper"]
	var ink: Color = pal["ink"]
	var sea: Color = pal["sea"]
	var water: Color = pal["water"]
	var forest: Color = pal["forest"]
	var mountain: Color = pal["mountain"]
	var road: Color = pal["road"]
	var snow: Color = pal["snow"]

	draw_rect(Rect2(0, 0, w, h), paper)
	for i in 110:
		var x := 8.0 + fmod(float(i) * 71.0, w - 16.0)
		var y := 8.0 + fmod(float(i) * 43.0, h - 16.0)
		draw_rect(Rect2(x, y, 2.0 + float(i % 3), 1), Color(ink, 0.045))
	for i in 40:
		var x := fmod(float(i) * 127.0, w)
		var y := fmod(float(i) * 61.0, h)
		draw_rect(Rect2(x, y, 6, 3), Color(1, 1, 1, 0.035))

	var sea_edge_raw := PackedVector2Array([
		Vector2(w * 0.60, h), Vector2(w * 0.62, h * 0.82),
		Vector2(w * 0.70, h * 0.73), Vector2(w * 0.67, h * 0.60),
		Vector2(w * 0.78, h * 0.52), Vector2(w * 0.82, h * 0.66),
		Vector2(w * 0.90, h * 0.76), Vector2(w, h * 0.70),
	])
	var sea_edge := _smooth(sea_edge_raw, 9)
	var sea_poly := sea_edge.duplicate()
	sea_poly.append(Vector2(w, h))
	draw_colored_polygon(sea_poly, sea)
	draw_polyline(sea_edge, paper.lightened(0.14), 4.0)
	draw_polyline(sea_edge, Color(ink, 0.55), 1.4)
	for i in 9:
		var wx := w * 0.68 + i * 24.0
		var wy := h * 0.80 + (i % 3) * 11.0
		draw_line(Vector2(wx, wy), Vector2(wx + 13, wy), Color(1, 1, 1, 0.18), 1.0)

	var river_raw := PackedVector2Array([
		Vector2(w * 0.15, -10), Vector2(w * 0.17, h * 0.18),
		Vector2(w * 0.12, h * 0.34), Vector2(w * 0.22, h * 0.49),
		Vector2(w * 0.30, h * 0.62), Vector2(w * 0.36, h * 0.78),
		Vector2(w * 0.50, h * 0.90), Vector2(w * 0.61, h),
	])
	var river := _smooth(river_raw, 9)
	draw_polyline(river, paper.darkened(0.10), 15.0)
	draw_polyline(river, water.darkened(0.08), 9.0)
	draw_polyline(river, water.lightened(0.16), 2.0)

	var road_raw := PackedVector2Array([
		Vector2(w * 0.06, h * 0.72), Vector2(w * 0.22, h * 0.65),
		Vector2(w * 0.33, h * 0.48), Vector2(w * 0.48, h * 0.42),
		Vector2(w * 0.60, h * 0.30), Vector2(w * 0.76, h * 0.28),
	])
	var road_pts := _smooth(road_raw, 10)
	draw_polyline(road_pts, Color(ink, 0.24), 8.0)
	draw_polyline(road_pts, Color(road, 0.88), 5.0)
	draw_polyline(road_pts, Color(road.lightened(0.14), 0.5), 1.4)
	for i in range(5, road_pts.size() - 5, 7):
		draw_circle(road_pts[i], 1.3, Color(road.lightened(0.22), 0.65))

	_mountain(w * 0.16, h * 0.34, 46, pal)
	_mountain(w * 0.25, h * 0.28, 34, pal)
	_mountain(w * 0.45, h * 0.25, 52, pal)
	_mountain(w * 0.56, h * 0.32, 36, pal)
	_mountain(w * 0.78, h * 0.22, 44, pal)

	var trees := [
		Vector2(w * 0.05, h * 0.22), Vector2(w * 0.10, h * 0.27),
		Vector2(w * 0.07, h * 0.32), Vector2(w * 0.30, h * 0.72),
		Vector2(w * 0.34, h * 0.68), Vector2(w * 0.38, h * 0.74),
		Vector2(w * 0.48, h * 0.58), Vector2(w * 0.51, h * 0.54),
		Vector2(w * 0.55, h * 0.60), Vector2(w * 0.70, h * 0.50),
		Vector2(w * 0.74, h * 0.46), Vector2(w * 0.71, h * 0.84),
		Vector2(w * 0.76, h * 0.80), Vector2(w * 0.80, h * 0.86),
	]
	for p in trees:
		_tree(p.x, p.y, 1.0, forest, ink)

	_ruin(w * 0.40, h * 0.82, ink)
	_ruin(w * 0.58, h * 0.18, ink)

	var cx := w - 42.0
	var cy := 38.0
	draw_circle(Vector2(cx, cy), 16, Color(paper.darkened(0.06), 0.9))
	draw_arc(Vector2(cx, cy), 16, 0, TAU, 32, ink, 1.2)
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx, cy - 12), Vector2(cx + 4, cy), Vector2(cx, cy + 1), Vector2(cx - 4, cy),
	]), ink)
	draw_string(ThemeDB.fallback_font, Vector2(cx - 4, cy + 14), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, ink)

	draw_rect(Rect2(4, 4, w - 8, h - 8), Color(ink, 0.55), false, 2.0)
	draw_rect(Rect2(9, 9, w - 18, h - 18), Color(ink, 0.22), false, 1.0)
	for p in [Vector2(4, 4), Vector2(w - 4, 4), Vector2(4, h - 4), Vector2(w - 4, h - 4)]:
		draw_circle(p, 3.0, ink)


func _smooth(points: PackedVector2Array, steps: int = 8) -> PackedVector2Array:
	var out := PackedVector2Array()
	if points.size() < 2:
		return points
	for i in range(points.size() - 1):
		var p0 := points[maxi(i - 1, 0)]
		var p1 := points[i]
		var p2 := points[i + 1]
		var p3 := points[mini(i + 2, points.size() - 1)]
		for s in steps:
			var t := float(s) / float(steps)
			var t2 := t * t
			var t3 := t2 * t
			out.append(0.5 * (
				(2.0 * p1)
				+ (-p0 + p2) * t
				+ (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
				+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
			))
	out.append(points[points.size() - 1])
	return out


func _palette() -> Dictionary:
	match Game.area_index:
		1:
			return {
				"paper": Color("#b6c1c5"), "ink": Color("#2f3a3e"), "sea": Color("#496970"),
				"water": Color("#7ba3a3"), "forest": Color("#4d6260"), "mountain": Color("#849092"),
				"road": Color("#8c7e66"), "snow": Color("#e8eef0"),
			}
		2:
			return {
				"paper": Color("#8b5c48"), "ink": Color("#2b1c18"), "sea": Color("#4a2a25"),
				"water": Color("#b85f43"), "forest": Color("#3d332b"), "mountain": Color("#4f3b33"),
				"road": Color("#70543d"), "snow": Color("#e8a878"),
			}
		_:
			return {
				"paper": Color("#c2b183"), "ink": Color("#3d3428"), "sea": Color("#45696b"),
				"water": Color("#628c85"), "forest": Color("#3d5638"), "mountain": Color("#6d6354"),
				"road": Color("#8b7554"), "snow": Color("#e7e0cc"),
			}


func _mountain(x: float, base_y: float, size: float, pal: Dictionary) -> void:
	var ink: Color = pal["ink"]
	var m: Color = pal["mountain"]
	var snow: Color = pal["snow"]
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - size, base_y), Vector2(x, base_y - size * 1.15), Vector2(x + size, base_y),
	]), m.darkened(0.22))
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - size * 0.7, base_y), Vector2(x + size * 0.1, base_y - size * 0.95),
		Vector2(x + size * 0.65, base_y),
	]), m)
	draw_polyline(PackedVector2Array([
		Vector2(x - size, base_y), Vector2(x, base_y - size * 1.15),
		Vector2(x + size, base_y),
	]), ink, 1.2)
	var peak := Vector2(x, base_y - size * 1.15)
	draw_colored_polygon(PackedVector2Array([
		peak, Vector2(peak.x - size * 0.28, peak.y + size * 0.38),
		Vector2(peak.x + size * 0.20, peak.y + size * 0.34),
	]), snow)


func _tree(x: float, y: float, s: float, forest: Color, ink: Color) -> void:
	draw_rect(Rect2(x - 2 * s, y - 6 * s, 4 * s, 11 * s), ink)
	draw_circle(Vector2(x, y - 16 * s), 11 * s, forest)
	draw_circle(Vector2(x - 7 * s, y - 11 * s), 8 * s, forest.lightened(0.06))
	draw_circle(Vector2(x + 7 * s, y - 11 * s), 8 * s, forest.darkened(0.08))
	draw_circle(Vector2(x, y - 23 * s), 7 * s, forest.lightened(0.12))


func _ruin(x: float, y: float, ink: Color) -> void:
	draw_rect(Rect2(x - 24, y - 6, 48, 5), Color(ink, 0.65))
	draw_rect(Rect2(x - 26, y - 18, 7, 16), ink)
	draw_rect(Rect2(x - 8, y - 24, 6, 22), ink)
	draw_rect(Rect2(x + 10, y - 14, 7, 13), ink)
	draw_rect(Rect2(x + 18, y - 26, 8, 20), ink)
	draw_line(Vector2(x - 20, y - 12), Vector2(x - 20, y - 2), Color(1, 1, 1, 0.15), 1.0)
	draw_line(Vector2(x - 3, y - 20), Vector2(x - 3, y - 8), Color(1, 1, 1, 0.15), 1.0)
