## Continue Game screen: lists every save slot; click one to resume that run.
extends Control

const FRACTURED_RUN := "res://scenes/world/FracturedRun.tscn"
const MENU := "res://scenes/ui/MainMenu.tscn"

@onready var rows_box: VBoxContainer = $Panel/Margin/VBox/Scroll/Rows
@onready var empty_label: Label = $Panel/Margin/VBox/EmptyLabel


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_rebuild_list()


func _rebuild_list() -> void:
	for child in rows_box.get_children():
		child.queue_free()
	var saves: Array = SaveManager.list_saves()
	if empty_label:
		empty_label.visible = saves.is_empty()
	for meta in saves:
		rows_box.add_child(_build_row(meta))


func _build_row(meta: Dictionary) -> Control:
	var panel := PanelContainer.new()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)

	var info := Label.new()
	info.text = "Run #%d  —  Lv %d  —  %s (Realm %d, Depth %d)\nGold: %d  |  Items: %d  |  Last played: %s" % [
		meta["run_number"], meta["level"], meta["realm_name"],
		meta["realm_index"], meta["depth"],
		meta["gold"], meta["item_count"], meta["last_played_text"],
	]
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)

	var load_btn := Button.new()
	load_btn.text = "Load"
	load_btn.custom_minimum_size = Vector2(90, 0)
	load_btn.pressed.connect(_on_load_pressed.bind(int(meta["slot"])))
	row.add_child(load_btn)

	var delete_btn := Button.new()
	delete_btn.text = "Delete"
	delete_btn.custom_minimum_size = Vector2(90, 0)
	delete_btn.pressed.connect(_on_delete_pressed.bind(int(meta["slot"]), delete_btn))
	row.add_child(delete_btn)

	return panel


func _on_load_pressed(slot: int) -> void:
	if not SaveManager.load_slot(slot):
		return
	Global.continue_run = true
	Global.hub_test_mode = false
	Global.hub_test_applied = false
	get_tree().change_scene_to_file(FRACTURED_RUN)


## Two-step delete: first click arms the button, second click removes the file.
func _on_delete_pressed(slot: int, btn: Button) -> void:
	if btn.text != "Sure?":
		btn.text = "Sure?"
		return
	SaveManager.delete_slot(slot)
	_rebuild_list()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MENU)
