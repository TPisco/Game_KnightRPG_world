## Main menu: Start Run, Continue, Settings, Credits.
extends Control

const FRACTURED_RUN := "res://scenes/world/FracturedRun.tscn"
const STORY_INTRO := "res://scenes/ui/StoryIntro.tscn"
const HUB_WORLD := "res://scenes/world.tscn"
const SAVE_SELECT := "res://scenes/ui/SaveSelect.tscn"
const CONTROLS_MENU := "res://scenes/ui/ControlsMenu.tscn"

@onready var continue_btn: Button = $Panel/VBox/ContinueBtn
@onready var settings_panel: Panel = $SettingsPanel
@onready var credits_panel: Panel = $CreditsPanel
@onready var sensitivity_slider: HSlider = $SettingsPanel/SensitivitySlider
@onready var sensitivity_value: Label = $SettingsPanel/SensitivityValue


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Leaving the hub ends test mode; reload the active slot from disk.
	var was_hub_testing := Global.hub_test_mode or Global.hub_test_applied
	Global.hub_test_mode = false
	Global.hub_test_applied = false
	if not SaveManager.reload_active_slot() and was_hub_testing:
		ProgressionTracker.reset_progression()
	continue_btn.disabled = not SaveManager.has_any_save()
	if sensitivity_slider:
		sensitivity_slider.value = ProgressionTracker.mouse_sensitivity
		sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
		_on_sensitivity_changed(sensitivity_slider.value)


func _on_start_run_pressed() -> void:
	Global.start_new_run()
	if not ProgressionTracker.story_seen:
		get_tree().change_scene_to_file(STORY_INTRO)
	else:
		get_tree().change_scene_to_file(FRACTURED_RUN)


func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file(SAVE_SELECT)


func _on_hub_pressed() -> void:
	get_tree().change_scene_to_file(HUB_WORLD)


func _on_settings_pressed() -> void:
	settings_panel.visible = true


func _on_controls_pressed() -> void:
	get_tree().change_scene_to_file(CONTROLS_MENU)


func _on_credits_pressed() -> void:
	credits_panel.visible = true


func _on_close_settings_pressed() -> void:
	settings_panel.visible = false


func _on_close_credits_pressed() -> void:
	credits_panel.visible = false


func _on_sensitivity_changed(value: float) -> void:
	ProgressionTracker.mouse_sensitivity = value
	SaveManager.save_settings()
	if sensitivity_value:
		sensitivity_value.text = "%.3f" % value
	if Global.player_node and "sensivity" in Global.player_node:
		Global.player_node.sensivity = value


func _on_quit_pressed() -> void:
	get_tree().quit()
