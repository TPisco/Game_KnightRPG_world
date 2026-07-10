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
	"cave_portal": [
		{"speaker": "The Rift", "text": "The guardian falls. A portal opens deeper into the fractured multiverse."},
	],
	"skill_unlocked": [
		{"speaker": "Ancient Knowledge", "text": "A forgotten power surges through you. A new skill is yours to wield."},
	],
	"boss_defeat": [
		{"speaker": "Ancient Being", "text": "You have conquered me... but the path remains hidden in deeper rifts."},
	],
	"boss_warning": [
		{"speaker": "Whisper", "text": "A guardian stirs. Steel yourself, knight."},
	],
	"ending": [
		{"speaker": "The Void Warden", "text": "The gate... opens. The path you seek was sealed behind me."},
		{"speaker": "Unknown Voice", "text": "The fractures tremble. For the first time, you glimpse your own world beyond the rift."},
		{"speaker": "Unknown Voice", "text": "Step through, knight — or delve deeper. The multiverse still holds its secrets."},
	],
	"random_dungeon_clear": [
		{"speaker": "The Rift", "text": "The vault falls silent. Take your spoils, knight — the return portal glows green."},
	],
	"dungeon_enter": [
		{"speaker": "The Rift", "text": "A sealed chamber between worlds. Something old guards this place."},
	],
	"dungeon_first_clear": [
		{"speaker": "The Rift", "text": "The first seal shatters. One more guardian holds the way to this realm's master."},
	],
	"dungeon_unlocked": [
		{"speaker": "The Rift", "text": "The second seal breaks! The Boss Gate burns crimson — the realm's master awaits."},
	],
	"hub_memory": [
		{"speaker": "Memory", "text": "This place... a fragment of the world you were torn from. It holds, for now."},
		{"speaker": "Memory", "text": "Rest. Prepare. Beyond the rifts, the fractured worlds are waiting."},
	],
	"shop_first": [
		{"speaker": "The Collector", "text": "Another one pulled through the cracks... A knight, this time. Curious."},
		{"speaker": "The Collector", "text": "I gather what the fracture scatters — blades, powder-arms, staffs, bottled light. All for a price."},
		{"speaker": "The Collector", "text": "Gold means little between worlds, yet I collect it still. Spend it — you will not survive the deep rifts empty-handed."},
	],
	"shop_visit": [
		{"speaker": "The Collector", "text": "Back again, knight. The rifts grow hungrier — browse, and arm yourself."},
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


func trigger_cave_portal() -> void:
	await trigger_story_event("cave_portal")


func trigger_boss_defeat(boss_name: String = "") -> void:
	await trigger_story_event("boss_defeat", boss_name)


func trigger_boss_warning() -> void:
	await trigger_story_event("boss_warning")


func trigger_ending() -> void:
	await trigger_story_event("ending")
