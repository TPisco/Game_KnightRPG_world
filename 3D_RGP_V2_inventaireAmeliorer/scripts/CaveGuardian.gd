## Large red cave boss — uses EnemyDeathSystem and opens a portal on death.
class_name CaveGuardian
extends "res://scripts/chunk_enemy.gd"

const PORTAL_SCENE := preload("res://scenes/world/cave_portal.tscn")

var _portal_spawn_local: Vector3 = Vector3.ZERO
var _owner_chunk: Node3D = null


func _ready() -> void:
	hp = 400
	damage = 40
	value = 50
	speed = 3.5
	attack_interval = 2.0
	super._ready()
	add_to_group("cave_guardians")
	_make_guardian_big_and_red()


func configure(portal_local: Vector3, owner_chunk: Node3D) -> void:
	_portal_spawn_local = portal_local
	_owner_chunk = owner_chunk


func _setup_death_system() -> void:
	_death_system = get_node_or_null("EnemyDeathSystem") as EnemyDeathSystem
	if _death_system == null:
		_death_system = EnemyDeathSystem.new()
		_death_system.name = "EnemyDeathSystem"
		add_child(_death_system)
	_death_system.setup(self, animation_player)
	_death_system.death_rewards_callback = _spawn_portal_behind


func _make_guardian_big_and_red() -> void:
	scale = Vector3(2.5, 2.5, 2.5)
	var model := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if model == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.92, 0.1, 0.08)
	mat.roughness = 0.65
	mat.emission_enabled = true
	mat.emission = Color(0.55, 0.05, 0.05)
	mat.emission_energy_multiplier = 0.8
	model.material_override = mat


func _spawn_portal_behind() -> void:
	if _portal_spawn_local == Vector3.ZERO and _owner_chunk == null:
		return

	var parent: Node = _owner_chunk if _owner_chunk else get_parent()
	if parent == null:
		return

	var portal := PORTAL_SCENE.instantiate()
	parent.add_child(portal)
	portal.position = _portal_spawn_local

	var world_gen := get_tree().current_scene.get_node_or_null("WorldGenerator")
	if portal.has_method("configure"):
		portal.configure(world_gen, _owner_chunk)
	if portal.has_method("enable_portal"):
		portal.call_deferred("enable_portal")

	print("Cave Guardian defeated! Portal opened inside the cave.")
