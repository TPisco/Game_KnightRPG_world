## Main menu: Start Run, Continue, Settings, Credits.
extends Control

const FRACTURED_RUN := "res://scenes/world/FracturedRun.tscn"
const STORY_INTRO := "res://scenes/ui/StoryIntro.tscn"
const HUB_WORLD := "res://scenes/world.tscn"

@onready var continue_btn: Button = $Panel/VBox/ContinueBtn
@onready var settings_panel: Panel = $SettingsPanel
@onready var credits_panel: Panel = $CreditsPanel
@onready var sensitivity_slider: HSlider = $SettingsPanel/SensitivitySlider
@onready var sensitivity_value: Label = $SettingsPanel/SensitivityValue


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	continue_btn.disabled = not ProgressionTracker.has_save()
	ProgressionTracker.load_game()
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
	Global.continue_run = true
	get_tree().change_scene_to_file(FRACTURED_RUN)


func _on_hub_pressed() -> void:
	get_tree().change_scene_to_file(HUB_WORLD)


func _on_settings_pressed() -> void:
	settings_panel.visible = true


func _on_credits_pressed() -> void:
	credits_panel.visible = true


func _on_close_settings_pressed() -> void:
	settings_panel.visible = false


func _on_close_credits_pressed() -> void:
	credits_panel.visible = false


func _on_sensitivity_changed(value: float) -> void:
	ProgressionTracker.mouse_sensitivity = value
	ProgressionTracker.save_game()
	if sensitivity_value:
		sensitivity_value.text = "%.3f" % value
	if Global.player_node and "sensivity" in Global.player_node:
		Global.player_node.sensivity = value


func _on_quit_pressed() -> void:
	get_tree().quit()
