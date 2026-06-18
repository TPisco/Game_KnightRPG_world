#global
extends Node

var node_position: String = ""
var rotation: float = -90.0
var current_realm: String = "fractured_wastes"
var continue_run: bool = false

var player_node = null


func set_player_reference(player) -> void:
	player_node = player


func start_new_run() -> void:
	continue_run = false
	ProgressionTracker.start_new_run()


func save_progression() -> void:
	ProgressionTracker.save_game()


func load_progression() -> bool:
	return ProgressionTracker.load_game()
