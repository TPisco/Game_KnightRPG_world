## Controls remapping screen: click an action, press the new key/mouse button.
## Changes apply instantly and persist via SaveManager settings.
extends Control

const MENU := "res://scenes/ui/MainMenu.tscn"

## action name -> label shown to the player (order = display order).
const REMAP_ACTIONS := [
	["foward", "Move Forward"],
	["backward", "Move Backward"],
	["left", "Move Left"],
	["right", "Move Right"],
	["jump", "Jump"],
	["attack", "Attack / Fire"],
	["Guard", "Guard / Cast"],
	["skill", "Use Active Skill"],
	["skill_1", "Power 1 (Power Slash)"],
	["skill_2", "Power 2 (Arcane Bolt)"],
	["skill_3", "Power 3 (Iron Wall)"],
	["skill_4", "Power 4 (Life Drain)"],
	["hotbar_1", "Hotbar Slot 1"],
	["hotbar_2", "Hotbar Slot 2"],
	["hotbar_3", "Hotbar Slot 3"],
	["hotbar_4", "Hotbar Slot 4"],
	["hotbar_5", "Hotbar Slot 5"],
	["interact", "Pick Up Item"],
	["inventory", "Inventory"],
	["skill_menu", "Skills & Stats Menu"],
	["switch", "Switch Camera View"],
	["escape", "Quit To Menu"],
]

@onready var rows_box: VBoxContainer = $Panel/Margin/VBox/Scroll/Rows
@onready var status_label: Label = $Panel/Margin/VBox/StatusLabel

var _listening_action: String = ""
var _listening_button: Button = null
var _key_buttons: Dictionary = {}  # action -> Button


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	for entry in REMAP_ACTIONS:
		rows_box.add_child(_build_row(entry[0], entry[1]))
	_set_status("Click a key button, then press the new key or mouse button.")


func _build_row(action: String, display_name: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var name_label := Label.new()
	name_label.text = display_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)

	var key_btn := Button.new()
	key_btn.text = _action_key_text(action)
	key_btn.custom_minimum_size = Vector2(170, 0)
	key_btn.pressed.connect(_on_key_button_pressed.bind(action, key_btn))
	row.add_child(key_btn)
	_key_buttons[action] = key_btn
	return row


func _action_key_text(action: String) -> String:
	if not InputMap.has_action(action):
		return "?"
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key := event as InputEventKey
			var code := key.physical_keycode if key.physical_keycode != 0 else key.keycode
			return OS.get_keycode_string(code)
		if event is InputEventMouseButton:
			match (event as InputEventMouseButton).button_index:
				MOUSE_BUTTON_LEFT: return "Left Click"
				MOUSE_BUTTON_RIGHT: return "Right Click"
				MOUSE_BUTTON_MIDDLE: return "Middle Click"
				_: return "Mouse %d" % (event as InputEventMouseButton).button_index
	return "—"


func _on_key_button_pressed(action: String, btn: Button) -> void:
	# Cancel a previous pending listen, if any.
	if _listening_button and is_instance_valid(_listening_button):
		_listening_button.text = _action_key_text(_listening_action)
	_listening_action = action
	_listening_button = btn
	btn.text = "Press a key..."
	_set_status("Press the new key or mouse button (Esc cancels).")


func _input(event: InputEvent) -> void:
	if _listening_action == "":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		if (event as InputEventKey).physical_keycode == KEY_ESCAPE:
			_cancel_listening()
			return
		_apply_binding(event)
	elif event is InputEventMouseButton and event.pressed:
		# Ignore the click that pressed the button itself (same frame).
		if _listening_button and _listening_button.get_global_rect().has_point((event as InputEventMouseButton).global_position):
			return
		get_viewport().set_input_as_handled()
		_apply_binding(event)


func _cancel_listening() -> void:
	if _listening_button and is_instance_valid(_listening_button):
		_listening_button.text = _action_key_text(_listening_action)
	_listening_action = ""
	_listening_button = null
	_set_status("Cancelled. Click a key button to remap.")


func _apply_binding(event: InputEvent) -> void:
	var action := _listening_action
	SaveManager.set_input_override(action, event)
	_listening_action = ""
	_listening_button = null
	_refresh_all_buttons()
	_set_status("'%s' rebound to %s. Saved." % [_display_name_for(action), _action_key_text(action)])
	SoundManager.play("buy")


func _display_name_for(action: String) -> String:
	for entry in REMAP_ACTIONS:
		if entry[0] == action:
			return entry[1]
	return action


func _refresh_all_buttons() -> void:
	for action in _key_buttons:
		var btn := _key_buttons[action] as Button
		if btn and is_instance_valid(btn):
			btn.text = _action_key_text(action)


func _set_status(text: String) -> void:
	if status_label:
		status_label.text = text


func _on_reset_pressed() -> void:
	_cancel_listening()
	SaveManager.clear_input_overrides()
	_refresh_all_buttons()
	_set_status("All controls reset to defaults.")


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MENU)
