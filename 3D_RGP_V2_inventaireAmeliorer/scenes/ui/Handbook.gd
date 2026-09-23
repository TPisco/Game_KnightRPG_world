## Adventurer Handbook: a book-style menu (K) holding everything that used to
## clutter the screen — quests, stat points, skills, bestiary, boss records,
## and item discoveries — laid out as chapters on parchment pages.
class_name Handbook
extends CanvasLayer

const CHAPTERS := ["Quests", "Stat Points", "Skills", "Bestiary", "Bosses", "Discoveries"]
const INK := Color(0.24, 0.16, 0.09)
const INK_FADED := Color(0.42, 0.33, 0.24)

var _player: Node = null
var _root: Control = null
var _book: PanelContainer = null
var _summary_label: Label = null
var _page_title: Label = null
var _content: VBoxContainer = null
var _current_chapter: String = "Quests"
var _chapter_buttons: Dictionary = {}


func setup(player: Node) -> void:
	_player = player


func _ready() -> void:
	layer = 8
	_build_ui()
	visible = false


func _input(event: InputEvent) -> void:
	if Global.build_mode_active:
		return  # the home editor owns the controls
	if event.is_action_pressed("skill_menu"):
		toggle()


func toggle() -> void:
	if visible:
		visible = false
		# Give the mouse back to gameplay unless the inventory holds it.
		var inv = _player.get_node_or_null("InventoryUI") if _player else null
		if inv == null or not inv.visible:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		SoundManager.play("page")
		_refresh_summary()
		_open_chapter(_current_chapter)
		# "Opening the book" — a quick swell from the spine.
		_book.pivot_offset = _book.size * 0.5
		_book.scale = Vector2(0.85, 0.92)
		_book.modulate.a = 0.0
		var tween := create_tween().set_parallel(true)
		tween.tween_property(_book, "scale", Vector2.ONE, 0.18).set_ease(Tween.EASE_OUT)
		tween.tween_property(_book, "modulate:a", 1.0, 0.15)


# --- UI construction ---------------------------------------------------------

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)

	# Leather cover.
	_book = PanelContainer.new()
	var leather := StyleBoxFlat.new()
	leather.bg_color = Color(0.26, 0.17, 0.10)
	leather.border_color = Color(0.48, 0.34, 0.18)
	for side in ["border_width_left", "border_width_top", "border_width_right", "border_width_bottom"]:
		leather.set(side, 4)
	for corner in ["corner_radius_top_left", "corner_radius_top_right", "corner_radius_bottom_left", "corner_radius_bottom_right"]:
		leather.set(corner, 14)
	leather.shadow_color = Color(0, 0, 0, 0.5)
	leather.shadow_size = 12
	_book.add_theme_stylebox_override("panel", leather)
	_root.add_child(_book)
	_book.set_anchors_preset(Control.PRESET_CENTER)
	_book.offset_left = -480
	_book.offset_right = 480
	_book.offset_top = -300
	_book.offset_bottom = 300

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 14)
	_book.add_child(margin)

	var pages := HBoxContainer.new()
	pages.add_theme_constant_override("separation", 10)
	margin.add_child(pages)

	# --- Left page: title, adventurer summary, chapter bookmarks ---
	var left := PanelContainer.new()
	left.add_theme_stylebox_override("panel", _parchment_style())
	left.custom_minimum_size = Vector2(300, 0)
	pages.add_child(left)
	var left_margin := _page_margin()
	left.add_child(left_margin)
	var left_box := VBoxContainer.new()
	left_box.add_theme_constant_override("separation", 8)
	left_margin.add_child(left_box)

	var title := Label.new()
	title.text = "Adventurer\nHandbook"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left_box.add_child(title)
	left_box.add_child(_ink_rule())

	_summary_label = Label.new()
	_summary_label.add_theme_font_size_override("font_size", 14)
	_summary_label.add_theme_color_override("font_color", INK_FADED)
	left_box.add_child(_summary_label)
	left_box.add_child(_ink_rule())

	for chapter in CHAPTERS:
		var btn := Button.new()
		btn.text = chapter
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_open_chapter.bind(chapter))
		left_box.add_child(btn)
		_chapter_buttons[chapter] = btn

	left_box.add_child(_ink_rule())
	var respawn_btn := Button.new()
	respawn_btn.text = "Respawn at Map Center"
	respawn_btn.tooltip_text = "Teleport to the center of the area you are in.\nSame map — keeps ALL items and progress."
	respawn_btn.pressed.connect(_on_respawn_pressed)
	left_box.add_child(respawn_btn)

	var close_hint := Label.new()
	close_hint.text = "\n[K] close the book"
	close_hint.add_theme_font_size_override("font_size", 12)
	close_hint.add_theme_color_override("font_color", INK_FADED)
	left_box.add_child(close_hint)

	# --- Spine ---
	var spine := ColorRect.new()
	spine.color = Color(0.16, 0.10, 0.06)
	spine.custom_minimum_size = Vector2(6, 0)
	pages.add_child(spine)

	# --- Right page: chapter content ---
	var right := PanelContainer.new()
	right.add_theme_stylebox_override("panel", _parchment_style())
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pages.add_child(right)
	var right_margin := _page_margin()
	right.add_child(right_margin)
	var right_box := VBoxContainer.new()
	right_box.add_theme_constant_override("separation", 6)
	right_margin.add_child(right_box)

	_page_title = Label.new()
	_page_title.add_theme_font_size_override("font_size", 24)
	_page_title.add_theme_color_override("font_color", INK)
	right_box.add_child(_page_title)
	right_box.add_child(_ink_rule())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_box.add_child(scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 6)
	scroll.add_child(_content)


func _parchment_style() -> StyleBoxFlat:
	var parchment := StyleBoxFlat.new()
	parchment.bg_color = Color(0.88, 0.81, 0.66)
	parchment.border_color = Color(0.62, 0.52, 0.36)
	for side in ["border_width_left", "border_width_top", "border_width_right", "border_width_bottom"]:
		parchment.set(side, 2)
	for corner in ["corner_radius_top_left", "corner_radius_top_right", "corner_radius_bottom_left", "corner_radius_bottom_right"]:
		parchment.set(corner, 6)
	return parchment


func _page_margin() -> MarginContainer:
	var m := MarginContainer.new()
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		m.add_theme_constant_override(side, 14)
	return m


func _ink_rule() -> ColorRect:
	var rule := ColorRect.new()
	rule.color = Color(0.55, 0.44, 0.30, 0.7)
	rule.custom_minimum_size = Vector2(0, 2)
	return rule


func _add_line(text: String, size: int = 15, color: Color = INK) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.add_child(label)
	return label


## Safe respawn: a plain teleport to the center of the map area the player is
## ALREADY in (their current chunk) — same world, same surroundings, no
## reload, no reset, so inventory, equipment, and progress are untouched.
func _on_respawn_pressed() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var pos := Vector3(0.0, 1.5, 4.0)  # hub world default spawn area
	var scene_root := get_tree().current_scene
	var world_gen := scene_root.get_node_or_null("WorldGenerator") if scene_root else null
	if world_gen and "world_seed" in world_gen:
		var p: Vector3 = _player.global_position
		var cx := floorf(p.x / 32.0) * 32.0 + 16.0
		var cz := floorf(p.z / 32.0) * 32.0 + 16.0
		var h: float = WorldChunk.get_terrain_height(world_gen.world_seed, cx, cz)
		pos = Vector3(cx, h + 2.0, cz)
	_player.global_position = pos
	if "velocity" in _player:
		_player.velocity = Vector3.ZERO
	SoundManager.play("portal")
	if visible:
		toggle()  # close the book and hand the mouse back to gameplay


# --- Chapters ----------------------------------------------------------------

func _open_chapter(chapter: String) -> void:
	_current_chapter = chapter
	_page_title.text = chapter
	for chapter_name in _chapter_buttons:
		_chapter_buttons[chapter_name].disabled = chapter_name == chapter
	for child in _content.get_children():
		child.visible = false  # hide instantly; freed at frame end
		child.queue_free()
	SoundManager.play("page")
	match chapter:
		"Quests":
			_build_quests_page()
		"Stat Points":
			_build_stats_page()
		"Skills":
			_build_skills_page()
		"Bestiary":
			_build_bestiary_page()
		"Bosses":
			_build_bosses_page()
		"Discoveries":
			_build_discoveries_page()


func _refresh_summary() -> void:
	if _summary_label == null:
		return
	var gold := 0
	if _player and is_instance_valid(_player) and "gold" in _player:
		gold = int(_player.gold)
	var realm: Dictionary = BossRegistry.get_realm_for_depth(ProgressionTracker.run_depth)
	var points_note := "  (!)" if ProgressionTracker.stat_points > 0 else ""
	_summary_label.text = "Level %d  —  XP %d / %d\nGold: %d\nRealm %d: %s\nStat points: %d%s" % [
		ProgressionTracker.level, ProgressionTracker.xp, ProgressionTracker.xp_to_next,
		gold, ProgressionTracker.cave_portals_cleared + 1, realm.get("name", "?"),
		ProgressionTracker.stat_points, points_note,
	]


func _quest_line(done: bool, text: String) -> void:
	_add_line(("[X]  " if done else "[  ]  ") + text, 15, INK if not done else INK_FADED)


func _build_quests_page() -> void:
	_add_line("The Journey Home", 18)
	_quest_line(false, "Survive the fractured worlds and find the path back home.")
	_content.add_child(_ink_rule())

	_add_line("This Realm", 18)
	var seals := ProgressionTracker.minibosses_cleared
	var boss_name := BossRegistry.get_boss_name_for_realm(ProgressionTracker.cave_portals_cleared)
	_quest_line(seals >= 2, "Break the dungeon seals in the caves  (%d / 2)" % mini(seals, 2))
	if seals >= 2:
		_quest_line(false, "The Boss Gate is open — slay %s!" % boss_name)
	else:
		_add_line("      Find caves and clear their Mini-Boss Dungeons.", 13, INK_FADED)
		_quest_line(false, "Slay the realm's master: %s (locked)" % boss_name)
	_quest_line(false, "Step through the victory portal to the next realm.")
	_content.add_child(_ink_rule())

	_add_line("Side Notes", 18)
	_quest_line(ShopInterior._met_collector, "Meet The Collector in a shop between worlds.")
	var next_level_goal := 5 if ProgressionTracker.level < 5 else (10 if ProgressionTracker.level < 10 else 20)
	_quest_line(ProgressionTracker.level >= next_level_goal, "Reach level %d." % next_level_goal)
	_add_line("\nRealms crossed: %d    Bosses felled: %d" % [
		ProgressionTracker.cave_portals_cleared, ProgressionTracker.bosses_defeated], 14, INK_FADED)


func _build_stats_page() -> void:
	_add_line("Available points: %d" % ProgressionTracker.stat_points, 18)
	_content.add_child(_ink_rule())
	var stats := [
		["strength", "Strength", ProgressionTracker.strength, "melee damage, health, stamina"],
		["magic", "Magic", ProgressionTracker.magic, "spell power, mana, cooldowns"],
		["defense", "Defense", ProgressionTracker.defense, "damage taken, guard strength"],
	]
	for entry in stats:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		_content.add_child(row)
		var label := Label.new()
		label.text = "%s: %d  —  %s" % [entry[1], entry[2], entry[3]]
		label.add_theme_font_size_override("font_size", 15)
		label.add_theme_color_override("font_color", INK)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var btn := Button.new()
		btn.text = "+"
		btn.custom_minimum_size = Vector2(36, 0)
		btn.disabled = ProgressionTracker.stat_points <= 0
		btn.pressed.connect(_on_allocate.bind(entry[0]))
		row.add_child(btn)

	_content.add_child(_ink_rule())
	_add_line("Build Path", 18)
	var build_row := HBoxContainer.new()
	_content.add_child(build_row)
	var build_option := OptionButton.new()
	var paths := ["strength", "magic", "defense", "hybrid"]
	for i in paths.size():
		build_option.add_item(paths[i].capitalize(), i)
	var idx := paths.find(ProgressionTracker.build_path)
	if idx >= 0:
		build_option.select(idx)
	build_option.item_selected.connect(func(i): ProgressionTracker.set_build_path(paths[i]))
	build_row.add_child(build_option)

	_content.add_child(_ink_rule())
	var passives: Array[String] = ProgressionTracker.get_passive_list()
	_add_line("Passives: " + (", ".join(passives) if not passives.is_empty() else "none yet"), 14, INK_FADED)


func _on_allocate(stat_name: String) -> void:
	if ProgressionTracker.allocate_stat(stat_name) and _player and _player.has_method("refresh_stats"):
		_player.refresh_stats()
	_refresh_summary()
	_open_chapter("Stat Points")


func _build_skills_page() -> void:
	var skill_system = _player.get_node_or_null("SkillSystem") if _player else null
	var active_id: String = skill_system.active_skill if skill_system else ""
	for i in SkillSystem.SKILL_DATABASE.size():
		var entry: Dictionary = SkillSystem.SKILL_DATABASE[i]
		var skill_id: String = entry["id"]
		var unlocked: bool = Global.hub_test_mode or ProgressionTracker.is_skill_unlocked(skill_id)
		var key := _action_key_text("skill_%d" % (i + 1))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		_content.add_child(row)
		var label := Label.new()
		var status: String = "ACTIVE" if skill_id == active_id else (str(entry["type"]).capitalize() if unlocked else "locked")
		label.text = "[%s]  %s  —  %s" % [key, entry["name"], status]
		label.add_theme_font_size_override("font_size", 15)
		label.add_theme_color_override("font_color", INK if unlocked else INK_FADED)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		if unlocked and skill_id != active_id and skill_system:
			var btn := Button.new()
			btn.text = "Set Active"
			btn.pressed.connect(func():
				skill_system.set_active_skill(skill_id)
				_open_chapter("Skills"))
			row.add_child(btn)
	_content.add_child(_ink_rule())
	_add_line("The active skill fires on [Q] / Right Click. Every unlocked power\nalso has its own direct key, shown on the combat side panel.", 13, INK_FADED)


func _action_key_text(action: String) -> String:
	if not InputMap.has_action(action):
		return "?"
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key := event as InputEventKey
			var code := key.physical_keycode if key.physical_keycode != 0 else key.keycode
			return OS.get_keycode_string(code)
	return "?"


func _build_bestiary_page() -> void:
	_add_line("Creatures slain: %d" % ProgressionTracker.get_total_mob_kills(), 18)
	_content.add_child(_ink_rule())
	if ProgressionTracker.mob_kills.is_empty():
		_add_line("No kills recorded yet. The fractured wilds await.", 14, INK_FADED)
		return
	var names := ProgressionTracker.mob_kills.keys()
	names.sort()
	for mob_name in names:
		_add_line("%s  —  %d slain" % [mob_name, int(ProgressionTracker.mob_kills[mob_name])])


func _build_bosses_page() -> void:
	_add_line("Great victories: %d" % ProgressionTracker.bosses_defeated, 18)
	_content.add_child(_ink_rule())
	if ProgressionTracker.boss_kills.is_empty():
		_add_line("No bosses defeated yet. Break the dungeon seals to face one.", 14, INK_FADED)
		return
	var names := ProgressionTracker.boss_kills.keys()
	names.sort()
	for boss_name in names:
		var count := int(ProgressionTracker.boss_kills[boss_name])
		_add_line("%s  —  defeated%s" % [boss_name, " x%d" % count if count > 1 else ""])


func _build_discoveries_page() -> void:
	_add_line("Items discovered: %d" % ProgressionTracker.discovered_items.size(), 18)
	_content.add_child(_ink_rule())
	if ProgressionTracker.discovered_items.is_empty():
		_add_line("Nothing catalogued yet. Loot the world!", 14, INK_FADED)
		return
	var names := ProgressionTracker.discovered_items.duplicate()
	names.sort()
	for item_name in names:
		_add_line("• " + str(item_name))
