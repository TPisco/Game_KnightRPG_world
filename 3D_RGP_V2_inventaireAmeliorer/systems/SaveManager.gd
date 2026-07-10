## Multi-slot save system: each run lives in its own file under user://saves/.
## Global settings (sensitivity, story seen, run counter) are shared in one file.
extends Node

const SAVE_DIR := "user://saves"
const SETTINGS_PATH := "user://settings.save"
const LEGACY_PATH := "user://progression.save"
const NO_POSITION := Vector3(0, 99999, 0)

var active_slot: int = -1

## Global (not per-save) settings, loaded before ProgressionTracker._ready.
var settings: Dictionary = {
	"story_seen": false,
	"mouse_sensitivity": 0.003,
	"total_runs": 0,
	"input_overrides": {},
}

# State handed to the next spawned player after load_slot().
var _pending_inventory = null  # Dictionary or null
var _pending_gold: int = -1
var _pending_player_pos: Vector3 = NO_POSITION


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	_load_settings()
	_migrate_legacy_save()
	apply_input_overrides()


# --- Input remapping (persisted in the shared settings file) ---------------

## Re-applies every saved key/mouse rebinding onto Godot's InputMap.
func apply_input_overrides() -> void:
	var overrides = settings.get("input_overrides", {})
	if typeof(overrides) != TYPE_DICTIONARY:
		return
	for action in overrides:
		if not InputMap.has_action(action):
			continue
		var event := _override_to_event(overrides[action])
		if event == null:
			continue
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, event)


func _override_to_event(data) -> InputEvent:
	if typeof(data) != TYPE_DICTIONARY:
		return null
	match str(data.get("type", "")):
		"key":
			var key := InputEventKey.new()
			key.physical_keycode = int(data.get("code", 0)) as Key
			return key
		"mouse":
			var mouse := InputEventMouseButton.new()
			mouse.button_index = int(data.get("code", 1)) as MouseButton
			return mouse
	return null


## Stores one rebinding and applies it immediately.
func set_input_override(action: String, event: InputEvent) -> void:
	var data := {}
	if event is InputEventKey:
		var key := event as InputEventKey
		var code := key.physical_keycode if key.physical_keycode != 0 else key.keycode
		data = {"type": "key", "code": int(code)}
	elif event is InputEventMouseButton:
		data = {"type": "mouse", "code": int((event as InputEventMouseButton).button_index)}
	else:
		return
	if typeof(settings.get("input_overrides")) != TYPE_DICTIONARY:
		settings["input_overrides"] = {}
	settings["input_overrides"][action] = data
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, _override_to_event(data))
	save_settings()


## Removes every rebinding and restores the project's default controls.
func clear_input_overrides() -> void:
	settings["input_overrides"] = {}
	InputMap.load_from_project_settings()
	save_settings()


# --- Global settings -------------------------------------------------------

func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if not file:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		for key in settings.keys():
			if parsed.has(key):
				settings[key] = parsed[key]


func save_settings() -> void:
	settings["story_seen"] = ProgressionTracker.story_seen
	settings["mouse_sensitivity"] = ProgressionTracker.mouse_sensitivity
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(settings))
		file.close()


# --- Slot management -------------------------------------------------------

func _slot_path(slot: int) -> String:
	return "%s/slot_%d.save" % [SAVE_DIR, slot]


func get_save_count() -> int:
	return list_saves().size()


func has_any_save() -> bool:
	var dir := DirAccess.open(SAVE_DIR)
	if dir == null:
		return false
	for file_name in dir.get_files():
		if file_name.begins_with("slot_") and file_name.ends_with(".save"):
			return true
	return false


## Summaries of every save file, most recently played first.
func list_saves() -> Array:
	var result: Array = []
	var dir := DirAccess.open(SAVE_DIR)
	if dir == null:
		return result
	for file_name in dir.get_files():
		if not (file_name.begins_with("slot_") and file_name.ends_with(".save")):
			continue
		var data := _read_slot_file("%s/%s" % [SAVE_DIR, file_name])
		if data.is_empty():
			continue
		var prog: Dictionary = data.get("progression", {})
		var world: Dictionary = data.get("world", {})
		var depth := int(prog.get("run_depth", 0))
		result.append({
			"slot": int(data.get("slot", -1)),
			"run_number": int(data.get("run_number", 0)),
			"level": int(prog.get("level", 1)),
			"depth": depth,
			"realm_index": int(prog.get("cave_portals_cleared", 0)) + 1,
			"realm_name": str(world.get("realm_name", BossRegistry.get_realm_for_depth(depth).get("name", "Fractured Wastes"))),
			"gold": int(world.get("gold", 0)),
			"item_count": (data.get("inventory", {}) as Dictionary).get("items", []).size(),
			"last_played_text": str(data.get("last_played_text", "unknown")),
			"last_played_unix": int(data.get("last_played_unix", 0)),
		})
	result.sort_custom(func(a, b): return a["last_played_unix"] > b["last_played_unix"])
	return result


func _read_slot_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func _next_free_slot() -> int:
	var used: Array[int] = []
	var dir := DirAccess.open(SAVE_DIR)
	if dir:
		for file_name in dir.get_files():
			if file_name.begins_with("slot_") and file_name.ends_with(".save"):
				used.append(int(file_name.trim_prefix("slot_").trim_suffix(".save")))
	var slot := 1
	while slot in used:
		slot += 1
	return slot


## Start New Run: fresh progression in a brand-new slot; old saves untouched.
func create_new_save() -> int:
	active_slot = _next_free_slot()
	clear_pending_state()
	settings["total_runs"] = int(settings.get("total_runs", 0)) + 1
	ProgressionTracker.reset_progression()
	ProgressionTracker.run_seed = randi()
	ProgressionTracker.refresh_skill_unlocks()
	save_settings()
	save_active_slot()
	return active_slot


func delete_slot(slot: int) -> void:
	var path := _slot_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	if active_slot == slot:
		active_slot = -1


# --- Saving ----------------------------------------------------------------

## Writes the active slot: progression + live inventory/world when the player
## exists, otherwise whatever the file already holds is preserved.
func save_active_slot() -> void:
	if active_slot < 0:
		return
	if Global.hub_test_mode:
		return

	var path := _slot_path(active_slot)
	var previous := _read_slot_file(path)
	var data := {
		"slot": active_slot,
		"run_number": previous.get("run_number", settings.get("total_runs", 1)),
		"created_unix": previous.get("created_unix", Time.get_unix_time_from_system()),
		"last_played_unix": Time.get_unix_time_from_system(),
		"last_played_text": Time.get_datetime_string_from_system(false, true),
		"progression": ProgressionTracker.get_save_dict(),
		"inventory": previous.get("inventory", {"items": [], "equipped": -1}),
		"world": previous.get("world", {}),
	}

	var player = Global.player_node
	if player and is_instance_valid(player) and player.is_inside_tree():
		var inv = player.get_node_or_null("InventoryUI")
		if inv and inv.has_method("serialize_inventory"):
			data["inventory"] = inv.serialize_inventory()
		var scene: Node = player.get_tree().current_scene
		var pos: Vector3 = player.global_position
		data["world"] = {
			"scene": "hub" if HubWorldStartup.is_hub_scene(scene) else "run",
			"player_pos": [pos.x, pos.y, pos.z],
			"gold": int(player.gold) if "gold" in player else 0,
			"realm_name": BossRegistry.get_realm_for_depth(ProgressionTracker.run_depth).get("name", ""),
		}

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()


# --- Loading ---------------------------------------------------------------

## Loads a slot into ProgressionTracker and queues inventory/gold/position
## for the next player spawn. Returns false if the file is missing/corrupt.
func load_slot(slot: int) -> bool:
	var data := _read_slot_file(_slot_path(slot))
	if data.is_empty():
		return false
	active_slot = slot
	ProgressionTracker.apply_save_dict(data.get("progression", {}))

	clear_pending_state()
	var inv = data.get("inventory", null)
	if typeof(inv) == TYPE_DICTIONARY and not (inv as Dictionary).get("items", []).is_empty():
		_pending_inventory = inv
	var world: Dictionary = data.get("world", {})
	_pending_gold = int(world.get("gold", -1)) if world.has("gold") else -1
	var pos = world.get("player_pos", null)
	if pos is Array and pos.size() == 3:
		_pending_player_pos = Vector3(float(pos[0]), float(pos[1]), float(pos[2]))
	return true


## Re-applies the active slot from disk (e.g. returning from hub test mode).
func reload_active_slot() -> bool:
	if active_slot < 0:
		return false
	var data := _read_slot_file(_slot_path(active_slot))
	if data.is_empty():
		return false
	ProgressionTracker.apply_save_dict(data.get("progression", {}))
	return true


func clear_pending_state() -> void:
	_pending_inventory = null
	_pending_gold = -1
	_pending_player_pos = NO_POSITION


func take_pending_inventory():
	var inv = _pending_inventory
	_pending_inventory = null
	return inv


func take_pending_gold() -> int:
	var g := _pending_gold
	_pending_gold = -1
	return g


func take_pending_player_pos() -> Vector3:
	var p := _pending_player_pos
	_pending_player_pos = NO_POSITION
	return p


## Queue a spawn position for the next world load (used by "Restart Here").
func queue_player_position(pos: Vector3) -> void:
	_pending_player_pos = pos


# --- Legacy migration ------------------------------------------------------

## Converts the old single progression.save into slot 1 (once).
func _migrate_legacy_save() -> void:
	if has_any_save() or not FileAccess.file_exists(LEGACY_PATH):
		return
	var file := FileAccess.open(LEGACY_PATH, FileAccess.READ)
	if not file:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	settings["story_seen"] = parsed.get("story_seen", false)
	settings["mouse_sensitivity"] = parsed.get("mouse_sensitivity", 0.003)
	settings["total_runs"] = parsed.get("total_runs", 1)
	var slot_data := {
		"slot": 1,
		"run_number": 1,
		"created_unix": Time.get_unix_time_from_system(),
		"last_played_unix": Time.get_unix_time_from_system(),
		"last_played_text": Time.get_datetime_string_from_system(false, true),
		"progression": parsed,
		"inventory": {"items": [], "equipped": -1},
		"world": {},
	}
	var out := FileAccess.open(_slot_path(1), FileAccess.WRITE)
	if out:
		out.store_string(JSON.stringify(slot_data))
		out.close()
	var settings_file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if settings_file:
		settings_file.store_string(JSON.stringify(settings))
		settings_file.close()
	DirAccess.rename_absolute(LEGACY_PATH, LEGACY_PATH + ".bak")
	print("Migrated legacy save into slot 1.")
