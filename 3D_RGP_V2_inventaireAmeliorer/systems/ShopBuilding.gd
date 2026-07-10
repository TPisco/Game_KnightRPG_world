## Shop exterior: touching the door teleports the player into the shared interior.
class_name ShopBuilding
extends Node3D

const INTERIOR_SCENE := preload("res://scenes/world/shop_interior.tscn")

@onready var door_area: Area3D = $DoorArea


func _ready() -> void:
	if door_area:
		door_area.body_entered.connect(_on_door_body_entered)


func _on_door_body_entered(body: Node3D) -> void:
	if not body.has_method("player"):
		return
	var interior := _get_shared_interior()
	if interior and interior.has_method("enter_shop"):
		interior.enter_shop(body, self)


## One interior per scene, created lazily and reused by every shop building.
func _get_shared_interior() -> Node:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return null
	var interior := scene_root.get_node_or_null("SharedShopInterior")
	if interior == null:
		interior = INTERIOR_SCENE.instantiate()
		interior.name = "SharedShopInterior"
		scene_root.add_child(interior)
	return interior
