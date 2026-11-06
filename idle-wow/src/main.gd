extends Node2D

var world: World
var hud: HUD
var _shot := ""
var _dragging := false
var _drag_offset := Vector2i.ZERO
var _character_select: CharacterSelect
var _select_layer: CanvasLayer


func _ready() -> void:
	get_tree().auto_accept_quit = false
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true)
	DisplayServer.window_set_size(Vector2i(960, 540))
	var usable := DisplayServer.screen_get_usable_rect()
	DisplayServer.window_set_position(usable.position + (usable.size - Vector2i(960, 540)) / 2)
	get_viewport().transparent_bg = true
	get_window().theme = UiKit.theme()

	var args := OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("--shot="):
			_shot = a.substr(7)

	if "--test" in args:
		Game.debug_report()
		get_tree().quit()
		return

	world = World.new()
	add_child(world)
	hud = HUD.new()
	add_child(hud)
	hud.world = world
	world.hud = hud

	if _shot != "":
		_run_shot()
		return

	if "--auto" in args:
		_run_auto("--boss" in args)
		return

	if "--autofarm" in args:
		_run_autofarm()
		return

	if "--flow" in args:
		_run_flow()
		return

	if "--shoptest" in args:
		_run_shoptest()
		return

	if "--areatest" in args:
		_run_areatest()
		return

	if "--windowtest" in args:
		_run_windowtest()
		return

	if "--battletest" in args:
		_run_battletest()
		return

	if "--uitest" in args:
		_run_uitest()
		return

	if "--balancetest" in args:
		_run_balancetest()
		return

	if "--charactertest" in args:
		_run_charactertest()
		return

	if "--bagtest" in args:
		_run_bagtest()
		return

	if Game.loaded:
		world.set_class(Game.class_id)
	else:
		_show_character_select()


func _show_character_select() -> void:
	_select_layer = CanvasLayer.new()
	_select_layer.layer = 20
	add_child(_select_layer)
	_character_select = CharacterSelect.new()
	_select_layer.add_child(_character_select)
	_character_select.character_chosen.connect(_on_character_chosen)


func _on_character_chosen(cid: String) -> void:
	Game.new_game(cid)
	world.set_class(cid)
	if _character_select != null:
		_character_select.queue_free()
		_character_select = null
	if _select_layer != null:
		_select_layer.queue_free()
		_select_layer = null


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_drag_offset = DisplayServer.mouse_get_position() - DisplayServer.window_get_position()
			get_viewport().set_input_as_handled()
		elif _dragging:
			_dragging = false
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion and _dragging:
		DisplayServer.window_set_position(DisplayServer.mouse_get_position() - _drag_offset)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_B:
				hud.toggle_window("bag")
			KEY_M:
				hud.toggle_window("dungeon")
			KEY_S:
				hud.toggle_window("shop")
			KEY_I:
				hud.toggle_window("info")
			KEY_F:
				hud.refresh_dungeon()
			KEY_ESCAPE:
				hud.close_current()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Game.save_game()
		get_tree().quit()


func _run_shoptest() -> void:
	Game.debug_seed()
	print("SHOP start free=%d gold=%d stock=%d" % [Game.shop_free_left, Game.gold, Game.shop_stock.size()])
	for i in 6:
		var ok := Game.refresh_shop()
		print("SHOP refresh=%d ok=%s free=%d gold=%d" % [i + 1, str(ok), Game.shop_free_left, Game.gold])
	Game.auto_sell = true
	var before := Game.inventory_count()
	var it := GameItem.create(Game.rng, 10, 2, Game.class_id, "ring", "test")
	Game.receive_drop(it)
	print("SHOP autosell inv %d -> %d gold=%d" % [before, Game.inventory_count(), Game.gold])
	Game.set_auto_mode("repeat")
	print("SHOP mode=%s" % Game.auto_mode)
	get_tree().quit()


func _run_areatest() -> void:
	Game.debug_seed()
	print("AREA start idx=%d name=%s explore=%.0f" % [Game.area_index, String(Game.current_area()["name"]), Game.exploration])
	print("AREA switch1=%s idx=%d name=%s level=%d" % [
		str(Game.set_area(1)), Game.area_index, String(Game.current_area()["name"]), int(Game.dungeons[0]["level"])])
	Game.exploration = 50.0
	Game.save_game()
	Game.load_game()
	print("AREA saved idx=%d ex0=%.0f ex1=%.0f" % [
		Game.area_index, Game.area_exploration[0], Game.area_exploration[1]])
	print("AREA switch2=%s (locked)" % str(Game.set_area(2)))
	get_tree().quit()


func _run_charactertest() -> void:
	for cid in Data.CHARACTER_ORDER:
		Game.new_game(cid)
		var st := Game.compute_stats()
		var ch := Data.character_def(cid)
		print("CHAR %s name=%s talent=%s hp=%d armor=%.0f crit=%.2f haste=%.2f sp=%.0f ls=%.2f pen=%.2f" % [
			cid, ch["name"], ch["title"], int(st["hp_max"]), float(st["armor_total"]),
			float(st["crit_pct"]), float(st["haste_pct"]), float(st["sp"]),
			float(st["lifesteal_pct"]), float(st["pen_pct"])])
	get_tree().quit()


func _run_balancetest() -> void:
	var normal_explore := float(Data.MONSTER_TYPES["normal"]["explore"])
	var elite_explore := float(Data.MONSTER_TYPES["elite"]["explore"])
	var per_run := normal_explore * 3.0 + elite_explore
	print("BALANCE elite_hp=%.2f hero_hp=%.2f boss_hp=%.2f explore_run=%.2f runs=%.1f" % [
		float(Data.DIFFICULTIES["elite"]["hp"]), float(Data.DIFFICULTIES["hero"]["hp"]),
		float(Data.MONSTER_TYPES["boss"]["hp"]), per_run, 100.0 / per_run])
	get_tree().quit()


func _run_uitest() -> void:
	Game.debug_seed()
	hud.toggle_window("bag")
	await get_tree().create_timer(0.2).timeout
	var dolls := hud._bag.find_children("*", "PaperDoll", true, false)
	var x0: float = dolls[0].global_position.x if not dolls.is_empty() else -1.0
	hud._bag._toggle_stats()
	await get_tree().create_timer(0.2).timeout
	dolls = hud._bag.find_children("*", "PaperDoll", true, false)
	var x1: float = dolls[0].global_position.x if not dolls.is_empty() else -1.0
	print("UI bag_left_stable=%s x0=%.1f x1=%.1f" % [str(absf(x0 - x1) < 0.5), x0, x1])

	Game.push_log("UI TEST", Color.WHITE)
	hud.toggle_window("info")
	await get_tree().create_timer(0.2).timeout
	var before := Game.log_history.size()
	hud._info._clear_logs()
	await get_tree().create_timer(0.1).timeout
	print("UI info_clear=%s before=%d after=%d" % [str(Game.log_history.is_empty()), before, Game.log_history.size()])

	hud.toggle_window("shop")
	await get_tree().create_timer(0.2).timeout
	var refresh = hud._shop._footer_left.get_child(0)
	print("UI shop_refresh='%s' gold=%d" % [refresh.text, Game.gold])
	get_tree().quit()


func _run_battletest() -> void:
	Game.debug_seed()
	world.set_class(Game.class_id)
	print("BATTLE idle_bar=%s char_x=%.0f meet_x=%.0f grass_w=%.0f spawn_x=%.0f" % [
		str(world._player_bar.visible), World.CHAR_X, World.MEET_X,
		World.HORIZON_RECT.size.x, World.MONSTER_SPAWN_X])
	print("BATTLE player_bar_right=%.1f char_right=%.1f" % [
		world._player_bar.position.x + world._player_bar.size.x,
		World.CHAR_X + World.CHAR_SIZE * 0.5])
	world.start_dungeon(Game.dungeons[0])
	var saw_bar := false
	for i in 24:
		await get_tree().create_timer(0.2).timeout
		if world._player_bar.visible:
			saw_bar = true
	print("BATTLE saw_player_bar=%s" % str(saw_bar))
	var guard := 0
	while Game.busy and guard < 100:
		await get_tree().create_timer(0.2).timeout
		guard += 1
	print("BATTLE bar_after_dungeon=%s" % str(world._player_bar.visible))
	get_tree().quit()


func _run_windowtest() -> void:
	Game.new_game("warrior")
	hud.toggle_window("bag")
	hud.toggle_window("info")
	await get_tree().create_timer(0.2).timeout
	print("WINDOW bag=%s info=%s" % [str(hud._bag.visible), str(hud._info.visible)])
	hud.toggle_window("dungeon")
	await get_tree().create_timer(0.2).timeout
	print("WINDOW bag=%s map=%s info=%s" % [str(hud._bag.visible), str(hud._dungeon.visible), str(hud._info.visible)])
	hud.toggle_window("more")
	await get_tree().create_timer(0.2).timeout
	print("WINDOW map=%s more=%s info=%s" % [str(hud._dungeon.visible), str(hud._more.visible), str(hud._info.visible)])
	hud.toggle_window("info")
	await get_tree().create_timer(0.2).timeout
	print("WINDOW more=%s info=%s" % [str(hud._more.visible), str(hud._info.visible)])
	get_tree().quit()


func _run_bagtest() -> void:
	Game.debug_seed()
	var item: GameItem = Game.inventory[0]
	Game.toggle_lock(item)
	var before := Game.inventory_count()
	Game.sell_item(item)
	print("BAG locked=%s sell_blocked=%s" % [str(item.locked), str(Game.inventory_count() == before)])
	Game.dismantle_item(item)
	print("BAG dismantle_blocked=%s" % str(Game.inventory_count() == before))
	Game.toggle_lock(item)
	Game.dismantle_item(item)
	print("BAG dismantled=%s materials=%d" % [str(Game.inventory_count() == before - 1), Game.materials])
	var trinket := GameItem.create(Game.rng, 10, 2, Game.class_id, "trinket", "test")
	Game.receive_drop(trinket)
	print("BAG trinket_equipped=%s" % str(Game.equipment.get("trinket") != null))
	Game.save_game()
	Game.load_game()
	print("BAG load materials=%d trinket=%s" % [Game.materials, str(Game.equipment.get("trinket") != null)])
	get_tree().quit()


func _run_flow() -> void:
	if Game.class_id == "":
		Game.new_game("warrior")
	world.set_class(Game.class_id)
	Game.auto_mode = "off"
	await get_tree().create_timer(0.4).timeout
	print("FLOW class=%s level=%d gold=%d inv=%d equip_main=%s" % [
		Game.class_id, Game.level, Game.gold, Game.inventory_count(),
		"yes" if Game.equipment.get("main") != null else "no"])
	Game.save_game()
	await get_tree().create_timer(0.2).timeout
	var ok := Game.load_game()
	print("FLOW save_load=%s level=%d gold=%d" % [str(ok), Game.level, Game.gold])
	get_tree().quit()


func _run_autofarm() -> void:
	Game.debug_seed()
	Game.auto_mode = "next"
	world.set_class(Game.class_id)
	await get_tree().create_timer(0.2).timeout
	world.resume_auto(0.1)
	await get_tree().create_timer(30.0).timeout
	print("AUTOFARM busy=%s lv=%d gold=%d inv=%d explore=%.1f mode=%s" % [
		str(Game.busy), Game.level, Game.gold, Game.inventory_count(), Game.exploration, Game.auto_mode])
	get_tree().quit()


func _run_auto(boss: bool) -> void:
	Game.debug_seed()
	world.set_class(Game.class_id)
	await get_tree().create_timer(0.2).timeout
	var d: Dictionary = Game.make_boss_dungeon() if boss else Game.dungeons[0]
	print("AUTO_START ", Data.dungeon_title(d), " ", d["difficulty"])
	world.start_dungeon(d)
	await get_tree().create_timer(18.0).timeout
	print("AUTO_RESULT busy=%s lv=%d gold=%d inv=%d explore=%.1f clears=%d" % [
		str(Game.busy), Game.level, Game.gold, Game.inventory_count(), Game.exploration, Game.area_clears])
	get_tree().quit()


# ---------- 截图 / 调试 ----------

func _run_shot() -> void:
	if _shot == "class" or _shot == "firstrun":
		Game.class_id = ""
		Game.loaded = false
		Game.new_game("warrior")
		world.set_class("warrior")
		await get_tree().create_timer(0.4).timeout
	elif _shot == "select":
		Game.class_id = ""
		Game.loaded = false
		_show_character_select()
		await get_tree().create_timer(0.4).timeout
	else:
		Game.debug_seed()
		Game.auto_mode = "next"
		world.set_class(Game.class_id)
		await get_tree().create_timer(0.25).timeout
		match _shot:
			"bag":
				hud.toggle_window("bag")
			"bagcollapsed":
				hud.toggle_window("bag")
				await get_tree().create_timer(0.25).timeout
				hud._bag._toggle_stats()
			"tooltip":
				hud.toggle_window("bag")
				await get_tree().create_timer(0.25).timeout
				for it in Game.inventory:
					if it != null:
						hud._bag._tip.show_item(it, Game.compare_item(it), Game.class_id, "左键装备 · 右键出售")
						hud._bag._tip.position = Vector2(470, 190)
						break
			"map":
				hud.toggle_window("dungeon")
			"shop":
				hud.toggle_window("shop")
			"more":
				hud.toggle_window("more")
			"stats":
				hud.toggle_window("stats")
			"info":
				if not Game.dungeons.is_empty():
					world.start_dungeon(Game.dungeons[0])
				await get_tree().create_timer(1.8).timeout
				hud.toggle_window("info")
			"bossmap":
				Game.exploration = 100.0
				Game.exploration_changed.emit()
				hud.toggle_window("dungeon")
			"encounter":
				if not Game.dungeons.is_empty():
					world.start_dungeon(Game.dungeons[0])
			"bossencounter":
				Game.exploration = 100.0
				world.start_dungeon(Game.make_boss_dungeon())
	await get_tree().create_timer(3.4 if _shot == "firstrun" else 1.15).timeout
	await RenderingServer.frame_post_draw
	var dir := "res://shots"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var img := get_viewport().get_texture().get_image()
	if img != null:
		var path := "%s/%s.png" % [dir, _shot]
		img.save_png(path)
		print("SHOT_OK ", ProjectSettings.globalize_path(path))
	else:
		print("SHOT_FAIL no image")
	get_tree().quit()
