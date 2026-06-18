## Dialogue overlay driven by StoryManager autoload.
extends CanvasLayer

signal line_finished

@onready var panel: Panel = $Panel
@onready var speaker_label: Label = $Panel/SpeakerLabel
@onready var text_label: Label = $Panel/TextLabel
@onready var continue_hint: Label = $Panel/ContinueHint

var _waiting: bool = false


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not _waiting:
		return
	if event.is_action_pressed("ui_accept") or event is InputEventMouseButton and event.pressed:
		_waiting = false


func show_line(speaker: String, text: String) -> void:
	visible = true
	panel.visible = true
	speaker_label.text = speaker
	text_label.text = text
	continue_hint.text = "[ Click or Enter to continue ]"
	_waiting = true
	while _waiting:
		await get_tree().process_frame
	line_finished.emit()


func hide_dialogue() -> void:
	visible = false
	_waiting = false
