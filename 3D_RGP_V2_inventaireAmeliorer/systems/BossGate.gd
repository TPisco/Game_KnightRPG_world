## Crimson gate to the realm's real boss. Appears once both mini-boss rooms
## are cleared; touching it teleports the player into the boss arena.
class_name BossGate
extends Node3D

const BOSS_ARENA_SCENE := preload("res://scenes/world/boss_arena.tscn")
const REENTRY_COOLDOWN_MS := 1500

var _return_position: Vector3 = Vector3.ZERO
var _cooldown_until_ms: int = 0


func configure(return_global_pos: Vector3) -> void:
	_return_position = return_global_pos


func _ready() -> void:
	_build_visuals()
	var area := Area3D.new()
	add_child(area)
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.height = 3.5
	shape.radius = 1.5
	col.shape = shape
	col.position = Vector3(0, 1.7, 0)
	area.add_child(col)
	area.body_entered.connect(_on_body_entered)


func _build_visuals() -> void:
	var torus := TorusMesh.new()
	torus.inner_radius = 0.6
	torus.outer_radius = 1.5
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.15, 0.1, 0.85)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(1, 0.2, 0.05)
	mat.emission_energy_multiplier = 2.5
	var ring := MeshInstance3D.new()
	ring.mesh = torus
	ring.material_override = mat
	ring.rotation_degrees = Vector3(90, 0, 0)
	ring.position = Vector3(0, 1.7, 0)
	add_child(ring)

	var label := Label3D.new()
	label.text = "REAL BOSS DUNGEON\n%s awaits" % BossRegistry.get_boss_name_for_realm(ProgressionTracker.cave_portals_cleared)
	label.font_size = 40
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(1, 0.4, 0.3)
	label.outline_size = 10
	label.position = Vector3(0, 3.6, 0)
	add_child(label)

	var light := OmniLight3D.new()
	light.light_color = Color(1, 0.25, 0.1)
	light.light_energy = 2.2
	light.omni_range = 9.0
	light.position = Vector3(0, 1.7, 0)
	add_child(light)

	var tween := create_tween().set_loops()
	tween.tween_property(ring, "scale", Vector3(1.15, 1.15, 1.15), 0.7)
	tween.tween_property(ring, "scale", Vector3.ONE, 0.7)


func _on_body_entered(body: Node3D) -> void:
	if not body.has_method("player"):
		return
	if Time.get_ticks_msec() < _cooldown_until_ms:
		return
	_cooldown_until_ms = Time.get_ticks_msec() + REENTRY_COOLDOWN_MS
	var arena := _get_shared_boss_arena()
	if arena and arena.has_method("enter"):
		arena.enter(body, _return_position)


func _get_shared_boss_arena() -> Node:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return null
	var arena := scene_root.get_node_or_null("SharedBossArena")
	if arena == null:
		arena = BOSS_ARENA_SCENE.instantiate()
		arena.name = "SharedBossArena"
		scene_root.add_child(arena)
	return arena
