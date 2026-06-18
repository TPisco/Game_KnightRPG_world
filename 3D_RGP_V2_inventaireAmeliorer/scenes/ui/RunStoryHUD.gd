## In-run story layer: realm name and hints as the player delves deeper.
extends CanvasLayer

@onready var realm_label: Label = $Panel/RealmLabel
@onready var hint_label: Label = $Panel/HintLabel
@onready var boss_label: Label = $Panel/BossLabel

var _last_depth: int = -1


func _ready() -> void:
	ProgressionTracker.level_up.connect(func(_l): _flash_hint("Level up! Allocate stats with K."))
	visible = true


func _process(_delta: float) -> void:
	var depth := ProgressionTracker.run_depth
	if depth != _last_depth:
		_last_depth = depth
		_update_realm(depth)


func _update_realm(depth: int) -> void:
	var realm: Dictionary = BossRegistry.get_realm_for_depth(depth)
	Global.current_realm = realm.get("id", "fractured_wastes")
	if realm_label:
		realm_label.text = realm.get("name", "Fractured Wastes")
	if hint_label:
		hint_label.text = realm.get("hint", "")


func show_boss_warning(milestone: int) -> void:
	if boss_label:
		boss_label.text = "⚠ %s approaches!" % BossRegistry.get_boss_name(milestone)
		boss_label.visible = true
		var tween := create_tween()
		tween.tween_interval(4.0)
		tween.tween_callback(func(): boss_label.visible = false)


func _flash_hint(text: String) -> void:
	if hint_label:
		var old := hint_label.text
		hint_label.text = text
		var tween := create_tween()
		tween.tween_interval(3.0)
		tween.tween_callback(func(): hint_label.text = old)
