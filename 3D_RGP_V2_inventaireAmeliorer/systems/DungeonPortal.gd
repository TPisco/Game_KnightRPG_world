## Surface portal into a RANDOM mini-boss dungeon (loot content, no seals).
## Clearly labeled so the player knows exactly what they are entering.
class_name DungeonPortal
extends Node3D

const RANDOM_DUNGEON_SCENE_NAME := "SharedRandomDungeon"
const REENTRY_COOLDOWN_MS := 1500

var _return_position: Vector3 = Vector3.ZERO
var _difficulty: float = 1.0
var _cooldown_until_ms: int = 0


func configure(return_global_pos: Vector3, difficulty: float) -> void:
	_return_position = return_global_pos
	_difficulty = difficulty


func _ready() -> void:
	_build_visuals()
	var area := Area3D.new()
	add_child(area)
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.height = 3.5
	shape.radius = 1.4
	col.shape = shape
	col.position = Vector3(0, 1.7, 0)
	area.add_child(col)
	area.body_entered.connect(_on_body_entered)


func _build_visuals() -> void:
	var torus := TorusMesh.new()
	torus.inner_radius = 0.55
	torus.outer_radius = 1.35
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.55, 0.95, 0.85)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.15, 0.5, 1.0)
	mat.emission_energy_multiplier = 2.2
	var ring := MeshInstance3D.new()
	ring.mesh = torus
	ring.material_override = mat
	ring.rotation_degrees = Vector3(90, 0, 0)
	ring.position = Vector3(0, 1.7, 0)
	add_child(ring)

	var label := Label3D.new()
	label.text = "MINI-BOSS LOOT DUNGEON\nRandom layout — good loot"
	label.font_size = 44
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(0.5, 0.8, 1)
	label.outline_size = 10
	label.position = Vector3(0, 4.2, 0)
	add_child(label)

	var light := OmniLight3D.new()
	light.light_color = Color(0.3, 0.6, 1)
	light.light_energy = 1.8
	light.omni_range = 9.0
	light.position = Vector3(0, 1.7, 0)
	add_child(light)

	var tween := create_tween().set_loops()
	tween.tween_property(ring, "scale", Vector3(1.12, 1.12, 1.12), 0.8)
	tween.tween_property(ring, "scale", Vector3.ONE, 0.8)


func _on_body_entered(body: Node3D) -> void:
	if not body.has_method("player"):
		return
	if Time.get_ticks_msec() < _cooldown_until_ms:
		return
	_cooldown_until_ms = Time.get_ticks_msec() + REENTRY_COOLDOWN_MS
	var dungeon := _get_shared_dungeon()
	if dungeon and dungeon.has_method("enter"):
		dungeon.enter(body, _return_position, _difficulty)


func _get_shared_dungeon() -> Node:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return null
	var dungeon := scene_root.get_node_or_null(RANDOM_DUNGEON_SCENE_NAME)
	if dungeon == null:
		dungeon = RandomDungeon.new()
		dungeon.name = RANDOM_DUNGEON_SCENE_NAME
		scene_root.add_child(dungeon)
	return dungeon
