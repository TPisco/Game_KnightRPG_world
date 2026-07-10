## Ancient door at the end of an underground cave. Touching it teleports the
## player into the shared mini-boss dungeon room.
class_name DungeonDoor
extends Node3D

const ARENA_SCENE := preload("res://scenes/world/miniboss_arena.tscn")
const REENTRY_COOLDOWN_MS := 1500

var _return_position: Vector3 = Vector3.ZERO
var _difficulty: float = 1.0
var _cooldown_until_ms: int = 0
var _label: Label3D = null


func configure(return_global_pos: Vector3, difficulty: float) -> void:
	_return_position = return_global_pos
	_difficulty = difficulty


func _ready() -> void:
	_build_visuals()
	var area := Area3D.new()
	area.name = "DoorArea"
	add_child(area)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.4, 3.0, 1.6)
	col.shape = shape
	col.position = Vector3(0, 1.5, 0)
	area.add_child(col)
	area.body_entered.connect(_on_body_entered)


func _build_visuals() -> void:
	var pack := "res://assets/model/FantasyPack/"
	if not ModelLibrary.place_prop(self, pack + "dungeon/dungeon_gate.glb", Vector3.ZERO):
		ModelLibrary.place_prop(self, pack + "dungeon/dungeon_door.glb", Vector3.ZERO)

	var glow_mesh := MeshInstance3D.new()
	var quad := BoxMesh.new()
	quad.size = Vector3(1.8, 2.6, 0.15)
	glow_mesh.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.45, 0.15, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.95, 0.4, 0.1)
	mat.emission_energy_multiplier = 1.8
	glow_mesh.material_override = mat
	glow_mesh.position = Vector3(0, 1.5, 0)
	add_child(glow_mesh)

	_label = Label3D.new()
	_label.font_size = 44
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.outline_size = 10
	_label.position = Vector3(0, 3.4, 0)
	add_child(_label)
	_update_label()

	# Keep the label truthful about what lies behind the door.
	var refresh := Timer.new()
	refresh.wait_time = 1.0
	refresh.autostart = true
	refresh.timeout.connect(_update_label)
	add_child(refresh)

	var light := OmniLight3D.new()
	light.light_color = Color(1, 0.5, 0.2)
	light.light_energy = 1.2
	light.omni_range = 7.0
	light.position = Vector3(0, 2.0, 0.8)
	add_child(light)


func _update_label() -> void:
	if _label == null:
		return
	if ProgressionTracker.minibosses_cleared >= 2:
		_label.text = "REAL BOSS GATE WITHIN"
		_label.modulate = Color(1, 0.35, 0.25)
	else:
		_label.text = "MINI-BOSS DUNGEON\nSeal %d/2" % ProgressionTracker.minibosses_cleared
		_label.modulate = Color(1, 0.75, 0.4)


func _on_body_entered(body: Node3D) -> void:
	if not body.has_method("player"):
		return
	if Time.get_ticks_msec() < _cooldown_until_ms:
		return
	_cooldown_until_ms = Time.get_ticks_msec() + REENTRY_COOLDOWN_MS
	var arena := _get_shared_arena()
	if arena and arena.has_method("enter"):
		arena.enter(body, _return_position, _difficulty)


func _get_shared_arena() -> Node:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return null
	var arena := scene_root.get_node_or_null("SharedMiniBossArena")
	if arena == null:
		arena = ARENA_SCENE.instantiate()
		arena.name = "SharedMiniBossArena"
		scene_root.add_child(arena)
	return arena
