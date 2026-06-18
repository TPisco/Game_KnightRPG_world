## Unified story layer: intro, world transitions, boss defeats, ending.
extends Node

signal line_shown(speaker: String, text: String)
signal beat_started(beat_id: String)
signal beat_finished(beat_id: String)

const DIALOGUE_UI_SCENE := preload("res://scenes/ui/DialogueUI.tscn")

var current_beat: String = ""
var _dialogue_ui: CanvasLayer
var _playing: bool = false

const STORY_BEATS: Dictionary = {
	"intro": [
		{"speaker": "Unknown Voice", "text": "You are torn from your world by a mysterious force..."},
		{"speaker": "Unknown Voice", "text": "Thrown into a fractured multiverse, you must fight through hostile realms."},
		{"speaker": "Unknown Voice", "text": "Somewhere beyond the chaos lies a path home. Will you find it?"},
	],
	"world_change": [
		{"speaker": "The Rift", "text": "A new fractured realm unfolds. The danger escalates with every step."},
	],
	"boss_defeat": [
		{"speaker": "Ancient Being", "text": "You have conquered me... but the path remains hidden in deeper rifts."},
	],
	"boss_warning": [
		{"speaker": "Whisper", "text": "A guardian stirs. Steel yourself, knight."},
	],
	"ending": [
		{"speaker": "Unknown Voice", "text": "Only the strongest will find the path home. Press on, fractured knight."},
	],
}


func _ready() -> void:
	_dialogue_ui = DIALOGUE_UI_SCENE.instantiate()
	add_child(_dialogue_ui)
	_dialogue_ui.visible = false


func trigger_story_event(event_name: String, boss_name: String = "") -> void:
	if _playing:
		return
	_playing = true
	current_beat = event_name
	beat_started.emit(event_name)
	var beats: Array = STORY_BEATS.get(event_name, []).duplicate()
	if event_name == "boss_defeat" and boss_name != "":
		beats.append({"speaker": boss_name, "text": "The rift trembles. Another shard of the multiverse opens..."})
	await show_dialogue(beats)
	beat_finished.emit(event_name)
	current_beat = ""
	_playing = false


func show_dialogue(beats: Array) -> void:
	if beats.is_empty():
		return
	if _dialogue_ui == null:
		return
	_dialogue_ui.visible = true
	for beat in beats:
		if typeof(beat) != TYPE_DICTIONARY:
			continue
		var speaker: String = beat.get("speaker", "")
		var text: String = beat.get("text", "")
		line_shown.emit(speaker, text)
		if _dialogue_ui.has_method("show_line"):
			await _dialogue_ui.show_line(speaker, text)
		else:
			await get_tree().create_timer(2.5).timeout
	if _dialogue_ui.has_method("hide_dialogue"):
		_dialogue_ui.hide_dialogue()
	else:
		_dialogue_ui.visible = false


func trigger_intro() -> void:
	await trigger_story_event("intro")


func trigger_world_change(_world_index: int = 0) -> void:
	await trigger_story_event("world_change")


func trigger_boss_defeat(boss_name: String = "") -> void:
	await trigger_story_event("boss_defeat", boss_name)


func trigger_boss_warning() -> void:
	await trigger_story_event("boss_warning")


func trigger_ending() -> void:
	await trigger_story_event("ending")
