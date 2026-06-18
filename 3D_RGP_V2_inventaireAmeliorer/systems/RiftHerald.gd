## Boss #2 — summons minions from the rift in later phases.
extends "res://systems/BossController.gd"

const MINION_SCENE := preload("res://scenes/objects/chunk_enemy.tscn")

var _minion_timer: float = 4.0


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if hp <= 0:
		return
	_minion_timer -= delta
	if current_phase >= 2 and _minion_timer <= 0.0:
		_spawn_minion()
		_minion_timer = 6.0 - current_phase


func _spawn_minion() -> void:
	var minion := MINION_SCENE.instantiate()
	get_parent().add_child(minion)
	var offset := Vector3(randf_range(-6, 6), 0, randf_range(-6, 6))
	minion.global_position = global_position + offset
	minion.global_position.y = global_position.y
	if "hp" in minion:
		minion.hp = 12 + current_phase * 4
