## Builds a single 32x32 terrain tile with props, loot, and enemy spawn points.
class_name WorldChunk
extends Node3D

const CHUNK_SIZE := 32
const VERTEX_STEP := 2
const SKIRT_DEPTH := 10.0

static var _cached_prop_scenes: Array[PackedScene] = []
static var _props_loaded: bool = false

var chunk_coord: Vector2i = Vector2i.ZERO

var _prop_scenes: Array[PackedScene] = []
var _enemy_scene: PackedScene = preload("res://scenes/objects/chunk_enemy.tscn")
var _loot_scene: PackedScene = preload("res://scenes/Items/WorldLootPickup.tscn")
var _noise: FastNoiseLite


func setup(coord: Vector2i, world_seed: int, depth: int, difficulty_multiplier: float = 1.0) -> void:
	chunk_coord = coord
	position = Vector3(coord.x * CHUNK_SIZE, 0.0, coord.y * CHUNK_SIZE)
	_noise = FastNoiseLite.new()
	_noise.seed = world_seed + coord.x * 928371 + coord.y * 689287
	_noise.frequency = 0.04
	_noise.fractal_octaves = 3
	_load_prop_scenes()
	_build_terrain()
	_scatter_props(depth)
	call_deferred("_spawn_enemies", depth, difficulty_multiplier)
	call_deferred("_spawn_loot", depth)


func _spawn_loot(depth: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _noise.seed + 201

	# Starter gear at world origin so the player can arm up immediately.
	if chunk_coord == Vector2i.ZERO:
		var starter_positions := [
			Vector2(12, 14), Vector2(18, 12), Vector2(15, 18),
		]
		var starter_items := LootTable.starter_loadout()
		for i in starter_items.size():
			_place_loot(starter_items[i], starter_positions[i])
		return

	var loot_count := clampi(1 + depth / 2, 1, 4)
	for i in loot_count:
		if rng.randf() > 0.82:
			continue
		var item := LootTable.roll_loot(depth, rng)
		var local_x := rng.randf_range(4.0, CHUNK_SIZE - 4.0)
		var local_z := rng.randf_range(4.0, CHUNK_SIZE - 4.0)
		_place_loot(item, Vector2(local_x, local_z))


func _place_loot(item: ItemData, local_xz: Vector2) -> void:
	var pickup := _loot_scene.instantiate()
	if pickup.has_method("set_loot"):
		pickup.set_loot(item)
	elif "loot_data" in pickup:
		pickup.loot_data = item
	add_child(pickup)
	var world_x := chunk_coord.x * CHUNK_SIZE + local_xz.x
	var world_z := chunk_coord.y * CHUNK_SIZE + local_xz.y
	var h := _sample_height(world_x, world_z)
	pickup.position = Vector3(local_xz.x, h + 0.35, local_xz.y)


func _sample_height(world_x: float, world_z: float) -> float:
	return _noise.get_noise_2d(world_x, world_z) * 3.0


func _load_prop_scenes() -> void:
	if _props_loaded:
		_prop_scenes = _cached_prop_scenes
		return
	var paths := [
		"res://assets/model/Other/pinetree.glb",
		"res://assets/model/Other/grass.glb",
		"res://assets/model/CliffProps/cliffProps1.glb",
		"res://assets/model/CliffProps/cliffProps2.glb",
	]
	for path in paths:
		if ResourceLoader.exists(path):
			var scene: PackedScene = load(path)
			if scene:
				_prop_scenes.append(scene)
	_cached_prop_scenes = _prop_scenes
	_props_loaded = true


func _build_terrain() -> void:
	var body := StaticBody3D.new()
	body.name = "TerrainBody"
	body.collision_layer = 1
	add_child(body)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "TerrainMesh"
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	body.add_child(mesh_instance)

	var resolution := (CHUNK_SIZE / VERTEX_STEP) + 1
	var heights: Array = []
	heights.resize(resolution * resolution)

	for z in range(resolution):
		for x in range(resolution):
			var world_x := chunk_coord.x * CHUNK_SIZE + x * VERTEX_STEP
			var world_z := chunk_coord.y * CHUNK_SIZE + z * VERTEX_STEP
			var h := _sample_height(world_x, world_z)
			heights[x + z * resolution] = h

	var top_mesh := _build_terrain_top_mesh(resolution, heights)
	mesh_instance.mesh = _build_terrain_visual_mesh(resolution, heights, top_mesh)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.38, 0.18, 1.0)
	mat.roughness = 1.0
	mat.metallic = 0.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	mat.cull_mode = BaseMaterial3D.CULL_BACK
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mesh_instance.material_override = mat

	# Trimesh from the walkable top surface — matches rendered terrain exactly.
	var collision := CollisionShape3D.new()
	collision.shape = _build_terrain_collision_mesh(resolution).create_trimesh_shape()
	body.add_child(collision)


func _build_terrain_top_mesh(resolution: int, heights: Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for z in range(resolution - 1):
		for x in range(resolution - 1):
			var i00 := x + z * resolution
			var i10 := (x + 1) + z * resolution
			var i01 := x + (z + 1) * resolution
			var i11 := (x + 1) + (z + 1) * resolution
			_add_terrain_tri(st, x, z, heights[i00])
			_add_terrain_tri(st, x + 1, z, heights[i10])
			_add_terrain_tri(st, x, z + 1, heights[i01])
			_add_terrain_tri(st, x + 1, z, heights[i10])
			_add_terrain_tri(st, x + 1, z + 1, heights[i11])
			_add_terrain_tri(st, x, z + 1, heights[i01])

	st.generate_normals()
	return st.commit()


func _build_terrain_visual_mesh(resolution: int, heights: Array, top_mesh: ArrayMesh) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.append_from(top_mesh, 0, Transform3D.IDENTITY)
	_add_terrain_skirt(st, resolution, heights)
	st.generate_normals()
	return st.commit()


func _build_terrain_collision_mesh(resolution: int) -> ArrayMesh:
	# One-cell overlap past chunk edges so adjacent chunk colliders meet without cracks.
	var col_res := resolution + 2
	var heights: Array = []
	heights.resize(col_res * col_res)

	for z in range(col_res):
		for x in range(col_res):
			var world_x := chunk_coord.x * CHUNK_SIZE + (x - 1) * VERTEX_STEP
			var world_z := chunk_coord.y * CHUNK_SIZE + (z - 1) * VERTEX_STEP
			heights[x + z * col_res] = _sample_height(world_x, world_z)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for z in range(col_res - 1):
		for x in range(col_res - 1):
			var i00 := x + z * col_res
			var i10 := (x + 1) + z * col_res
			var i01 := x + (z + 1) * col_res
			var i11 := (x + 1) + (z + 1) * col_res
			_add_terrain_tri(st, x - 1, z - 1, heights[i00])
			_add_terrain_tri(st, x, z - 1, heights[i10])
			_add_terrain_tri(st, x - 1, z, heights[i01])
			_add_terrain_tri(st, x, z - 1, heights[i10])
			_add_terrain_tri(st, x, z, heights[i11])
			_add_terrain_tri(st, x - 1, z, heights[i01])

	st.generate_normals()
	return st.commit()


func _add_terrain_tri(st: SurfaceTool, x: int, z: int, height: float) -> void:
	st.add_vertex(Vector3(x * VERTEX_STEP, height, z * VERTEX_STEP))


func _add_terrain_skirt(st: SurfaceTool, resolution: int, heights: Array) -> void:
	var bottom_y := -SKIRT_DEPTH
	var max_x := (resolution - 1) * VERTEX_STEP
	var max_z := (resolution - 1) * VERTEX_STEP

	# South edge (z = 0)
	for x in range(resolution - 1):
		var h0: float = heights[x]
		var h1: float = heights[x + 1]
		var x0 := x * VERTEX_STEP
		var x1 := (x + 1) * VERTEX_STEP
		_add_skirt_quad(st, Vector3(x0, h0, 0), Vector3(x1, h1, 0), Vector3(x1, bottom_y, 0), Vector3(x0, bottom_y, 0))

	# North edge (z = max)
	for x in range(resolution - 1):
		var h0: float = heights[x + (resolution - 1) * resolution]
		var h1: float = heights[(x + 1) + (resolution - 1) * resolution]
		var x0 := x * VERTEX_STEP
		var x1 := (x + 1) * VERTEX_STEP
		_add_skirt_quad(st, Vector3(x1, h1, max_z), Vector3(x0, h0, max_z), Vector3(x0, bottom_y, max_z), Vector3(x1, bottom_y, max_z))

	# West edge (x = 0)
	for z in range(resolution - 1):
		var h0: float = heights[z * resolution]
		var h1: float = heights[(z + 1) * resolution]
		var z0 := z * VERTEX_STEP
		var z1 := (z + 1) * VERTEX_STEP
		_add_skirt_quad(st, Vector3(0, h0, z1), Vector3(0, h1, z1), Vector3(0, bottom_y, z1), Vector3(0, bottom_y, z0))

	# East edge (x = max)
	for z in range(resolution - 1):
		var h0: float = heights[(resolution - 1) + z * resolution]
		var h1: float = heights[(resolution - 1) + (z + 1) * resolution]
		var z0 := z * VERTEX_STEP
		var z1 := (z + 1) * VERTEX_STEP
		_add_skirt_quad(st, Vector3(max_x, h1, z1), Vector3(max_x, h0, z0), Vector3(max_x, bottom_y, z0), Vector3(max_x, bottom_y, z1))


func _add_skirt_quad(st: SurfaceTool, v0: Vector3, v1: Vector3, v2: Vector3, v3: Vector3) -> void:
	st.add_vertex(v0)
	st.add_vertex(v1)
	st.add_vertex(v2)
	st.add_vertex(v0)
	st.add_vertex(v2)
	st.add_vertex(v3)


func _scatter_props(depth: int) -> void:
	if _prop_scenes.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = _noise.seed + 17
	var prop_count := clampi(2 + depth, 2, 6)
	var props_root := Node3D.new()
	props_root.name = "Props"
	add_child(props_root)

	for i in prop_count:
		var scene := _prop_scenes[rng.randi() % _prop_scenes.size()]
		var prop := scene.instantiate()
		props_root.add_child(prop)
		var local_x := rng.randf_range(2.0, CHUNK_SIZE - 2.0)
		var local_z := rng.randf_range(2.0, CHUNK_SIZE - 2.0)
		var h := _sample_height(chunk_coord.x * CHUNK_SIZE + local_x, chunk_coord.y * CHUNK_SIZE + local_z)
		prop.position = Vector3(local_x, h, local_z)
		prop.rotation.y = rng.randf() * TAU
		prop.scale = Vector3.ONE * rng.randf_range(0.6, 1.2)


func _spawn_enemies(depth: int, difficulty_multiplier: float = 1.0) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _noise.seed + 99
	var count := 0 if depth == 0 else clampi(1 + int(depth * difficulty_multiplier / 2.0), 1, 5)
	if count == 0:
		return
	var spawns := Node3D.new()
	spawns.name = "EnemySpawns"
	add_child(spawns)

	for i in count:
		var enemy := _enemy_scene.instantiate()
		spawns.add_child(enemy)
		var local_x := rng.randf_range(4.0, CHUNK_SIZE - 4.0)
		var local_z := rng.randf_range(4.0, CHUNK_SIZE - 4.0)
		var h := _sample_height(chunk_coord.x * CHUNK_SIZE + local_x, chunk_coord.y * CHUNK_SIZE + local_z)
		enemy.position = Vector3(local_x, h + 1.0, local_z)
		if "hp" in enemy:
			enemy.hp = int((15 + depth * 5) * difficulty_multiplier)
		if "damage" in enemy:
			enemy.damage = int((12 + depth * 2) * difficulty_multiplier)
		if "value" in enemy:
			enemy.value = int((10 + depth * 3) * difficulty_multiplier)
