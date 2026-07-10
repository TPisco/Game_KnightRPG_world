#global
extends Node

var node_position: String = ""
var rotation: float = -90.0
var current_realm: String = "fractured_wastes"
var continue_run: bool = false
var hub_test_mode: bool = false
var hub_test_applied: bool = false
var hub_story_shown: bool = false

## Last position on the surface world — "Restart Here" respawns the player
## there so dungeon deaths return to the same realm they came from.
var last_surface_position: Vector3 = Vector3.INF

var player_node = null


func set_player_reference(player) -> void:
	player_node = player


## Start New Run: brand-new save slot with completely fresh progression.
func start_new_run() -> void:
	continue_run = false
	hub_test_mode = false
	hub_test_applied = false
	last_surface_position = Vector3.INF
	SaveManager.create_new_save()


func save_progression() -> void:
	ProgressionTracker.save_game()


func load_progression() -> bool:
	return ProgressionTracker.load_game()
