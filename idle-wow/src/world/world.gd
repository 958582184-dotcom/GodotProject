class_name World
extends Node2D

const GROUND_Y := 646.0
const CHAR_X := 590.0
const MEET_X := 650.0
const ROAD_TOP := 646.0
const HORIZON_RECT := Rect2(390, 646, 500, 18)
const CHAR_SIZE := 45.0
const MONSTER_SPAWN_X := 860.0

var hud: Node

var _character: AnimatedSprite2D
var _char_shadow: Sprite2D
var _player_bar: ProgressBar
var _shield_bar: ProgressBar
var _combat_hp := 0.0
var _combat_hp_max := 0.0
var _camera: Camera2D
var _busy := false
var _time := 0.0
var _class_id := "warrior"
var _auto_token := 0

var _rng := RandomNumberGenerator.new()
var _sky: GradientTexture2D
var _stars: Array = []
var _clouds: Array = []
var _motes: Array = []
var _tufts: Array = []
var _pebbles: Array = []
var _trees: Array = []
var _far_hills: PackedVector2Array
var _mid_hills: PackedVector2Array


func _ready() -> void:
	_rng.seed = 20261105
	_camera = Camera2D.new()
	_camera.position = Vector2(640, 360)
	_camera.enabled = true
	add_child(_camera)
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	# 草坪/地板：按钮紧贴在它下面
	var r := HORIZON_RECT
	draw_rect(r, Color(0.095, 0.145, 0.085))
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 3), Color(0.28, 0.42, 0.20))
	draw_rect(Rect2(r.position.x, r.position.y + r.size.y - 3, r.size.x, 3), Color(0.055, 0.085, 0.050))
	for i in 46:
		var x := r.position.x + 8.0 + i * 10.7
		var h := 3.0 + float((i * 7) % 4)
		var c := Color(0.30, 0.47, 0.22, 0.75) if i % 3 != 0 else Color(0.22, 0.36, 0.17, 0.75)
		draw_line(Vector2(x, r.position.y + 3), Vector2(x - 1.5, r.position.y + 3 - h), c, 1.0)
		draw_line(Vector2(x + 2.0, r.position.y + 4), Vector2(x + 3.0, r.position.y + 2), c, 1.0)
	for i in 9:
		var fx := r.position.x + 24.0 + i * 52.0
		draw_rect(Rect2(fx, r.position.y + 7, 2, 2), Color(0.68, 0.55, 0.30, 0.8))



# ---------- 角色 ----------

func set_class(cid: String) -> void:
	_class_id = cid
	if _character != null:
		_character.queue_free()
		_character = null
	if _char_shadow != null:
		_char_shadow.queue_free()
		_char_shadow = null
	if _player_bar != null:
		_player_bar.queue_free()
		_player_bar = null
	if _shield_bar != null:
		_shield_bar.queue_free()
		_shield_bar = null
	var cls: Dictionary = Data.class_def(cid)
	var ch: Dictionary = Data.character_def(cid)
	var tex: Texture2D = load(String(ch["sprite"]))
	var frame_w := int(ch.get("frame_w", 16))
	var frame_h := int(ch.get("frame_h", 16))
	var is_static := bool(ch.get("static", false))

	var sf := SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
	sf.add_animation("run")
	sf.set_animation_speed("run", 9.0)
	sf.set_animation_loop("run", true)
	for i in 4:
		var at := AtlasTexture.new()
		at.atlas = tex
		if is_static:
			at.region = Rect2(0, 0, frame_w, frame_h)
		else:
			at.region = Rect2(48, i * 16, 16, 16)
		sf.add_frame("run", at)

	_character = AnimatedSprite2D.new()
	_character.sprite_frames = sf
	_character.position = Vector2(CHAR_X, GROUND_Y - CHAR_SIZE * 0.5)
	_character.scale = Vector2(CHAR_SIZE / float(frame_h), CHAR_SIZE / float(frame_h))
	_character.modulate = Color(String(ch.get("tint", "#ffffff")))
	_character.play("run")
	add_child(_character)

	_char_shadow = Sprite2D.new()
	_char_shadow.texture = load("res://assets/icons/shadow.png")
	_char_shadow.position = Vector2(CHAR_X, GROUND_Y - 1)
	_char_shadow.scale = Vector2(1.05, 0.9)
	_char_shadow.modulate = Color(0, 0, 0, 0.55)
	_char_shadow.visible = true
	add_child(_char_shadow)

	_player_bar = UiKit.progress(1.0, 1.0, 6, Color("#63c76a"))
	_player_bar.position = Vector2(CHAR_X - 27.0, GROUND_Y + 2.0)
	_player_bar.size = Vector2(54, 6)
	_player_bar.show_percentage = false
	_player_bar.visible = false
	add_child(_player_bar)
	_shield_bar = UiKit.progress(1.0, 1.0, 3, Color("#6fa8dc"))
	_shield_bar.position = Vector2(CHAR_X - 27.0, GROUND_Y - 2.0)
	_shield_bar.size = Vector2(54, 3)
	_shield_bar.show_percentage = false
	_shield_bar.visible = false
	add_child(_shield_bar)
	_update_player_bar()


# ---------- 副本 ----------

func start_dungeon(d: Dictionary) -> void:
	if _busy:
		return
	_auto_token += 1
	_busy = true
	Game.current_dungeon = d
	Game.set_busy(true)
	var title := Data.dungeon_title(d)
	var is_boss_run: bool = String(d.get("kind", "normal")) == "boss"
	_combat_hp_max = float(Game.compute_stats().get("hp_max", 1.0))
	_combat_hp = _combat_hp_max
	_set_player_hp(_combat_hp, _combat_hp_max, true)
	if _shield_bar != null:
		_shield_bar.value = 0.0
		_shield_bar.visible = false
	if hud != null:
		hud.set_stage("%s  0/%d" % [title, d["monsters"].size()])
		if is_boss_run:
			hud.add_log("进入 %s" % title, UiKit.COL_GOLD)
		else:
			hud.add_log("进入 %s（%s）" % [title, Data.DIFFICULTIES[d["difficulty"]]["name"]], UiKit.COL_GOLD)
	var cleared: bool = await _run_dungeon(d)
	if _player_bar != null:
		_player_bar.visible = false
	if _shield_bar != null:
		_shield_bar.visible = false
	if hud != null:
		hud.clear_stage()
	_busy = false
	Game.set_busy(false)
	Game.save_game()

	if not cleared:
		Game.set_auto_mode("off")
		return
	if Game.boss_ready():
		return
	if Game.auto_mode != "off":
		await _wait(0.6)
		resume_auto(0.1)


func resume_auto(delay: float = 0.6) -> void:
	if _busy or Game.auto_mode == "off" or Game.class_id == "":
		return
	if Game.boss_ready():
		return
	if hud != null and hud.has_open_window():
		return
	if Game.inventory_count() >= Data.INVENTORY_SIZE and not Game.auto_sell:
		Game.toast.emit("背包已满，自动副本暂停", Color("#ff7b72"))
		return
	_auto_token += 1
	var token := _auto_token
	await get_tree().create_timer(delay / maxf(0.25, Game.speed_mult)).timeout
	if token != _auto_token or _busy or Game.auto_mode == "off":
		return
	if hud != null and hud.has_open_window():
		return
	if Game.boss_ready():
		return
	var d: Dictionary = Game.pick_auto_dungeon()
	if d.is_empty():
		return
	start_dungeon(d)


func _run_dungeon(d: Dictionary) -> bool:
	var monsters: Array = d["monsters"]
	var total: int = monsters.size()
	var cleared := true
	var is_boss: bool = d.get("kind", "normal") == "boss"
	var base_level := int(d["level"])
	var title := Data.dungeon_title(d)

	for i in total:
		var type_id: String = monsters[i]
		var lvl := base_level
		var mon := {"type": type_id, "level": lvl, "difficulty": d["difficulty"]}
		var label := _enemy_label(type_id)
		if hud != null:
			hud.set_stage("%s  %d/%d" % [title, i + 1, total])

		var root := _spawn_monster(type_id, lvl)
		await _walk_in(root, i)
		var battle := Game.build_battle(mon, d["difficulty"], _combat_hp)
		await _clash(root, battle, label)
		_combat_hp = float(battle["player_hp_left"])
		_set_player_hp(_combat_hp, float(battle["player_hp_max"]), true)
		if not battle["win"]:
			cleared = false
			Game.bump_metric("deaths")
			if hud != null:
				hud.add_log("你被 Lv.%d %s 击败，副本中止" % [lvl, label], UiKit.COL_RED)
			await _fade_out(root, 0.25)
			break

		var level_before := Game.level
		var gains := Game.grant_kill(mon, d["difficulty"])
		if Game.level > level_before:
			_combat_hp_max = float(Game.compute_stats().get("hp_max", 1.0))
			_combat_hp = _combat_hp_max
			_set_player_hp(_combat_hp, _combat_hp_max, true)
			if hud != null:
				hud.add_log("升级！生命回满", UiKit.COL_GREEN)
		if hud != null:
			hud.add_log("击败 Lv.%d %s  ·  +%d 金币  +%d 经验" % [lvl, label, gains["gold"], gains["exp"]],
				UiKit.COL_GREEN)
		_floating_text(root.position + Vector2(0, -70),
			"+%d EXP   +%d 金币" % [gains["exp"], gains["gold"]], Color("#ffd76a"), 12)
		await _fade_out(root, 0.30)
		await _wait(0.20)

	if cleared:
		_combat_hp_max = float(Game.compute_stats().get("hp_max", 1.0))
		_combat_hp = _combat_hp_max
		_set_player_hp(_combat_hp, _combat_hp_max, true)
		if not is_boss:
			Game.add_exploration(float(Data.EXPLORE_CLEAR_GAIN.get(String(d["difficulty"]), 1.0)))
		var loot := Game.grant_dungeon_loot(base_level)
		var loot_names: Array = []
		for it in loot:
			loot_names.append(it.item_name)
		Game.bump_metric("dungeons")
		if hud != null:
			if is_boss:
				hud.add_log("区域首领已击败 · 探索度清零", UiKit.COL_GOLD)
			hud.add_log("状态已恢复", UiKit.COL_GREEN)
			if loot_names.is_empty():
				hud.add_log("副本完成 · 未掉落装备", UiKit.COL_GREEN)
			else:
				hud.add_log("副本完成 · 获得装备：%s" % "、".join(loot_names), UiKit.COL_GREEN)
		await _wait(0.5)
	return cleared


func _enemy_label(type_id: String) -> String:
	match type_id:
		"elite":
			return "精英"
		"boss":
			return "区域首领"
		_:
			return "小怪"


func _spawn_monster(type_id: String, lvl: int) -> Node2D:
	var root := Node2D.new()
	root.position = Vector2(MONSTER_SPAWN_X, GROUND_Y)
	add_child(root)

	var tex: Texture2D
	var frame_size := 16
	var frames := 4
	var scl := 2.8
	var col := 2
	var tint := Color.WHITE
	var display := _enemy_label(type_id)
	var name_col := Color(0.86, 0.89, 0.94)
	var shadow_scale := Vector2(1.0, 0.85)
	var attack_speed := 8.0
	var foot_pad := 1.0

	match type_id:
		"elite":
			tex = load("res://assets/monsters/cyclope.png")
			scl = 3.6
			tint = Color(1.05, 0.94, 0.86)
			name_col = Color(0.94, 0.78, 0.38)
			shadow_scale = Vector2(1.25, 1.0)
			attack_speed = 7.0
			foot_pad = 0.0
		"boss":
			tex = load("res://assets/monsters/boss_walk.png")
			frame_size = 50
			frames = 6
			scl = 2.4
			col = -1
			name_col = Color(1.0, 0.42, 0.36)
			shadow_scale = Vector2(2.0, 1.35)
			attack_speed = 6.0
			foot_pad = 7.0
		_:
			tex = load("res://assets/monsters/slime.png")
			tint = Color(0.92, 0.98, 1.0)
			foot_pad = 1.0

	var sf := SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
	sf.add_animation("walk")
	sf.set_animation_speed("walk", attack_speed)
	sf.set_animation_loop("walk", true)
	for i in frames:
		var at := AtlasTexture.new()
		at.atlas = tex
		if col >= 0:
			at.region = Rect2(col * 16, i * 16, 16, 16)
		else:
			at.region = Rect2(i * frame_size, 0, frame_size, frame_size)
		sf.add_frame("walk", at)

	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = sf
	spr.scale = Vector2(scl, scl)
	var h := float(frame_size) * scl
	var sprite_w := float(frame_size) * scl
	spr.position = Vector2(0, -h * 0.5 + foot_pad * scl)
	spr.modulate = tint
	spr.play("walk")
	root.add_child(spr)

	var sh := Sprite2D.new()
	sh.texture = load("res://assets/icons/shadow.png")
	sh.position = Vector2(0, -1)
	sh.scale = shadow_scale
	sh.modulate = Color(0, 0, 0, 0.5)
	sh.visible = true
	root.add_child(sh)

	var bar := UiKit.progress(1.0, 1.0, 6, Color("#d9534f"))
	var bar_width := clampf(sprite_w + 6.0, 44.0, 72.0)
	bar.position = Vector2(-bar_width * 0.5, -h - 13)
	bar.size = Vector2(bar_width, 6)
	bar.fill_mode = ProgressBar.FILL_END_TO_BEGIN
	bar.show_percentage = false
	root.add_child(bar)

	var name_label := UiKit.label("Lv.%d %s" % [lvl, display], 12, name_col)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	name_label.add_theme_constant_override("outline_size", 4)
	name_label.position = Vector2(-100, -h - 60)
	name_label.size = Vector2(200, 18)
	name_label.visible = type_id != "normal"
	root.add_child(name_label)

	root.set_meta("sprite", spr)
	root.set_meta("hp", bar)
	root.set_meta("height", h)
	root.set_meta("name_label", name_label)
	root.set_meta("tint", tint)
	return root


func _walk_in(root: Node2D, index: int) -> void:
	var target_x := MEET_X + float(index % 2) * 8.0 + _rng.randf_range(-4, 4)
	var dist := absf(root.position.x - target_x)
	var dur := clampf(dist / 320.0, 0.55, 1.5)
	var t := create_tween()
	t.tween_property(root, "position:x", target_x, dur / maxf(0.25, Game.speed_mult))
	await t.finished
	await _wait(0.12)


func _clash(root: Node2D, battle: Dictionary, label: String) -> void:
	var spr: AnimatedSprite2D = root.get_meta("sprite")
	var bar: ProgressBar = root.get_meta("hp")
	var h := float(root.get_meta("height"))
	var total_hp := float(battle["monster_hp_total"])
	var hp_max := float(battle["player_hp_max"])
	bar.max_value = total_hp
	bar.value = total_hp
	if _player_bar != null:
		_player_bar.max_value = hp_max
		_player_bar.value = float(battle["player_hp_start"])
		_player_bar.visible = true
	if _shield_bar != null:
		_shield_bar.max_value = hp_max
		_shield_bar.value = 0.0
		_shield_bar.visible = false
	var win: bool = battle["win"]

	for turn in battle["turns"]:
		if not is_instance_valid(root):
			return
		if _player_bar != null:
			_player_bar.value = float(turn["player_hp"])
		if _shield_bar != null and turn.has("shield"):
			var shield_val := float(turn["shield"])
			_shield_bar.max_value = hp_max
			_shield_bar.value = shield_val
			_shield_bar.visible = shield_val > 0.0
		var note := String(turn.get("note", ""))
		if String(turn["side"]) == "player":
			bar.value = float(turn["monster_hp"])
			var dmg := int(turn["dmg"])
			_floating_text(root.position + Vector2(_rng.randf_range(-20, 20), -h * 0.72),
				str(dmg), Color(1.0, 0.86, 0.52), 13)
			_spawn_slash(root.position + Vector2(_rng.randf_range(-20, 10), -h * 0.4))
			spr.modulate = Color(1.8, 1.8, 1.8)
			if hud != null:
				hud.add_log("你 造成 %d 伤害%s" % [dmg, (" · " + note) if note != "" else ""], Color("#ffd76a"))
				if note != "":
					_floating_text(Vector2(CHAR_X, GROUND_Y - 82), note, Color("#8fd3c7"), 11)
			await _wait(0.16)
			if is_instance_valid(spr):
				spr.modulate = root.get_meta("tint")
		else:
			var mdmg := int(turn["dmg"])
			var absorbed := int(turn.get("absorbed", 0))
			_floating_text(Vector2(CHAR_X + 16, GROUND_Y - 58), "-%d" % (mdmg - absorbed), Color(1.0, 0.38, 0.34), 13)
			if absorbed > 0 and hud != null:
				_floating_text(Vector2(CHAR_X - 20, GROUND_Y - 72), "盾 -%d" % absorbed, Color("#6fa8dc"), 11)
			if hud != null:
				var absorb_text := (" · 护盾吸收 %d" % absorbed) if absorbed > 0 else ""
				hud.add_log("%s 造成 %d 伤害%s · 生命 %d/%d" % [
					label, mdmg, absorb_text, int(turn["player_hp"]), int(hp_max)], Color("#ff6b5e"))
			if _character != null:
				_character.modulate = Color(1.0, 0.55, 0.5)
			await _wait(0.14)
			if _character != null:
				_character.modulate = Color.WHITE
		await _wait(0.05)

	if _character != null:
		_character.modulate = Color.WHITE
	if _player_bar != null:
		_player_bar.value = float(battle["player_hp_left"])
	if _shield_bar != null:
		_shield_bar.value = float(battle.get("player_shield_left", 0))
		_shield_bar.visible = _shield_bar.value > 0.0
	if not win:
		_shake()
	await _wait(0.12)


func _set_player_hp(value: float, max_value: float, show: bool) -> void:
	if _player_bar == null:
		return
	_player_bar.max_value = maxf(1.0, max_value)
	_player_bar.value = clampf(value, 0.0, max_value)
	_player_bar.visible = show


func _update_player_bar() -> void:
	if _player_bar == null:
		return
	var hp := float(Game.compute_stats().get("hp_max", 1.0))
	_player_bar.max_value = hp
	_player_bar.value = hp
	_player_bar.visible = false


func _fade_out(root: Node2D, dur: float) -> void:
	if not is_instance_valid(root):
		return
	var t := create_tween().set_parallel(true)
	t.tween_property(root, "modulate:a", 0.0, dur / maxf(0.25, Game.speed_mult))
	t.tween_property(root, "position:y", root.position.y - 10.0, dur / maxf(0.25, Game.speed_mult))
	await t.finished
	if is_instance_valid(root):
		root.queue_free()


# ---------- 特效 ----------

func _floating_text(pos: Vector2, text: String, color: Color, size: int = 16) -> void:
	var l := UiKit.label(text, size, color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.92))
	l.add_theme_constant_override("outline_size", 4)
	l.position = pos - Vector2(60, 0)
	l.size = Vector2(120, 24)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.z_index = 50
	add_child(l)
	var t := create_tween().set_parallel(true)
	t.tween_property(l, "position:y", l.position.y - 32.0, 0.62)
	t.tween_property(l, "modulate:a", 0.0, 0.62)
	t.finished.connect(l.queue_free)


func _spawn_slash(pos: Vector2) -> void:
	var s := Sprite2D.new()
	s.texture = load("res://assets/icons/slash.png")
	s.position = pos
	s.scale = Vector2(1.4, 1.4)
	s.rotation = _rng.randf_range(-0.9, 0.9)
	s.modulate = Color(1.0, 0.95, 0.82, 0.95)
	s.z_index = 40
	add_child(s)
	var t := create_tween().set_parallel(true)
	t.tween_property(s, "scale", Vector2(2.0, 2.0), 0.18)
	t.tween_property(s, "modulate:a", 0.0, 0.18)
	t.finished.connect(s.queue_free)


func _shake() -> void:
	if _camera == null:
		return
	var t := create_tween()
	t.tween_property(_camera, "offset", Vector2(9, 5), 0.05)
	t.tween_property(_camera, "offset", Vector2(-7, -4), 0.06)
	t.tween_property(_camera, "offset", Vector2(4, 3), 0.05)
	t.tween_property(_camera, "offset", Vector2.ZERO, 0.06)


func _wait(sec: float) -> void:
	await get_tree().create_timer(maxf(0.01, sec / maxf(0.25, Game.speed_mult))).timeout
