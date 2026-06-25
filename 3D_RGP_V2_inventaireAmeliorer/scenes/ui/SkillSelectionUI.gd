## Build path and active skill selection overlay.
extends CanvasLayer

@onready var skill_list: ItemList = $Panel/Margin/VBox/SkillList
@onready var build_option: OptionButton = $Panel/Margin/VBox/BuildOption
@onready var stats_label: Label = $Panel/Margin/VBox/StatsLabel
@onready var passives_label: Label = $Panel/Margin/VBox/PassivesLabel
@onready var str_btn: Button = $Panel/Margin/VBox/StatButtons/StrBtn
@onready var mag_btn: Button = $Panel/Margin/VBox/StatButtons/MagBtn
@onready var def_btn: Button = $Panel/Margin/VBox/StatButtons/DefBtn

var _player: Node


func _ready() -> void:
	visible = false
	if build_option:
		build_option.clear()
		build_option.add_item("Strength", 0)
		build_option.add_item("Magic", 1)
		build_option.add_item("Defense", 2)
		build_option.add_item("Hybrid", 3)
		_select_build_option(ProgressionTracker.build_path)
		build_option.item_selected.connect(_on_build_selected)
	if skill_list:
		skill_list.item_selected.connect(_on_skill_selected)
	if str_btn:
		str_btn.pressed.connect(func(): _allocate("strength"))
	if mag_btn:
		mag_btn.pressed.connect(func(): _allocate("magic"))
	if def_btn:
		def_btn.pressed.connect(func(): _allocate("defense"))
	ProgressionTracker.level_up.connect(func(_l): _refresh())
	ProgressionTracker.skill_unlocked.connect(func(_s): _refresh())


func bind_player(player: Node) -> void:
	_player = player
	if is_node_ready():
		_refresh()
	else:
		call_deferred("_refresh")


func _allocate(stat_name: String) -> void:
	if ProgressionTracker.allocate_stat(stat_name) and _player and _player.has_method("refresh_stats"):
		_player.refresh_stats()
	_refresh()


func _refresh() -> void:
	if skill_list == null or stats_label == null:
		return
	skill_list.clear()
	var skills_to_show: Array[String] = []
	if Global.hub_test_mode:
		for skill_id in ProgressionTracker.SKILL_DEFS:
			skills_to_show.append(skill_id)
	else:
		for skill_id in ProgressionTracker.unlocked_skills:
			var def: Dictionary = ProgressionTracker.SKILL_DEFS.get(skill_id, {})
			if def.is_empty():
				continue
			if skill_id != "power_slash" and def.get("path", "") != ProgressionTracker.build_path:
				if skill_id != "life_drain" or ProgressionTracker.build_path != "hybrid":
					continue
			skills_to_show.append(skill_id)
	for skill_id in skills_to_show:
		var idx := skill_list.add_item(skill_id.replace("_", " ").capitalize())
		skill_list.set_item_metadata(idx, skill_id)
	var mode_hint := "\n[TEST MODE — all builds & skills]" if Global.hub_test_mode else ""
	stats_label.text = "Lv %d  XP %d/%d\nSTR %d  MAG %d  DEF %d\nPoints: %d%s" % [
		ProgressionTracker.level,
		ProgressionTracker.xp,
		ProgressionTracker.xp_to_next,
		ProgressionTracker.strength,
		ProgressionTracker.magic,
		ProgressionTracker.defense,
		ProgressionTracker.stat_points,
		mode_hint,
	]
	if passives_label:
		var passives: Array[String] = ProgressionTracker.get_passive_list()
		if passives.is_empty():
			passives_label.text = "Passives: none yet"
		else:
			passives_label.text = "Passives: " + ", ".join(passives)
	var can_alloc := ProgressionTracker.stat_points > 0
	if str_btn:
		str_btn.disabled = not can_alloc
	if mag_btn:
		mag_btn.disabled = not can_alloc
	if def_btn:
		def_btn.disabled = not can_alloc


func _on_build_selected(index: int) -> void:
	var paths := ["strength", "magic", "defense", "hybrid"]
	ProgressionTracker.set_build_path(paths[index])
	_refresh()


func _on_skill_selected(index: int) -> void:
	var skill_id: String = skill_list.get_item_metadata(index)
	if _player:
		var skill_sys = _player.get_node_or_null("SkillSystem")
		if skill_sys:
			skill_sys.set_active_skill(skill_id)
	_refresh()


func _select_build_option(path: String) -> void:
	if build_option == null:
		return
	var paths := ["strength", "magic", "defense", "hybrid"]
	var idx := paths.find(path)
	if idx >= 0:
		build_option.select(idx)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("skill_menu"):
		visible = not visible
		if visible:
			_refresh()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif _player == null:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			var inv = _player.get_node_or_null("InventoryUI")
			if inv == null or not inv.visible:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
