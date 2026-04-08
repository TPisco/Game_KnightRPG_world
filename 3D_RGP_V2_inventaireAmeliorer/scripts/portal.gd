#portal
extends Node3D

var destinations : Dictionary = {
	house_1_door_1 = {
		scene = "res://scenes/world.tscn",
		nameNode = "door1",
		rotationNode = 0
	},
	house_2_door_1 = {
		scene = "res://scenes/world_2.tscn",
		nameNode = "door1",
		rotationNode = 0
	}
}


@export var destination : String

func change_world(_destination:String) -> void:
	var scene_destination = load(destinations[_destination].scene)
	Global.node_position = destinations[_destination].nameNode
	Global.rotation = destinations[_destination].rotationNode
	get_tree().change_scene_to_packed(scene_destination)

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.has_method("player"):
		change_world(destination)
