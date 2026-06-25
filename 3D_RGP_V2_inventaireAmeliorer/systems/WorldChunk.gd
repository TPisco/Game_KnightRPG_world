## Builds a single 32x32 terrain tile with props, loot, and enemy spawn points.
class_name WorldChunk
extends Node3D

const CHUNK_SIZE := 32
const VERTEX_STEP := 2
const SKIRT_DEPTH := 10.0

static var _cached_prop_scenes: Array[PackedScene] = []
static var _props_loaded: bool = false

var chunk_coord: Vector2i = Vector2i.ZERO
var chunk_type: String = "open"
var biome: String = "verdant"
var portal_spawn_local: Vector3 = Vector3.ZERO
var guardian_spawn_local: Vector3 = Vector3.ZERO

# Biome definitions: terrain tint + ambient fog/light feel, keyed by depth band.
const BIOMES := {
	"verdant":  {"color": Color(0.22, 0.38, 0.18), "max_depth": 3},
	"ashen":    {"color": Color(0.30, 0.27, 0.24), "max_depth": 7},
	"frostbit": {"color": Color(0.62, 0.72, 0.82), "max_depth": 12},
	"voidlands":{"color": Color(0.20, 0.12, 0.30), "max_depth": 9999},
}

const BIOME_DENSITY := {
	"verdant": 1.0,
	"ashen": 0.6,
	"frostbit": 0.4,
	"voidlands": 0.25,
}

var _prop_scenes: Array[PackedScene] = []
var _enemy_scene: PackedScene = preload("res://scenes/objects/chunk_enemy.tscn")
var _guardian_scene: PackedScene = preload("res://scenes/objects/cave_guardian.tscn")
var _loot_scene: PackedScene = preload("res://scenes/Items/WorldLootPickup.tscn")
var _guardian_spawned: bool = false
var _cave_root: Node3D = null
var _world_seed: int = 0
var _chunk_rng_seed: int = 0
var _noise: FastNoiseLite


func setup(coord: Vector2i, world_seed: int, depth: int, difficulty_multiplier: float = 1.0) -> void:
	chunk_coord = coord
	position = Vector3(coord.x * CHUNK_SIZE, 0.0, coord.y * CHUNK_SIZE)
	_world_seed = world_seed
	_chunk_rng_seed = world_seed + coord.x * 928371 + coord.y * 689287
	_noise = FastNoiseLite.new()
	# Shared seed keeps height continuous across chunk boundaries.
	_noise.seed = _world_seed
	_noise.frequency = 0.04
	_noise.fractal_octaves = 3
	_load_prop_scenes()
	_determine_biome(depth)
	_determine_chunk_type(depth)
	_build_terrain()
	if is_cave():
		_build_cave_interior()
	else:
		_scatter_props(depth)
	call_deferred("_spawn_cave_guardian", depth, difficulty_multiplier)
	call_deferred("_spawn_enemies", depth, difficulty_multiplier)
	call_deferred("_spawn_loot", depth)


func is_cave() -> bool:
	return chunk_type == "cave"


func _determine_biome(depth: int) -> void:
	# Depth sets the base biome; a noise band adds local variation between neighbours.
	var variation := _noise.get_noise_2d(chunk_coord.x * 13.7, chunk_coord.y * 13.7)
	var effective_depth := depth + int(round(variation * 2.0))
	effective_depth = maxi(0, effective_depth)
	for biome_id in ["verdant", "ashen", "frostbit", "voidlands"]:
		if effective_depth <= int(BIOMES[biome_id]["max_depth"]):
			biome = biome_id
			return
	biome = "voidlands"


func _biome_terrain_color() -> Color:
	var def: Dictionary = BIOMES.get(biome, BIOMES["verdant"])
	var base := def["color"] as Color
	# Slight per-chunk jitter so tiles aren't perfectly flat-colored.
	var jitter := _noise.get_noise_2d(chunk_coord.x * 7.3 + 100.0, chunk_coord.y * 7.3 - 100.0) * 0.04
	return Color(
		clampf(base.r + jitter, 0.0, 1.0),
		clampf(base.g + jitter, 0.0, 1.0),
		clampf(base.b + jitter, 0.0, 1.0)
	)


func get_guardian_spawn_position() -> Vector3:
	return guardian_spawn_local


func _determine_chunk_type(depth: int) -> void:
	chunk_type = "open"
	if chunk_coord == Vector2i.ZERO or depth < 2:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = _chunk_rng_seed + 501
	if rng.randf() < 0.16:
		chunk_type = "cave"


func _spawn_loot(depth: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _chunk_rng_seed + 201

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


func get_height_at_local(local_x: float, local_z: float) -> float:
	var world_x := chunk_coord.x * CHUNK_SIZE + local_x
	var world_z := chunk_coord.y * CHUNK_SIZE + local_z
	return _sample_height(world_x, world_z)


func _build_height_grid(grid_steps: int, x_offset: int, z_offset: int) -> Array:
	var grid_size := grid_steps + 1
	var heights: Array = []
	heights.resize(grid_size * grid_size)
	for z in range(grid_size):
		for x in range(grid_size):
			var world_x := chunk_coord.x * CHUNK_SIZE + (x + x_offset) * VERTEX_STEP
			var world_z := chunk_coord.y * CHUNK_SIZE + (z + z_offset) * VERTEX_STEP
			heights[x + z * grid_size] = _sample_height(world_x, world_z)
	return heights


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

	var base_resolution := (CHUNK_SIZE / VERTEX_STEP) + 1
	# One extra ring on each side so adjacent chunks share edge vertices.
	var x_offset := -1
	var z_offset := -1
	var grid_steps := base_resolution + 1
	var heights := _build_height_grid(grid_steps, x_offset, z_offset)
	var grid_size := grid_steps + 1

	var top_mesh := _build_terrain_top_mesh(grid_size, heights, x_offset, z_offset)
	mesh_instance.mesh = _build_terrain_visual_mesh(grid_size, heights, top_mesh, x_offset, z_offset)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = _biome_terrain_color()
	mat.roughness = 1.0
	mat.metallic = 0.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	mat.cull_mode = BaseMaterial3D.CULL_BACK
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mesh_instance.material_override = mat

	var collision := CollisionShape3D.new()
	collision.shape = top_mesh.create_trimesh_shape()
	body.add_child(collision)


func _build_terrain_top_mesh(grid_size: int, heights: Array, x_offset: int, z_offset: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for z in range(grid_size - 1):
		for x in range(grid_size - 1):
			var i00 := x + z * grid_size
			var i10 := (x + 1) + z * grid_size
			var i01 := x + (z + 1) * grid_size
			var i11 := (x + 1) + (z + 1) * grid_size
			_add_terrain_tri(st, x + x_offset, z + z_offset, heights[i00])
			_add_terrain_tri(st, x + 1 + x_offset, z + z_offset, heights[i10])
			_add_terrain_tri(st, x + x_offset, z + 1 + z_offset, heights[i01])
			_add_terrain_tri(st, x + 1 + x_offset, z + z_offset, heights[i10])
			_add_terrain_tri(st, x + 1 + x_offset, z + 1 + z_offset, heights[i11])
			_add_terrain_tri(st, x + x_offset, z + 1 + z_offset, heights[i01])

	st.generate_normals()
	return st.commit()


func _build_terrain_visual_mesh(grid_size: int, heights: Array, top_mesh: ArrayMesh, x_offset: int, z_offset: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.append_from(top_mesh, 0, Transform3D.IDENTITY)
	_add_terrain_skirt(st, grid_size, heights, x_offset, z_offset)
	st.generate_normals()
	return st.commit()


func _add_terrain_tri(st: SurfaceTool, x: int, z: int, height: float) -> void:
	st.add_vertex(Vector3(x * VERTEX_STEP, height, z * VERTEX_STEP))


func _add_terrain_skirt(st: SurfaceTool, grid_size: int, heights: Array, x_offset: int, z_offset: int) -> void:
	var bottom_y := -SKIRT_DEPTH
	var min_x := x_offset * VERTEX_STEP
	var min_z := z_offset * VERTEX_STEP
	var max_x := (x_offset + grid_size - 1) * VERTEX_STEP
	var max_z := (z_offset + grid_size - 1) * VERTEX_STEP

	# South edge (min_z)
	for x in range(grid_size - 1):
		var h0: float = heights[x + 0 * grid_size]
		var h1: float = heights[(x + 1) + 0 * grid_size]
		var x0 := (x + x_offset) * VERTEX_STEP
		var x1 := (x + 1 + x_offset) * VERTEX_STEP
		_add_skirt_quad(
			st,
			Vector3(x0, h0, min_z),
			Vector3(x1, h1, min_z),
			Vector3(x1, bottom_y, min_z),
			Vector3(x0, bottom_y, min_z)
		)

	# North edge (max_z)
	for x in range(grid_size - 1):
		var z_row := grid_size - 1
		var h0: float = heights[x + z_row * grid_size]
		var h1: float = heights[(x + 1) + z_row * grid_size]
		var x0 := (x + x_offset) * VERTEX_STEP
		var x1 := (x + 1 + x_offset) * VERTEX_STEP
		var z_edge := max_z
		_add_skirt_quad(
			st,
			Vector3(x1, h1, z_edge),
			Vector3(x0, h0, z_edge),
			Vector3(x0, bottom_y, z_edge),
			Vector3(x1, bottom_y, z_edge)
		)

	for z in range(grid_size - 1):
		var h0: float = heights[0 + z * grid_size]
		var h1: float = heights[0 + (z + 1) * grid_size]
		var z0 := (z + z_offset) * VERTEX_STEP
		var z1 := (z + 1 + z_offset) * VERTEX_STEP
		var x_edge := min_x
		_add_skirt_quad(
			st,
			Vector3(x_edge, h0, z1),
			Vector3(x_edge, h1, z0),
			Vector3(x_edge, bottom_y, z0),
			Vector3(x_edge, bottom_y, z1)
		)

	for z in range(grid_size - 1):
		var x_col := grid_size - 1
		var h0: float = heights[x_col + z * grid_size]
		var h1: float = heights[x_col + (z + 1) * grid_size]
		var z0 := (z + z_offset) * VERTEX_STEP
		var z1 := (z + 1 + z_offset) * VERTEX_STEP
		var x_edge := max_x
		_add_skirt_quad(
			st,
			Vector3(x_edge, h1, z1),
			Vector3(x_edge, h0, z0),
			Vector3(x_edge, bottom_y, z0),
			Vector3(x_edge, bottom_y, z1)
		)


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
	rng.seed = _chunk_rng_seed + 17
	# Vegetation thins out in harsher biomes.
	var density: float = float(BIOME_DENSITY.get(biome, 1.0))
	var prop_count := clampi(int((2 + depth) * density), 0, 6)
	if prop_count == 0:
		return
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
	if is_cave():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = _chunk_rng_seed + 99
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


func _spawn_cave_guardian(depth: int, difficulty_multiplier: float = 1.0) -> void:
	if not is_cave() or _guardian_spawned:
		return
	_guardian_spawned = true
	var guardian := _guardian_scene.instantiate()
	add_child(guardian)
	guardian.position = guardian_spawn_local
	if guardian.has_method("configure"):
		guardian.configure(portal_spawn_local, self)
	if "hp" in guardian:
		guardian.hp = int(400 * difficulty_multiplier)
	if "damage" in guardian:
		guardian.damage = int(40 * difficulty_multiplier)
	if "value" in guardian:
		guardian.value = int(50 * difficulty_multiplier)


func _build_cave_interior() -> void:
	_cave_root = Node3D.new()
	_cave_root.name = "CaveInterior"
	add_child(_cave_root)

	var rng := RandomNumberGenerator.new()
	rng.seed = _chunk_rng_seed + 777
	var center_x := rng.randf_range(10.0, CHUNK_SIZE - 10.0)
	var center_z := rng.randf_range(10.0, CHUNK_SIZE - 10.0)
	var world_x := chunk_coord.x * CHUNK_SIZE + center_x
	var world_z := chunk_coord.y * CHUNK_SIZE + center_z
	var surface_h := _sample_height(world_x, world_z)

	var to_origin := Vector2(-center_x, -center_z)
	var cave_forward := Vector3(to_origin.x, 0.0, to_origin.y)
	if cave_forward.length_squared() < 0.01:
		cave_forward = Vector3(0.0, 0.0, 1.0)
	else:
		cave_forward = cave_forward.normalized()

	var chamber_len := 14.0
	var chamber_w := 12.0
	var cave_h := 7.0
	var floor_y := surface_h - 2.0
	var chamber_center := Vector3(center_x, floor_y + cave_h * 0.5, center_z)
	var side := cave_forward.cross(Vector3.UP).normalized()

	portal_spawn_local = chamber_center + (-cave_forward * (chamber_len * 0.5 - 2.0))
	portal_spawn_local.y = floor_y + 1.5
	guardian_spawn_local = portal_spawn_local + cave_forward * 5.0

	var cave_mat := StandardMaterial3D.new()
	cave_mat.albedo_color = Color(0.28, 0.2, 0.16)
	cave_mat.roughness = 1.0

	_add_cave_box(Vector3(center_x, floor_y, center_z), Vector3(chamber_w, 1.0, chamber_len), cave_mat)
	_add_cave_box(Vector3(center_x, floor_y + cave_h, center_z), Vector3(chamber_w, 1.0, chamber_len), cave_mat)
	_add_cave_box(chamber_center + side * chamber_w * 0.5, Vector3(1.5, cave_h, chamber_len), cave_mat)
	_add_cave_box(chamber_center - side * chamber_w * 0.5, Vector3(1.5, cave_h, chamber_len), cave_mat)
	_add_cave_box(chamber_center - cave_forward * chamber_len * 0.5, Vector3(chamber_w, cave_h, 1.5), cave_mat)
	_add_cave_box(
		chamber_center + cave_forward * (chamber_len * 0.5 - 1.0),
		Vector3(chamber_w * 0.55, 0.6, 2.0),
		cave_mat
	)

	var light := OmniLight3D.new()
	light.light_color = Color(0.95, 0.45, 0.25)
	light.light_energy = 0.75
	light.omni_range = 18.0
	light.position = chamber_center
	_cave_root.add_child(light)

	var entrance_light := OmniLight3D.new()
	entrance_light.light_color = Color(0.7, 0.55, 0.4)
	entrance_light.light_energy = 0.35
	entrance_light.omni_range = 10.0
	entrance_light.position = chamber_center + cave_forward * (chamber_len * 0.45)
	_cave_root.add_child(entrance_light)


func _add_cave_box(center: Vector3, size: Vector3, material: StandardMaterial3D) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	_cave_root.add_child(body)
	body.position = center

	var shape := BoxShape3D.new()
	shape.size = size
	var col := CollisionShape3D.new()
	col.shape = shape
	body.add_child(col)

	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_inst.mesh = box
	mesh_inst.material_override = material
	body.add_child(mesh_inst)
