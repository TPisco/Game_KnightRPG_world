## Side panel listing every power with its live hotkey and cooldown state.
## Keys are read from the InputMap so remapped controls display correctly.
class_name PowerPanel
extends CanvasLayer

const REFRESH_INTERVAL := 0.15

var _player: Node = null
var _skill_system: Node = null
var _rows: Array[Label] = []
var _timer: float = 0.0


func setup(player: Node) -> void:
	_player = player
	_skill_system = player.get_node_or_null("SkillSystem")


func _ready() -> void:
	layer = 5
	var panel := PanelContainer.new()
	add_child(panel)
	panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	panel.offset_left = -235.0
	panel.offset_right = -10.0
	panel.offset_top = -20.0
	panel.self_modulate = Color(1, 1, 1, 0.85)

	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	vbox.add_theme_constant_override("separation", 4)

	var title := Label.new()
	title.text = "Powers"
	title.add_theme_font_size_override("font_size", 15)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	for i in SkillSystem.SKILL_DATABASE.size():
		var row := Label.new()
		row.add_theme_font_size_override("font_size", 13)
		vbox.add_child(row)
		_rows.append(row)
	_refresh()


func _action_key_text(action: String) -> String:
	if not InputMap.has_action(action):
		return "?"
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			var code := key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode
			return OS.get_keycode_string(code)
		if event is InputEventMouseButton:
			return "Mouse %d" % (event as InputEventMouseButton).button_index
	return "?"


func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = REFRESH_INTERVAL
		_refresh()


func _refresh() -> void:
	if _skill_system == null or not is_instance_valid(_skill_system):
		return
	for i in _rows.size():
		var entry: Dictionary = SkillSystem.SKILL_DATABASE[i]
		var skill_id: String = entry.get("id", "")
		var skill_name: String = entry.get("name", skill_id)
		var key := _action_key_text("skill_%d" % (i + 1))
		var row := _rows[i]
		if not Global.hub_test_mode and not ProgressionTracker.is_skill_unlocked(skill_id):
			row.text = "[%s] %s — locked" % [key, skill_name]
			row.modulate = Color(1, 1, 1, 0.35)
			continue
		var cd: float = _skill_system.get_cooldown_remaining(skill_id)
		if cd > 0.0:
			row.text = "[%s] %s — %.1fs" % [key, skill_name, cd]
			row.modulate = Color(1, 0.75, 0.5, 0.9)
		else:
			row.text = "[%s] %s — READY" % [key, skill_name]
			row.modulate = Color(0.8, 1, 0.8, 1)
