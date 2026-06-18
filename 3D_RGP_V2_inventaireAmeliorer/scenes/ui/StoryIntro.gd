## First-run story intro for the fractured multiverse.
extends Control

const FRACTURED_RUN := "res://scenes/world/FracturedRun.tscn"
const MENU := "res://scenes/ui/MainMenu.tscn"

@onready var panel: Panel = $Panel


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	panel.visible = false
	StoryManager.beat_finished.connect(_on_beat_finished)
	StoryManager.trigger_intro()


func _on_beat_finished(beat_id: String) -> void:
	if beat_id == "intro":
		panel.visible = true


func _on_continue_pressed() -> void:
	ProgressionTracker.story_seen = true
	ProgressionTracker.save_game()
	get_tree().change_scene_to_file(FRACTURED_RUN)


func _on_skip_pressed() -> void:
	ProgressionTracker.story_seen = true
	ProgressionTracker.save_game()
	get_tree().change_scene_to_file(MENU)
