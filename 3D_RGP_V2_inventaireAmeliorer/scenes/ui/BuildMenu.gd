## Parchment catalog for the home editor: categories on the left, furnishings
## on the right, travel shortcuts between the hub and the tavern, and a live
## hint bar showing the current tool state.
class_name BuildMenu
extends CanvasLayer

signal entry_selected(entry: Dictionary)
signal travel_requested(scene_path: String)
signal exit_requested()

const INK := Color(0.24, 0.16, 0.09)
const INK_FADED := Color(0.45, 0.36, 0.26)
const HUB_SCENE := "res://scenes/world.tscn"
const TAVERN_SCENE := "res://scenes/world_2.tscn"

var _panel: PanelContainer
var _hint_panel: PanelContainer
var _category_box: VBoxContainer
var _item_box: VBoxContainer
var _status: Label
var _travel_btn: Button
var _current_category: int = 0
var _item_buttons: Dictionary = {}  # entry id -> Button
var _selected_id: String = ""


func _ready() -> void:
	layer = 9
	_build_ui()
	visible = false


func open() -> void:
	visible = true
	_refresh_travel_button()
	_show_category(_current_category)


func close() -> void:
	visible = false


func set_status(text: String) -> void:
	if _status:
		_status.text = text


func highlight_entry(entry: Dictionary) -> void:
	_selected_id = str(entry.get("id", ""))
	_apply_highlight()


func _apply_highlight() -> void:
	for id in _item_buttons:
		var btn := _item_buttons[id] as Button
		if btn and is_instance_valid(btn):
			btn.modulate = Color(1, 0.9, 0.55) if id == _selected_id else Color.WHITE


# --- UI -----------------------------------------------------------------

## True when the cursor sits over the catalog or the hint bar, so the world
## click handler can stand aside without relying on GUI event propagation.
func blocks_pointer() -> bool:
	if not visible:
		return false
	var mouse := get_viewport().get_mouse_position()
	if _panel and _panel.get_global_rect().has_point(mouse):
		return true
	if _hint_panel and _hint_panel.get_global_rect().has_point(mouse):
		return true
	return false


func _build_ui() -> void:
	var panel := PanelContainer.new()
	_panel = panel
	panel.add_theme_stylebox_override("panel", _parchment())
	add_child(panel)
	panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	panel.offset_left = 16
	panel.offset_right = 372
	panel.offset_top = 40
	panel.offset_bottom = -120

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 12)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	var title := Label.new()
	title.text = "Home Editor"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	box.add_child(_rule())

	var cat_label := Label.new()
	cat_label.text = "Categories"
	cat_label.add_theme_font_size_override("font_size", 14)
	cat_label.add_theme_color_override("font_color", INK_FADED)
	box.add_child(cat_label)

	var cat_scroll := ScrollContainer.new()
	cat_scroll.custom_minimum_size = Vector2(0, 150)
	box.add_child(cat_scroll)
	_category_box = VBoxContainer.new()
	_category_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cat_scroll.add_child(_category_box)

	var categories := BuildCatalog.categories()
	for i in categories.size():
		var btn := Button.new()
		btn.text = str(categories[i]["name"])
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_show_category.bind(i))
		_category_box.add_child(btn)

	box.add_child(_rule())

	var item_label := Label.new()
	item_label.text = "Furnishings"
	item_label.add_theme_font_size_override("font_size", 14)
	item_label.add_theme_color_override("font_color", INK_FADED)
	box.add_child(item_label)

	var item_scroll := ScrollContainer.new()
	item_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(item_scroll)
	_item_box = VBoxContainer.new()
	_item_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_scroll.add_child(_item_box)

	box.add_child(_rule())

	_travel_btn = Button.new()
	_travel_btn.pressed.connect(_on_travel)
	box.add_child(_travel_btn)

	var exit_btn := Button.new()
	exit_btn.text = "Finish Editing  [B]"
	exit_btn.pressed.connect(func(): exit_requested.emit())
	box.add_child(exit_btn)

	# Hint bar along the bottom of the screen.
	var hint_panel := PanelContainer.new()
	_hint_panel = hint_panel
	var dark := StyleBoxFlat.new()
	dark.bg_color = Color(0.09, 0.07, 0.06, 0.85)
	dark.border_color = Color(0.5, 0.38, 0.2)
	for side in ["border_width_left", "border_width_top", "border_width_right", "border_width_bottom"]:
		dark.set(side, 2)
	for corner in ["corner_radius_top_left", "corner_radius_top_right",
			"corner_radius_bottom_left", "corner_radius_bottom_right"]:
		dark.set(corner, 8)
	hint_panel.add_theme_stylebox_override("panel", dark)
	add_child(hint_panel)
	hint_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint_panel.offset_left = -330
	hint_panel.offset_right = 330
	hint_panel.offset_top = -108
	hint_panel.offset_bottom = -16

	var hint_margin := MarginContainer.new()
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		hint_margin.add_theme_constant_override(side, 10)
	hint_panel.add_child(hint_margin)

	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 14)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_margin.add_child(_status)


func _parchment() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.88, 0.81, 0.66)
	style.border_color = Color(0.48, 0.34, 0.18)
	for side in ["border_width_left", "border_width_top", "border_width_right", "border_width_bottom"]:
		style.set(side, 3)
	for corner in ["corner_radius_top_left", "corner_radius_top_right",
			"corner_radius_bottom_left", "corner_radius_bottom_right"]:
		style.set(corner, 10)
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 8
	return style


func _rule() -> ColorRect:
	var rule := ColorRect.new()
	rule.color = Color(0.55, 0.44, 0.30, 0.7)
	rule.custom_minimum_size = Vector2(0, 2)
	return rule


func _show_category(index: int) -> void:
	_current_category = index
	var categories := BuildCatalog.categories()
	if index < 0 or index >= categories.size():
		return
	for child in _item_box.get_children():
		child.visible = false
		child.queue_free()
	_item_buttons.clear()

	var bosses: int = ProgressionTracker.bosses_defeated
	for raw in categories[index]["items"]:
		var entry: Dictionary = raw
		var btn := Button.new()
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if BuildCatalog.is_unlocked(entry, bosses):
			btn.text = str(entry["name"])
			btn.pressed.connect(_on_entry_pressed.bind(entry))
		else:
			btn.text = "%s  (defeat %d boss%s)" % [
				str(entry["name"]), int(entry["unlock"]),
				"" if int(entry["unlock"]) == 1 else "es",
			]
			btn.disabled = true
		_item_box.add_child(btn)
		_item_buttons[str(entry["id"])] = btn
	_apply_highlight()


func _on_entry_pressed(entry: Dictionary) -> void:
	_selected_id = str(entry.get("id", ""))
	_apply_highlight()
	entry_selected.emit(entry)


func _refresh_travel_button() -> void:
	if _travel_btn == null:
		return
	var scene := get_tree().current_scene
	var path: String = scene.scene_file_path if scene else ""
	if path == TAVERN_SCENE:
		_travel_btn.text = "Go Outside (Hub)"
	else:
		_travel_btn.text = "Go Inside (Tavern)"


func _on_travel() -> void:
	var scene := get_tree().current_scene
	var path: String = scene.scene_file_path if scene else ""
	travel_requested.emit(HUB_SCENE if path == TAVERN_SCENE else TAVERN_SCENE)
