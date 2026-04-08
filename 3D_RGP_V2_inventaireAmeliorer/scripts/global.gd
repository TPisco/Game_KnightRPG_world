#global
extends Node

var node_position : String = ""
var rotation : int = -90

# inventory
var player_node = null

func _ready() -> void:
	pass

func set_player_reference(player):
	player_node = player
