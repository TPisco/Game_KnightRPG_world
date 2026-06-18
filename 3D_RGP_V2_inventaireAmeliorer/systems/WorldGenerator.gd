## Procedural infinite world: spawns/despawns chunks around the player.
class_name WorldGenerator
extends Node3D

const CHUNK_SCENE := preload("res://scenes/world/WorldChunk.tscn")
const PLAYER_SCENE := preload("res://scenes/objects/player.tscn")

const CHUNK_SIZE := 32
const LOAD_RANGE := 3
const UNLOAD_RANGE := 5
const BOSS_MILESTONES := [5, 12, 20]

signal chunk_spawned(chunk_node: Node)
signal chunk_unloaded(chunk_node: Node)

var world_seed: int = 0
var difficulty_multiplier: float = 1.0
var active_chunks: Dictionary = {}

var _player: CharacterBody3D
var _last_player_chunk: Vector2i = Vector2i.ZERO
var _last_realm_id: String = ""
var _bosses_spawned: Array[int] = []
var _chunks_loading: bool = false


func _ready() -> void:
	if Global.continue_run:
		ProgressionTracker.load_game()
		world_seed = ProgressionTracker.run_seed
		Global.continue_run = false
	elif ProgressionTracker.run_seed == 0:
		ProgressionTracker.start_new_run()
		world_seed = ProgressionTracker.run_seed
	else:
		world_seed = ProgressionTracker.run_seed

	_spawn_player()
	_bind_skill_ui()
	_last_player_chunk = _world_to_chunk(_player.global_position)
	call_deferred("_refresh_chunks_async")


func _bind_skill_ui() -> void:
	var skill_ui = get_tree().current_scene.get_node_or_null("SkillSelectionUI")
	if skill_ui and is_instance_valid(_player) and skill_ui.has_method("bind_player"):
		skill_ui.bind_player(_player)


func _process(_delta: float) -> void:
	if not is_instance_valid(_player):
		return
	var chunk := _world_to_chunk(_player.global_position)
	if chunk != _last_player_chunk:
		_last_player_chunk = chunk
		call_deferred("_refresh_chunks_async")
	var depth := maxi(absi(chunk.x), absi(chunk.y))
	difficulty_multiplier = 1.0 + depth * 0.12
	ProgressionTracker.update_run_depth(depth)
	_check_realm_change(depth)
	_check_boss_spawn(depth)


func get_player_position() -> Vector3:
	if is_instance_valid(_player):
		return _player.global_position
	return Vector3.ZERO


func _spawn_player() -> void:
	var spawn := get_node_or_null("PlayerSpawn")
	var spawn_pos: Vector3 = Vector3(16, 6, 16)
	if spawn is Node3D:
		spawn_pos = (spawn as Node3D).global_position
	var spawn_chunk := _world_to_chunk(spawn_pos)
	var noise := FastNoiseLite.new()
	noise.seed = world_seed + spawn_chunk.x * 928371 + spawn_chunk.y * 689287
	noise.frequency = 0.04
	noise.fractal_octaves = 3
	var terrain_h := noise.get_noise_2d(spawn_pos.x, spawn_pos.z) * 3.0
	spawn_pos.y = terrain_h + 2.0
	_player = PLAYER_SCENE.instantiate()
	add_child(_player)
	_player.global_position = spawn_pos
	Global.set_player_reference(_player)
	Global.node_position = ""


func _world_to_chunk(world_pos: Vector3) -> Vector2i:
	return Vector2i(
		int(floor(world_pos.x / float(CHUNK_SIZE))),
		int(floor(world_pos.z / float(CHUNK_SIZE)))
	)


func _chunk_distance_to_player(coord: Vector2i) -> int:
	return maxi(absi(coord.x - _last_player_chunk.x), absi(coord.y - _last_player_chunk.y))


func _refresh_chunks_async() -> void:
	if _chunks_loading:
		return
	_chunks_loading = true
	var center := _last_player_chunk

	for key in active_chunks.keys():
		var chunk_node: Node = active_chunks[key]
		var coord := Vector2i.ZERO
		if chunk_node is WorldChunk:
			coord = chunk_node.chunk_coord
		else:
			coord = _key_to_coord(key)
		if _chunk_distance_to_player(coord) > UNLOAD_RANGE:
			chunk_unloaded.emit(chunk_node)
			chunk_node.queue_free()
			active_chunks.erase(key)

	var to_spawn: Array[Vector2i] = []
	for x in range(center.x - LOAD_RANGE, center.x + LOAD_RANGE + 1):
		for z in range(center.y - LOAD_RANGE, center.y + LOAD_RANGE + 1):
			var coord := Vector2i(x, z)
			var key := _chunk_key(coord)
			if key not in active_chunks:
				to_spawn.append(coord)

	for coord in to_spawn:
		_spawn_chunk(coord)
		await get_tree().process_frame

	_rebuild_world_barrier()
	_chunks_loading = false


func _key_to_coord(key: String) -> Vector2i:
	var parts: PackedStringArray = key.split("_")
	if parts.size() == 2:
		return Vector2i(int(parts[0]), int(parts[1]))
	return Vector2i.ZERO


func _rebuild_world_barrier() -> void:
	var old_barrier := get_node_or_null("WorldBarrier")
	if old_barrier:
		old_barrier.queue_free()

	if active_chunks.is_empty():
		return

	var min_cx := 2147483647
	var max_cx := -2147483648
	var min_cz := 2147483647
	var max_cz := -2147483648

	for key in active_chunks.keys():
		var parts: PackedStringArray = key.split("_")
		if parts.size() != 2:
			continue
		var cx := int(parts[0])
		var cz := int(parts[1])
		min_cx = mini(min_cx, cx)
		max_cx = maxi(max_cx, cx)
		min_cz = mini(min_cz, cz)
		max_cz = maxi(max_cz, cz)

	var barrier := StaticBody3D.new()
	barrier.name = "WorldBarrier"
	barrier.collision_layer = 1
	add_child(barrier)

	var x0 := float(min_cx * CHUNK_SIZE)
	var x1 := float((max_cx + 1) * CHUNK_SIZE)
	var z0 := float(min_cz * CHUNK_SIZE)
	var z1 := float((max_cz + 1) * CHUNK_SIZE)
	var span_x := x1 - x0
	var span_z := z1 - z0
	var wall_h := 18.0
	var wall_thick := 2.0
	var mid_y := 6.0

	var cliff_mat := StandardMaterial3D.new()
	cliff_mat.albedo_color = Color(0.32, 0.24, 0.18)

	_add_barrier_wall(barrier, Vector3(x0 - wall_thick * 0.5, mid_y, (z0 + z1) * 0.5), Vector3(wall_thick, wall_h, span_z + wall_thick * 2.0), cliff_mat)
	_add_barrier_wall(barrier, Vector3(x1 + wall_thick * 0.5, mid_y, (z0 + z1) * 0.5), Vector3(wall_thick, wall_h, span_z + wall_thick * 2.0), cliff_mat)
	_add_barrier_wall(barrier, Vector3((x0 + x1) * 0.5, mid_y, z0 - wall_thick * 0.5), Vector3(span_x + wall_thick * 2.0, wall_h, wall_thick), cliff_mat)
	_add_barrier_wall(barrier, Vector3((x0 + x1) * 0.5, mid_y, z1 + wall_thick * 0.5), Vector3(span_x + wall_thick * 2.0, wall_h, wall_thick), cliff_mat)

	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(span_x + 8.0, 1.0, span_z + 8.0)
	var floor_col := CollisionShape3D.new()
	floor_col.shape = floor_shape
	floor_col.position = Vector3((x0 + x1) * 0.5, -12.0, (z0 + z1) * 0.5)
	barrier.add_child(floor_col)


func _add_barrier_wall(parent: StaticBody3D, pos: Vector3, size: Vector3, material: StandardMaterial3D) -> void:
	var shape := BoxShape3D.new()
	shape.size = size
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position = pos
	parent.add_child(col)

	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_inst.mesh = box
	mesh_inst.position = pos
	mesh_inst.material_override = material
	parent.add_child(mesh_inst)


func _spawn_chunk(coord: Vector2i) -> void:
	var chunk := CHUNK_SCENE.instantiate()
	add_child(chunk)
	var depth := maxi(absi(coord.x), absi(coord.y))
	if chunk.has_method("setup"):
		chunk.setup(coord, world_seed, depth, difficulty_multiplier)
	active_chunks[_chunk_key(coord)] = chunk
	chunk_spawned.emit(chunk)


func _chunk_key(coord: Vector2i) -> String:
	return "%d_%d" % [coord.x, coord.y]


func _check_realm_change(depth: int) -> void:
	var realm: Dictionary = BossRegistry.get_realm_for_depth(depth)
	var realm_id: String = realm.get("id", "fractured_wastes")
	if realm_id != _last_realm_id and _last_realm_id != "":
		StoryManager.trigger_world_change(depth)
	_last_realm_id = realm_id


func _check_boss_spawn(depth: int) -> void:
	for milestone in BOSS_MILESTONES:
		if depth >= milestone and milestone not in _bosses_spawned:
			_bosses_spawned.append(milestone)
			_spawn_boss(milestone)


func _spawn_boss(milestone: int) -> void:
	if not is_instance_valid(_player):
		return
	var story_hud = get_tree().current_scene.get_node_or_null("RunStoryHUD")
	if story_hud and story_hud.has_method("show_boss_warning"):
		story_hud.show_boss_warning(milestone)
	StoryManager.trigger_boss_warning()

	var boss_scene: PackedScene = BossRegistry.get_boss_scene(milestone)
	var boss := boss_scene.instantiate()
	add_child(boss)
	var offset := Vector3(randf_range(-10, 10), 0, randf_range(16, 24))
	boss.global_position = _player.global_position + offset
	var chunk := _world_to_chunk(boss.global_position)
	var noise := FastNoiseLite.new()
	noise.seed = world_seed + chunk.x * 928371 + chunk.y * 689287
	noise.frequency = 0.04
	noise.fractal_octaves = 3
	var h := noise.get_noise_2d(boss.global_position.x, boss.global_position.z) * 3.0
	boss.global_position.y = h + 3.5

	var boss_ui = get_tree().current_scene.get_node_or_null("BossUI")
	if boss_ui and boss_ui.has_method("register_boss"):
		boss_ui.register_boss(boss)
