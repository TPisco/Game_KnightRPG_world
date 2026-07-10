## Procedural infinite world: spawns/despawns chunks around the player.
class_name WorldGenerator
extends Node3D

const CHUNK_SCENE := preload("res://scenes/world/WorldChunk.tscn")
const PLAYER_SCENE := preload("res://scenes/objects/player.tscn")

const CHUNK_SIZE := 32
const LOAD_RANGE := 4
const UNLOAD_RANGE := 6
## Enemies only simulate within this many chunks of the player (5x5 area).
const MOB_ACTIVE_RANGE := 2

signal chunk_spawned(chunk_node: Node)
signal chunk_unloaded(chunk_node: Node)
signal cave_portal_entered(portals_cleared: int)

var world_seed: int = 0
var difficulty_multiplier: float = 1.0
var active_chunks: Dictionary = {}

var _player: CharacterBody3D
var _last_player_chunk: Vector2i = Vector2i.ZERO
var _last_realm_id: String = ""
var _chunks_loading: bool = false


func _ready() -> void:
	if Global.continue_run:
		# Save data was already applied by SaveManager.load_slot().
		world_seed = ProgressionTracker.run_seed + ProgressionTracker.cave_portals_cleared * 10007
		Global.continue_run = false
	elif ProgressionTracker.run_seed == 0:
		ProgressionTracker.start_new_run()
		world_seed = ProgressionTracker.run_seed
	else:
		world_seed = ProgressionTracker.run_seed + ProgressionTracker.cave_portals_cleared * 10007

	_spawn_player()
	_bind_skill_ui()
	_last_player_chunk = _world_to_chunk(_player.global_position)
	call_deferred("_refresh_chunks_async")
	# Boss already unlocked (e.g. after Restart Here): offer the gate again.
	if ProgressionTracker.minibosses_cleared >= 2:
		call_deferred("_spawn_boss_gate_near_player")


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
		_update_mob_activation()
		call_deferred("_refresh_chunks_async")
	var depth := maxi(absi(chunk.x), absi(chunk.y))
	difficulty_multiplier = 1.0 + depth * 0.12
	ProgressionTracker.update_run_depth(depth)
	_check_realm_change(depth)
	# Remember the last spot on the open surface for "Restart Here"
	# (underground caves and dungeon rooms don't count).
	var p := _player.global_position
	if p.y > WorldChunk.get_terrain_height(world_seed, p.x, p.z) - 3.0:
		Global.last_surface_position = p


func get_player_position() -> Vector3:
	if is_instance_valid(_player):
		return _player.global_position
	return Vector3.ZERO


func _spawn_player() -> void:
	var spawn := get_node_or_null("PlayerSpawn")
	var spawn_pos: Vector3 = Vector3(16, 6, 16)
	if spawn is Node3D:
		spawn_pos = (spawn as Node3D).global_position
	var terrain_h := WorldChunk.get_terrain_height(world_seed, spawn_pos.x, spawn_pos.z)
	spawn_pos.y = terrain_h + 2.0

	# Continue Game: put the knight back where that run was left.
	var saved_pos := SaveManager.take_pending_player_pos()
	if saved_pos != SaveManager.NO_POSITION:
		spawn_pos = saved_pos
		var ground := WorldChunk.get_terrain_height(world_seed, spawn_pos.x, spawn_pos.z)
		# Saved inside the shop interior (or below ground): resurface safely.
		if spawn_pos.y < ground - 1.0:
			spawn_pos.y = ground + 2.0
		else:
			spawn_pos.y = maxf(spawn_pos.y + 0.3, ground + 1.2)

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

	# Closest chunks first so the ground under the player has collision
	# before gravity can drop them through unloaded terrain.
	to_spawn.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return _chunk_distance_to_player(a) < _chunk_distance_to_player(b)
	)

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
	var wall_h := 44.0
	var wall_thick := 2.0
	var mid_y := 8.0

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
	floor_col.position = Vector3((x0 + x1) * 0.5, -26.0, (z0 + z1) * 0.5)
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
	if chunk.has_method("set_mobs_active"):
		chunk.set_mobs_active(_chunk_distance_to_player(coord) <= MOB_ACTIVE_RANGE)
	chunk_spawned.emit(chunk)


## Enable mobs in nearby chunks, freeze them everywhere else.
func _update_mob_activation() -> void:
	for key in active_chunks.keys():
		var chunk_node: Node = active_chunks[key]
		if not is_instance_valid(chunk_node):
			continue
		if chunk_node is WorldChunk and chunk_node.has_method("set_mobs_active"):
			var dist := _chunk_distance_to_player((chunk_node as WorldChunk).chunk_coord)
			chunk_node.set_mobs_active(dist <= MOB_ACTIVE_RANGE)


func _chunk_key(coord: Vector2i) -> String:
	return "%d_%d" % [coord.x, coord.y]


func _check_realm_change(depth: int) -> void:
	var realm: Dictionary = BossRegistry.get_realm_for_depth(depth)
	var realm_id: String = realm.get("id", "fractured_wastes")
	if realm_id != _last_realm_id and _last_realm_id != "":
		StoryManager.trigger_world_change(depth)
	_last_realm_id = realm_id


## After Restart Here (or reload) with both seals broken, place a Boss Gate on
## the surface near the player so the unlocked boss stays reachable.
func _spawn_boss_gate_near_player() -> void:
	if not is_instance_valid(_player):
		return
	var gate := BossGate.new()
	add_child(gate)
	var pos := _player.global_position + Vector3(6, 0, 6)
	pos.y = WorldChunk.get_terrain_height(world_seed, pos.x, pos.z)
	gate.global_position = pos
	gate.configure(pos + Vector3(3, 1.2, 3))


func enter_cave_portal(_portal: Node) -> void:
	if not is_instance_valid(_player):
		return

	ProgressionTracker.cave_portals_cleared += 1
	ProgressionTracker.minibosses_cleared = 0  # new realm, new dungeon seals
	ProgressionTracker.update_run_depth(ProgressionTracker.run_depth + 3)
	ProgressionTracker.save_game()

	var advance := float((LOAD_RANGE + 2) * CHUNK_SIZE)
	_player.global_position += Vector3(0.0, 0.0, advance)
	world_seed = ProgressionTracker.run_seed + ProgressionTracker.cave_portals_cleared * 10007
	_place_player_on_terrain()

	for key in active_chunks.keys():
		var chunk_node: Node = active_chunks[key]
		chunk_unloaded.emit(chunk_node)
		chunk_node.queue_free()
	active_chunks.clear()

	_last_player_chunk = _world_to_chunk(_player.global_position)
	call_deferred("_refresh_chunks_async")
	cave_portal_entered.emit(ProgressionTracker.cave_portals_cleared)
	StoryManager.trigger_cave_portal()
	print("Entered cave portal — advanced to realm %d" % ProgressionTracker.cave_portals_cleared)


func _place_player_on_terrain() -> void:
	if not is_instance_valid(_player):
		return
	var h := WorldChunk.get_terrain_height(world_seed, _player.global_position.x, _player.global_position.z)
	_player.global_position.y = h + 2.0
