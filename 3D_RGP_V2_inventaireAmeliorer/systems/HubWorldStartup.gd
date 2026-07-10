## Grants all skills, weapons, and max stats in hub worlds for testing.
class_name HubWorldStartup
extends Node

const HUB_SCENES := [
	"res://scenes/world.tscn",
	"res://scenes/world_2.tscn",
]


static func is_hub_scene(scene: Node) -> bool:
	if scene == null:
		return false
	return scene.scene_file_path in HUB_SCENES


static func grant_testing_power(knight: Node) -> void:
	if knight == null:
		return
	Global.hub_test_mode = true
	if knight.has_method("_setup_hub_testing"):
		knight._setup_hub_testing()
	elif knight.has_method("setup_for_hub_testing"):
		knight.setup_for_hub_testing()
	print("Hub World Test Mode: all powers and weapons granted!")


func _ready() -> void:
	call_deferred("_grant_when_ready")


func _grant_when_ready() -> void:
	await get_tree().process_frame
	var knight := get_tree().get_first_node_in_group("Player")
	if knight == null:
		knight = get_parent().find_child("player", true, false)
	if knight:
		grant_testing_power(knight)
	if not Global.hub_story_shown:
		Global.hub_story_shown = true
		StoryManager.trigger_story_event("hub_memory")
