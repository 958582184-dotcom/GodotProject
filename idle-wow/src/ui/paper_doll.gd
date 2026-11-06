class_name PaperDoll
extends Control


func _ready() -> void:
	custom_minimum_size = Vector2(350, 340)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	# 背景光晕与地面
	draw_circle(Vector2(165, 166), 132.0, Color(0.10, 0.13, 0.18, 0.55))
	draw_circle(Vector2(165, 166), 110.0, Color(0.13, 0.16, 0.22, 0.38))
	_ellipse(Vector2(165, 302), Vector2(78, 12), Color(0.01, 0.015, 0.025, 0.55))

	var fill := Color(0.135, 0.165, 0.220, 0.97)
	var rim := Color(0.42, 0.48, 0.58, 0.85)
	var gold := Color(0.78, 0.64, 0.36, 0.75)

	# 腿与脚
	_limb(Vector2(151, 192), Vector2(147, 254), 16.0, fill, rim)
	_limb(Vector2(179, 192), Vector2(183, 254), 16.0, fill, rim)
	_limb(Vector2(147, 250), Vector2(145, 286), 14.0, fill, rim)
	_limb(Vector2(183, 250), Vector2(185, 286), 14.0, fill, rim)
	_ellipse(Vector2(138, 290), Vector2(23, 9), rim)
	_ellipse(Vector2(138, 290), Vector2(19, 7), fill)
	_ellipse(Vector2(192, 290), Vector2(23, 9), rim)
	_ellipse(Vector2(192, 290), Vector2(19, 7), fill)

	# 手臂
	_limb(Vector2(131, 92), Vector2(104, 142), 15.0, fill, rim)
	_limb(Vector2(104, 142), Vector2(78, 177), 13.0, fill, rim)
	_limb(Vector2(199, 92), Vector2(226, 142), 15.0, fill, rim)
	_limb(Vector2(226, 142), Vector2(252, 177), 13.0, fill, rim)
	draw_circle(Vector2(75, 181), 10.0, rim)
	draw_circle(Vector2(75, 181), 8.0, fill)
	draw_circle(Vector2(255, 181), 10.0, rim)
	draw_circle(Vector2(255, 181), 8.0, fill)

	# 躯干
	var torso := PackedVector2Array([
		Vector2(128, 76), Vector2(202, 76), Vector2(196, 108),
		Vector2(190, 168), Vector2(140, 168), Vector2(134, 108),
	])
	draw_colored_polygon(torso, fill)
	var torso_line := torso.duplicate()
	torso_line.append(torso[0])
	draw_polyline(torso_line, rim, 2.0)

	# 骨盆
	var pelvis := PackedVector2Array([
		Vector2(140, 166), Vector2(190, 166), Vector2(184, 198), Vector2(146, 198),
	])
	draw_colored_polygon(pelvis, fill)
	var pelvis_line := pelvis.duplicate()
	pelvis_line.append(pelvis[0])
	draw_polyline(pelvis_line, rim, 2.0)

	# 脖子与头
	draw_rect(Rect2(156, 48, 18, 24), fill)
	draw_rect(Rect2(156, 48, 18, 24), rim, false, 2.0)
	draw_circle(Vector2(165, 28), 25.0, rim)
	draw_circle(Vector2(165, 28), 22.0, fill)

	# 金色束带与肩线
	draw_line(Vector2(141, 171), Vector2(189, 171), gold, 2.0)
	draw_line(Vector2(134, 108), Vector2(196, 108), Color(0.55, 0.60, 0.68, 0.5), 1.0)
	draw_line(Vector2(154, 72), Vector2(176, 72), gold, 1.5)
	draw_line(Vector2(132, 82), Vector2(150, 82), gold, 1.0)
	draw_line(Vector2(180, 82), Vector2(198, 82), gold, 1.0)
	draw_line(Vector2(146, 198), Vector2(150, 252), Color(0.26, 0.31, 0.38, 0.5), 1.0)
	draw_line(Vector2(184, 198), Vector2(180, 252), Color(0.26, 0.31, 0.38, 0.5), 1.0)

	draw_rect(Rect2(0.5, 0.5, 349, 339), Color(0.24, 0.29, 0.37, 0.55), false, 1.0)


func _limb(a: Vector2, b: Vector2, width: float, fill: Color, rim: Color) -> void:
	draw_line(a, b, rim, width + 3.0)
	draw_line(a, b, fill, width)


func _ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 28:
		var a := TAU * float(i) / 28.0
		pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	draw_colored_polygon(pts, color)
