## Floating damage numbers and shared combat VFX helpers.
extends Node
class_name CombatFeedback

const DAMAGE_NUMBER_SCENE := preload("res://scenes/ui/DamageNumber.tscn")


static func spawn_damage_number(world_pos: Vector3, amount: int, color: Color = Color.WHITE) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return
	var label := DAMAGE_NUMBER_SCENE.instantiate()
	tree.current_scene.add_child(label)
	if label.has_method("setup"):
		label.setup(world_pos, amount, color)
