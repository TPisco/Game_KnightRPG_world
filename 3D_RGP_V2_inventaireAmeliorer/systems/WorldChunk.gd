## Builds a single 32x32 terrain tile with props, loot, and enemy spawn points.
class_name WorldChunk
extends Node3D

const CHUNK_SIZE := 32
const VERTEX_STEP := 2
const SKIRT_DEPTH := 22.0

static var _cached_prop_scenes: Array[PackedScene] = []
static var _props_loaded: bool = false

# Shared terrain height: fine detail + large rolling relief. Every system that
# needs ground height (chunks, player/boss placement) must use this function.
static var _shared_height_noise: FastNoiseLite
static var _shared_macro_noise: FastNoiseLite
static var _shared_noise_seed: int = -2147483648


static func get_terrain_height(world_seed: int, world_x: float, world_z: float) -> float:
	if _shared_noise_seed != world_seed or _shared_height_noise == null:
		_shared_height_noise = FastNoiseLite.new()
		_shared_height_noise.seed = world_seed
		_shared_height_noise.frequency = 0.04
		_shared_height_noise.fractal_octaves = 3
		_shared_macro_noise = FastNoiseLite.new()
		_shared_macro_noise.seed = world_seed + 1337
		_shared_macro_noise.frequency = 0.007
		_shared_macro_noise.fractal_octaves = 2
		_shared_noise_seed = world_seed
	return _shared_height_noise.get_noise_2d(world_x, world_z) * 3.0 \
		+ _shared_macro_noise.get_noise_2d(world_x, world_z) * 8.0

var chunk_coord: Vector2i = Vector2i.ZERO
var chunk_type: String = "open"
var biome: String = "verdant"
var portal_spawn_local: Vector3 = Vector3.ZERO
var guardian_spawn_local: Vector3 = Vector3.ZERO

# Underground cave layout (local space), filled by _plan_cave/_build_cave_interior.
const CAVE_DROP := 9.0         # total descent — gentle enough to walk back UP
const CAVE_CARVE_INNER := 3.0  # half-width of the flat path floor
const CAVE_CARVE_OUTER := 5.5  # where the carve blends back into terrain
# Waypoints must stay inside this local box: neighbouring chunks overlap 2 m
# into this chunk and drop UNCARVED skirt walls along the +/-30 lines — any
# carve reaching past them gets walled off. Waypoint box + max well radius
# (7) must therefore stay within [3..29].
const CAVE_SAFE_MIN := 10.0
const CAVE_SAFE_MAX := 22.0

var _cave_planned: bool = false
var _cave_entrance: Vector2 = Vector2.ZERO  # local XZ of the mouth
var _cave_dir: Vector2 = Vector2.ZERO       # initial descent direction
var _cave_h0: float = 0.0                   # surface height at the entrance
var _cave_pts: Array[Vector2] = []          # winding path waypoints (local XZ)
var _cave_depths: Array[float] = []         # absolute floor height per waypoint
var _cave_wells: Array = []                 # widened bowls/pockets along the path
var _cave_mob_spots: Array[Vector3] = []    # enemy areas (local)
var _cave_loot_spots: Array[Vector3] = []   # loot placements (local)
var _chamber_center: Vector3 = Vector3.ZERO  # at chamber floor level
var _chamber_forward: Vector3 = Vector3.FORWARD  # entrance -> door direction
var _chamber_size: Vector3 = Vector3(16, 7, 14)
var _entrance_return_local: Vector3 = Vector3.ZERO  # surface spot outside mouth

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

# FantasyPack mobs per biome + light stat flavor per species.
const MOB_DIR := "res://assets/model/FantasyPack/mobs/"
const BIOME_MOBS := {
	"verdant": ["mob_goblin", "mob_slime", "mob_mushroom"],
	"ashen": ["mob_goblin_brute", "mob_orc", "mob_goblin"],
	"frostbit": ["mob_skeleton", "mob_skeleton_armored"],
	"voidlands": ["mob_void_wisp", "mob_skeleton_armored"],
}
const MOB_STATS := {
	"mob_goblin": {"hp": 1.0, "dmg": 1.0, "speed": 2.2},
	"mob_goblin_brute": {"hp": 1.5, "dmg": 1.3, "speed": 1.8},
	"mob_mushroom": {"hp": 0.8, "dmg": 0.9, "speed": 1.4},
	"mob_orc": {"hp": 1.4, "dmg": 1.2, "speed": 2.0},
	"mob_skeleton": {"hp": 0.9, "dmg": 1.1, "speed": 2.4},
	"mob_skeleton_armored": {"hp": 1.6, "dmg": 1.2, "speed": 1.8},
	"mob_slime": {"hp": 1.2, "dmg": 0.8, "speed": 1.5},
	"mob_void_wisp": {"hp": 0.7, "dmg": 1.3, "speed": 3.0},
}

var _prop_scenes: Array[PackedScene] = []
var _enemy_scene: PackedScene = preload("res://scenes/objects/chunk_enemy.tscn")
var _loot_scene: PackedScene = preload("res://scenes/Items/WorldLootPickup.tscn")
var _shop_scene: PackedScene = preload("res://scenes/world/shop_building.tscn")
var _cave_root: Node3D = null
var _world_seed: int = 0
var _chunk_rng_seed: int = 0
var _noise: FastNoiseLite

# Mob streaming: enemies only exist/simulate while the chunk is near the player.
var _mobs_spawned: bool = false
var _mobs_active: bool = false
var _spawned_mobs: Array[Node] = []
var _stored_depth: int = 0
var _stored_difficulty: float = 1.0


func setup(coord: Vector2i, world_seed: int, depth: int, difficulty_multiplier: float = 1.0) -> void:
	chunk_coord = coord
	position = Vector3(coord.x * CHUNK_SIZE, 0.0, coord.y * CHUNK_SIZE)
	_world_seed = world_seed
	_chunk_rng_seed = world_seed + coord.x * 928371 + coord.y * 689287
	_stored_depth = depth
	_stored_difficulty = difficulty_multiplier
	_noise = FastNoiseLite.new()
	# Shared seed keeps height continuous across chunk boundaries.
	_noise.seed = _world_seed
	_noise.frequency = 0.04
	_noise.fractal_octaves = 3
	_load_prop_scenes()
	_determine_biome(depth)
	_determine_chunk_type(depth)
	if is_cave():
		_plan_cave()  # must run BEFORE terrain so the ravine is carved into it
	_build_terrain()
	if is_cave():
		_build_cave_interior()
	else:
		_scatter_props(depth)
	match chunk_type:
		"shop":
			call_deferred("_build_shop_exterior")
		"ruins":
			call_deferred("_build_ruins")
	call_deferred("_spawn_loot", depth)
	# Enemies are NOT spawned here — WorldGenerator activates them by range.


func is_cave() -> bool:
	return chunk_type == "cave"


## Called by WorldGenerator: spawn/enable mobs near the player, freeze them far away.
func set_mobs_active(active: bool) -> void:
	if active == _mobs_active:
		return
	_mobs_active = active
	if active and not _mobs_spawned:
		_mobs_spawned = true
		if is_cave():
			_spawn_cave_mobs(_stored_depth, _stored_difficulty)
		else:
			_spawn_enemies(_stored_depth, _stored_difficulty)
		return  # freshly spawned mobs are already active
	for mob in _spawned_mobs:
		if not is_instance_valid(mob):
			continue
		mob.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
		if mob is Node3D:
			(mob as Node3D).visible = active


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
	# Deterministic shop grid: a merchant stop every 4 chunks in each axis,
	# so every realm always has reachable shops (nearest at chunk (2,2)).
	if posmod(chunk_coord.x, 4) == 2 and posmod(chunk_coord.y, 4) == 2:
		chunk_type = "shop"
		return
	if chunk_coord == Vector2i.ZERO or depth < 2:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = _chunk_rng_seed + 501
	var roll := rng.randf()
	if roll < 0.2:
		chunk_type = "cave"  # caves now host ALL dungeon portals
	elif roll < 0.32:
		chunk_type = "ruins"
	elif roll < 0.5:
		chunk_type = "forest"


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
	if chunk_type == "ruins":
		loot_count += 2  # ruins reward the detour
	for i in loot_count:
		if rng.randf() > 0.82:
			continue
		var item := LootTable.roll_loot(depth, rng)
		var local_x := rng.randf_range(4.0, CHUNK_SIZE - 4.0)
		var local_z := rng.randf_range(4.0, CHUNK_SIZE - 4.0)
		if chunk_type == "shop":
			var to_center := Vector2(local_x - CHUNK_SIZE * 0.5, local_z - CHUNK_SIZE * 0.5)
			if to_center.length() < 8.0:
				continue
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
	var h := get_terrain_height(_world_seed, world_x, world_z)
	if _cave_planned:
		h = _carved_height(world_x, world_z, h)
	return h


## Plans the whole underground layout: a long winding descending path with
## turn bowls, side loot pockets, enemy areas, and the final chamber position.
## The carved region stays inside CAVE_SAFE bounds so chunk edges never seam.
func _plan_cave() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _chunk_rng_seed + 777

	# Waypoints lie on a DESCENDING SPIRAL around the chunk center: a spiral
	# can never cross itself, always fits the safe box, and its gentle
	# per-segment drop (max ~27°) is walkable both down AND back up.
	var center := Vector2(CHUNK_SIZE * 0.5, CHUNK_SIZE * 0.5)
	var theta := rng.randf() * TAU
	var winding := 1.0 if rng.randf() < 0.5 else -1.0
	# Total winding stays under ~240° so the end arena can never curl back
	# near the entrance and undercut the doorstep.
	var dtheta := deg_to_rad(rng.randf_range(70.0, 80.0))
	var radii: Array[float] = [6.0, 5.4, 4.7, 4.2]
	var depth_offsets: Array[float] = [0.0, -3.5, -6.5, -CAVE_DROP]

	_cave_pts = []
	_cave_depths = []
	for i in 4:
		var th := theta + winding * dtheta * float(i)
		_cave_pts.append(center + Vector2(cos(th), sin(th)) * radii[i])
	_cave_entrance = _cave_pts[0]
	_cave_h0 = get_terrain_height(_world_seed,
		chunk_coord.x * CHUNK_SIZE + _cave_entrance.x,
		chunk_coord.y * CHUNK_SIZE + _cave_entrance.y)
	for i in 4:
		_cave_depths.append(_cave_h0 + depth_offsets[i])
	_cave_dir = (_cave_pts[1] - _cave_pts[0]).normalized()

	# Widened bowls: a FLATTENED doorstep apron (no terrain lip can ever block
	# the mouth), turn bowls (enemy areas), side loot pockets, and a large
	# terminal arena where the dungeon door stands.
	_cave_wells = []
	_cave_mob_spots = []
	_cave_loot_spots = []
	_cave_wells.append({"pos": _cave_pts[0], "h": _cave_h0, "inner": 3.5, "outer": 5.0, "flatten": true})
	for i in [1, 2]:
		_cave_wells.append({"pos": _cave_pts[i], "h": _cave_depths[i], "inner": 4.0, "outer": 6.5})
		_cave_mob_spots.append(Vector3(_cave_pts[i].x, _cave_depths[i] + 0.6, _cave_pts[i].y))
	# Terminal arena bowl: the end of the cave, home of the dungeon door.
	_cave_wells.append({"pos": _cave_pts[3], "h": _cave_depths[3], "inner": 5.0, "outer": 6.0})
	for i in [0, 1]:
		if rng.randf() < 0.8:
			var a: Vector2 = _cave_pts[i + 1]
			var b: Vector2 = _cave_pts[i]
			var seg_dir := (a - b).normalized()
			var perp := Vector2(-seg_dir.y, seg_dir.x)
			var mid: Vector2 = (a + b) * 0.5
			# Pockets always open OUTWARD from the spiral so they can never
			# collide with another stretch of the path.
			if perp.dot(mid - center) < 0.0:
				perp = -perp
			var pocket: Vector2 = mid + perp * 4.5
			pocket.x = clampf(pocket.x, CAVE_SAFE_MIN, CAVE_SAFE_MAX)
			pocket.y = clampf(pocket.y, CAVE_SAFE_MIN, CAVE_SAFE_MAX)
			var pocket_h: float = (_cave_depths[i] + _cave_depths[i + 1]) * 0.5
			_cave_wells.append({"pos": pocket, "h": pocket_h, "inner": 2.6, "outer": 4.6})
			_cave_loot_spots.append(Vector3(pocket.x, pocket_h + 0.4, pocket.y))
	_cave_loot_spots.append(Vector3(_cave_pts[2].x, _cave_depths[2] + 0.4, _cave_pts[2].y))

	_cave_planned = true


## Digs the winding path and its bowls into the heightmap (mesh AND collision),
## so the player simply walks down into the cave — nothing blocks the way.
func _carved_height(world_x: float, world_z: float, h: float) -> float:
	var p := Vector2(world_x - chunk_coord.x * CHUNK_SIZE, world_z - chunk_coord.y * CHUNK_SIZE)

	# Flatten wells first (entrance apron): level the ground both up AND down
	# so no natural lip or bump can ever block a cave mouth.
	var base := h
	for well in _cave_wells:
		if not well.get("flatten", false):
			continue
		var d := (p - (well["pos"] as Vector2)).length()
		var outer: float = well["outer"]
		if d >= outer:
			continue
		var falloff := 1.0 - smoothstep(well["inner"] as float, outer, d)
		base = lerpf(base, well["h"] as float, falloff)

	var best := base
	for j in _cave_pts.size() - 1:
		var a: Vector2 = _cave_pts[j]
		var ab: Vector2 = _cave_pts[j + 1] - a
		var seg_len := ab.length()
		if seg_len < 0.01:
			continue
		var seg_dir := ab / seg_len
		var t := clampf((p - a).dot(seg_dir), 0.0, seg_len)
		var d := (p - (a + seg_dir * t)).length()
		if d >= CAVE_CARVE_OUTER:
			continue
		var ramp := lerpf(_cave_depths[j], _cave_depths[j + 1], t / seg_len)
		var falloff := 1.0 - smoothstep(CAVE_CARVE_INNER, CAVE_CARVE_OUTER, d)
		best = minf(best, lerpf(base, minf(base, ramp), falloff))

	for well in _cave_wells:
		if well.get("flatten", false):
			continue
		var d := (p - (well["pos"] as Vector2)).length()
		var outer: float = well["outer"]
		if d >= outer:
			continue
		var falloff := 1.0 - smoothstep(well["inner"] as float, outer, d)
		best = minf(best, lerpf(base, minf(base, well["h"] as float), falloff))

	return best


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
		"res://assets/model/FantasyPack/props/tree_pine.glb",
		"res://assets/model/FantasyPack/props/tree_oak.glb",
		"res://assets/model/FantasyPack/props/bush.glb",
		"res://assets/model/FantasyPack/cave/rock_small.glb",
		"res://assets/model/FantasyPack/cave/rock_medium.glb",
		"res://assets/model/FantasyPack/cave/rock_large.glb",
		"res://assets/model/Other/pinetree.glb",
		"res://assets/model/Other/grass.glb",
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
	# Vegetation thins out in harsher biomes; forests are dense landmarks.
	var density: float = float(BIOME_DENSITY.get(biome, 1.0))
	var prop_count := clampi(int((2 + depth) * density), 0, 6)
	if chunk_type == "forest":
		prop_count = clampi(prop_count * 3 + 4, 8, 14)
	if prop_count == 0:
		return
	var props_root := Node3D.new()
	props_root.name = "Props"
	add_child(props_root)

	for i in prop_count:
		var scene := _prop_scenes[rng.randi() % _prop_scenes.size()]
		var local_x := rng.randf_range(2.0, CHUNK_SIZE - 2.0)
		var local_z := rng.randf_range(2.0, CHUNK_SIZE - 2.0)
		# Keep the shop's yard clear of trees and rocks.
		if chunk_type == "shop":
			var to_center := Vector2(local_x - CHUNK_SIZE * 0.5, local_z - CHUNK_SIZE * 0.5)
			if to_center.length() < 9.0:
				continue
		var prop := scene.instantiate()
		props_root.add_child(prop)
		var h := _sample_height(chunk_coord.x * CHUNK_SIZE + local_x, chunk_coord.y * CHUNK_SIZE + local_z)
		prop.position = Vector3(local_x, h, local_z)
		prop.rotation.y = rng.randf() * TAU
		prop.scale = Vector3.ONE * rng.randf_range(0.6, 1.2)


func _spawn_enemies(depth: int, difficulty_multiplier: float = 1.0) -> void:
	if is_cave() or chunk_type == "shop":
		return  # shops are safe ground
	var rng := RandomNumberGenerator.new()
	rng.seed = _chunk_rng_seed + 99
	var count := 0 if depth == 0 else clampi(1 + int(depth * difficulty_multiplier / 2.0), 1, 5)
	if chunk_type == "ruins" and count > 0:
		count += 1  # ruins are contested ground
	if count == 0:
		return
	var spawns := Node3D.new()
	spawns.name = "EnemySpawns"
	add_child(spawns)

	var mob_pool: Array = BIOME_MOBS.get(biome, BIOME_MOBS["verdant"])
	for i in count:
		var enemy := _enemy_scene.instantiate()
		spawns.add_child(enemy)
		var local_x := rng.randf_range(4.0, CHUNK_SIZE - 4.0)
		var local_z := rng.randf_range(4.0, CHUNK_SIZE - 4.0)
		var h := _sample_height(chunk_coord.x * CHUNK_SIZE + local_x, chunk_coord.y * CHUNK_SIZE + local_z)
		enemy.position = Vector3(local_x, h + 1.0, local_z)
		_finish_mob_setup(enemy, rng, mob_pool, depth, difficulty_multiplier)


## Cave dwellers: enemy areas at the path's turn bowls plus chamber guards.
func _spawn_cave_mobs(depth: int, difficulty_multiplier: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _chunk_rng_seed + 99
	var mob_pool: Array = BIOME_MOBS.get(biome, BIOME_MOBS["verdant"])
	var spawns := Node3D.new()
	spawns.name = "CaveMobs"
	add_child(spawns)
	var side := _chamber_forward.cross(Vector3.UP).normalized()

	var spots: Array[Vector3] = []
	spots.append_array(_cave_mob_spots)
	for i in 2:
		spots.append(_chamber_center \
			+ side * rng.randf_range(-_chamber_size.x * 0.25, _chamber_size.x * 0.25) \
			+ _chamber_forward * rng.randf_range(-1.0, _chamber_size.z * 0.25) \
			+ Vector3(0, 0.6, 0))

	for spot in spots:
		var enemy := _enemy_scene.instantiate()
		spawns.add_child(enemy)
		enemy.position = spot
		_finish_mob_setup(enemy, rng, mob_pool, depth, difficulty_multiplier)


func _finish_mob_setup(enemy: Node, rng: RandomNumberGenerator, mob_pool: Array, depth: int, difficulty_multiplier: float) -> void:
	var mob_id: String = mob_pool[rng.randi() % mob_pool.size()]
	var flavor: Dictionary = MOB_STATS.get(mob_id, {})
	if "hp" in enemy:
		enemy.hp = int((15 + depth * 5) * difficulty_multiplier * flavor.get("hp", 1.0))
	if "damage" in enemy:
		enemy.damage = int((12 + depth * 2) * difficulty_multiplier * flavor.get("dmg", 1.0))
	if "value" in enemy:
		enemy.value = int((10 + depth * 3) * difficulty_multiplier)
	if "speed" in enemy:
		enemy.speed = flavor.get("speed", 2.0)
	if enemy.has_method("set_mob_visual"):
		enemy.set_mob_visual(MOB_DIR + mob_id + ".glb")
	_spawned_mobs.append(enemy)


## Real underground cave, built from the _plan_cave layout: clear open
## entrance -> long winding carved path with turn bowls, side loot pockets and
## enemy areas -> terminal arena bowl holding the dungeon door. Everything is
## carved into the terrain itself (mesh AND collision), so nothing blocks the
## way at any point.
func _build_cave_interior() -> void:
	_cave_root = Node3D.new()
	_cave_root.name = "CaveInterior"
	add_child(_cave_root)

	var rng := RandomNumberGenerator.new()
	rng.seed = _chunk_rng_seed + 778

	var cave_h := 8.0
	var dir0 := Vector3(_cave_dir.x, 0.0, _cave_dir.y)
	var entrance := Vector3(_cave_entrance.x, _cave_h0, _cave_entrance.y)
	_entrance_return_local = entrance - dir0 * 5.0
	var last_pt: Vector2 = _cave_pts[_cave_pts.size() - 1]
	var prev_pt: Vector2 = _cave_pts[_cave_pts.size() - 2]
	var dir := Vector3((last_pt - prev_pt).normalized().x, 0.0, (last_pt - prev_pt).normalized().y)
	var side := dir.cross(Vector3.UP).normalized()

	# --- Open, clearly visible entrance: nothing within 6 m of the mouth ---
	var pack := "res://assets/model/FantasyPack/"
	var side0 := dir0.cross(Vector3.UP).normalized()
	ModelLibrary.place_prop(_cave_root, pack + "cave/cave_entrance.glb", entrance - dir0 * 2.0 + side0 * 6.5, atan2(-dir0.x, -dir0.z))

	var cave_sign := Label3D.new()
	cave_sign.text = "CAVE"
	cave_sign.font_size = 84
	cave_sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	cave_sign.modulate = Color(1, 0.85, 0.4)
	cave_sign.outline_size = 12
	cave_sign.position = entrance + Vector3(0, 4.5, 0)
	_cave_root.add_child(cave_sign)

	var mouth_light := OmniLight3D.new()
	mouth_light.light_color = Color(1, 0.75, 0.45)
	mouth_light.light_energy = 1.0
	mouth_light.omni_range = 10.0
	mouth_light.position = entrance + Vector3(0, 2.5, 0)
	_cave_root.add_child(mouth_light)

	# --- Braziers + lights at every bowl along the path (never a dark stretch) ---
	for well in _cave_wells:
		var wp: Vector2 = well["pos"]
		var wh: float = well["h"]
		var bpos := Vector3(wp.x + 1.6, wh + 0.15, wp.y + 1.2)
		ModelLibrary.place_prop(_cave_root, pack + "dungeon/brazier.glb", bpos, rng.randf() * TAU)
		var rl := OmniLight3D.new()
		rl.light_color = Color(1, 0.6, 0.3)
		rl.light_energy = 1.2
		rl.omni_range = 13.0
		rl.position = bpos + Vector3(0, 1.5, 0)
		_cave_root.add_child(rl)
		if rng.randf() < 0.6:
			ModelLibrary.place_prop(_cave_root, pack + "cave/stalagmite.glb",
				Vector3(wp.x - 2.2, wh, wp.y - 1.8), rng.randf() * TAU)

	# --- Loot along the way: pockets and the last bend hold real pickups ---
	for spot in _cave_loot_spots:
		var item := LootTable.roll_loot(_stored_depth + 1, rng)
		var pickup := _loot_scene.instantiate()
		if pickup.has_method("set_loot"):
			pickup.set_loot(item)
		elif "loot_data" in pickup:
			pickup.loot_data = item
		_cave_root.add_child(pickup)
		pickup.position = spot
		# A crystal marks each treasure pocket.
		ModelLibrary.place_prop(_cave_root, pack + ("cave/crystal_cluster_blue.glb" if rng.randf() < 0.5 else "cave/crystal_cluster_purple.glb"),
			spot + Vector3(1.4, -0.4, 1.0), rng.randf() * TAU)

	# --- Enclosed cave structure: rock walls + ceiling following every path
	# segment, so the interior is a real roofed underground tunnel ---
	var rock_mat := StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.29, 0.25, 0.22)
	rock_mat.roughness = 1.0

	for j in _cave_pts.size() - 1:
		var a3 := Vector3(_cave_pts[j].x, _cave_depths[j], _cave_pts[j].y)
		var b3 := Vector3(_cave_pts[j + 1].x, _cave_depths[j + 1], _cave_pts[j + 1].y)
		var seg_vec := b3 - a3
		var seg_len := seg_vec.length()
		var mid := (a3 + b3) * 0.5
		var use_len := seg_len + 2.0
		if j == 0:
			# Keep the mouth open to the sky: the roof starts a few metres in.
			mid += seg_vec.normalized() * 2.0
			use_len = seg_len - 4.0
		var seg_node := Node3D.new()
		_cave_root.add_child(seg_node)
		seg_node.transform = Transform3D(Basis.looking_at(seg_vec.normalized(), Vector3.UP), mid)
		_add_room_box(seg_node, Vector3(4.4, 2.0, 0), Vector3(1.4, 9.0, use_len), rock_mat)
		_add_room_box(seg_node, Vector3(-4.4, 2.0, 0), Vector3(1.4, 9.0, use_len), rock_mat)
		_add_room_box(seg_node, Vector3(0, 6.0, 0), Vector3(10.0, 1.0, use_len), rock_mat)
		# Unlit torches on alternating walls (emissive flames glow with bloom).
		var tside := 1.0 if (j % 2 == 0) else -1.0
		ModelLibrary.place_prop(seg_node, "res://assets/model/FantasyPack/cave/torch_wall.glb",
			Vector3(3.6 * tside, 1.8, 0), PI * 0.5 * tside)

	# Roof slabs over the turn bowls and the terminal arena (flat, axis-aligned
	# is fine for horizontal slabs) — true rotunda chambers underground.
	for i in [1, 2]:
		_add_cave_box(Vector3(_cave_pts[i].x, _cave_depths[i] + 6.4, _cave_pts[i].y), Vector3(14.5, 1.0, 14.5), rock_mat)
	var floor_top := _cave_h0 - CAVE_DROP
	_add_cave_box(Vector3(last_pt.x, floor_top + 7.0, last_pt.y), Vector3(17.0, 1.0, 17.0), rock_mat)

	# --- Terminal arena: the end of the cave ---
	_chamber_center = Vector3(last_pt.x, floor_top, last_pt.y)
	_chamber_forward = dir
	_chamber_size = Vector3(12.0, cave_h, 12.0)  # arena bowl dimensions

	# Bright arena lighting so both portals and guards read clearly.
	for offset in [side * 4.0, -side * 4.0]:
		var light := OmniLight3D.new()
		light.light_color = Color(0.98, 0.6, 0.35)
		light.light_energy = 1.3
		light.omni_range = 16.0
		light.position = _chamber_center + offset + Vector3(0, 3.0, 0)
		_cave_root.add_child(light)

	# --- The dungeon door (design unchanged) at the very end of the path ---
	var door := DungeonDoor.new()
	_cave_root.add_child(door)
	door.position = _chamber_center + dir * 3.5
	door.rotation.y = atan2(-dir.x, -dir.z)
	var return_global := _entrance_return_local + position + Vector3(0, 1.2, 0)
	door.configure(return_global, _stored_difficulty)

	# --- The blue Mini-Boss Dungeon portal, moved here from the open field ---
	var loot_portal := DungeonPortal.new()
	_cave_root.add_child(loot_portal)
	loot_portal.position = _chamber_center + side * 3.6 - dir * 1.2
	loot_portal.configure(return_global, _stored_difficulty)

	_decorate_cave(rng, dir, side, floor_top, cave_h)


## FantasyPack dressing inside the terminal arena bowl (open-air crater).
func _decorate_cave(rng: RandomNumberGenerator, dir: Vector3, side: Vector3, floor_top: float, _cave_h: float) -> void:
	var pack := "res://assets/model/FantasyPack/"
	var center := _chamber_center

	# Braziers flanking the dungeon door.
	for s: float in [1.0, -1.0]:
		var bpos: Vector3 = center + dir * 2.8 + side * 2.6 * s
		bpos.y = floor_top + 0.1
		ModelLibrary.place_prop(_cave_root, pack + "dungeon/brazier.glb", bpos, 0.0)

	# Crystals glowing at the arena rim.
	for i in 2:
		var crystal := "cave/crystal_cluster_blue.glb" if i == 0 else "cave/crystal_cluster_purple.glb"
		var cpos := center + side * 4.4 * (1.0 if i == 0 else -1.0) - dir * 2.0
		cpos.y = floor_top
		ModelLibrary.place_prop(_cave_root, pack + crystal, cpos, rng.randf() * TAU, 1.2)

	# Scattered rocks, bones, stalagmites around the arena edges.
	var floor_props := ["cave/rock_small.glb", "cave/rock_medium.glb", "cave/stalagmite.glb", "cave/bone_pile.glb"]
	for prop_path in floor_props:
		var angle := rng.randf() * TAU
		var ppos := center + Vector3(cos(angle), 0, sin(angle)) * rng.randf_range(3.5, 5.0)
		ppos.y = floor_top
		ModelLibrary.place_prop(_cave_root, pack + prop_path, ppos, rng.randf() * TAU)


## Stone box with collision placed in a room's LOCAL frame (rotates with it).
func _add_room_box(room: Node3D, local_pos: Vector3, size: Vector3, material: StandardMaterial3D) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	room.add_child(body)
	body.position = local_pos

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


## Axis-independent stone box with collision (for the inclined tunnel).
func _add_oriented_box(center: Vector3, size: Vector3, box_basis: Basis, material: StandardMaterial3D) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	_cave_root.add_child(body)
	body.transform = Transform3D(box_basis, center)

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


## Merchant building at the chunk center, door facing world origin.
func _build_shop_exterior() -> void:
	var center_x := CHUNK_SIZE * 0.5
	var center_z := CHUNK_SIZE * 0.5
	var world_x := chunk_coord.x * CHUNK_SIZE + center_x
	var world_z := chunk_coord.y * CHUNK_SIZE + center_z
	var h := _sample_height(world_x, world_z)

	var shop := _shop_scene.instantiate()
	add_child(shop)
	shop.position = Vector3(center_x, h, center_z)
	# Face the door roughly toward the world origin so travellers meet it.
	var to_origin := Vector2(-world_x, -world_z)
	if to_origin.length_squared() > 0.01:
		shop.rotation.y = atan2(to_origin.x, to_origin.y)

	# FantasyPack yard dressing (local to the building so it rotates with it).
	var pack := "res://assets/model/FantasyPack/"
	ModelLibrary.place_prop(shop, pack + "shop/shop_sign.glb", Vector3(-1.6, 0, 5.2))
	ModelLibrary.place_prop(shop, pack + "props/lamp_post.glb", Vector3(2.6, 0, 6.2))
	ModelLibrary.place_prop(shop, pack + "shop/barrel.glb", Vector3(-3.2, 0.5, 4.8))
	ModelLibrary.place_prop(shop, pack + "shop/crate.glb", Vector3(3.6, 0.5, 4.6), 0.5)


## Broken pillars and rubble — a lootable landmark.
func _build_ruins() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _chunk_rng_seed + 333
	var ruins_root := Node3D.new()
	ruins_root.name = "Ruins"
	add_child(ruins_root)

	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.55, 0.53, 0.48)
	stone_mat.roughness = 0.95

	var pack := "res://assets/model/FantasyPack/"
	var use_pack := ModelLibrary.exists(pack + "props/pillar_ruined.glb")

	var center_x := rng.randf_range(10.0, CHUNK_SIZE - 10.0)
	var center_z := rng.randf_range(10.0, CHUNK_SIZE - 10.0)
	var pillar_count := rng.randi_range(4, 7)
	for i in pillar_count:
		var angle := TAU * float(i) / float(pillar_count) + rng.randf_range(-0.3, 0.3)
		var radius := rng.randf_range(3.0, 6.5)
		var px := center_x + cos(angle) * radius
		var pz := center_z + sin(angle) * radius
		var ph := _sample_height(chunk_coord.x * CHUNK_SIZE + px, chunk_coord.y * CHUNK_SIZE + pz)
		var height := rng.randf_range(1.2, 4.5)

		var body := StaticBody3D.new()
		body.collision_layer = 1
		ruins_root.add_child(body)
		body.position = Vector3(px, ph + height * 0.5 - 0.3, pz)
		body.rotation = Vector3(rng.randf_range(-0.08, 0.08), rng.randf() * TAU, rng.randf_range(-0.08, 0.08))

		if use_pack:
			# FantasyPack ruined pillar, scaled to this pillar's height.
			var model := ModelLibrary.spawn(pack + "props/pillar_ruined.glb")
			if model:
				body.add_child(model)
				var aabb := ModelLibrary.measure(model)
				if aabb.size.y > 0.05:
					var s := height / aabb.size.y
					model.scale = Vector3(s, s, s)
					model.position = Vector3(0, -height * 0.5, 0)
		else:
			var mesh := CylinderMesh.new()
			mesh.top_radius = 0.55
			mesh.bottom_radius = 0.7
			mesh.height = height
			var mesh_inst := MeshInstance3D.new()
			mesh_inst.mesh = mesh
			mesh_inst.material_override = stone_mat
			body.add_child(mesh_inst)

		var shape := CylinderShape3D.new()
		shape.radius = 0.7
		shape.height = height
		var col := CollisionShape3D.new()
		col.shape = shape
		body.add_child(col)

	# Centerpiece arch and a few graves — decor only.
	if use_pack:
		var arch_pos := Vector3(center_x, 0, center_z)
		arch_pos.y = _sample_height(chunk_coord.x * CHUNK_SIZE + center_x, chunk_coord.y * CHUNK_SIZE + center_z)
		ModelLibrary.place_prop(ruins_root, pack + "props/ruin_arch.glb", arch_pos, rng.randf() * TAU)
		for i in 2:
			var gx := center_x + rng.randf_range(-5.0, 5.0)
			var gz := center_z + rng.randf_range(-5.0, 5.0)
			var gy := _sample_height(chunk_coord.x * CHUNK_SIZE + gx, chunk_coord.y * CHUNK_SIZE + gz)
			ModelLibrary.place_prop(ruins_root, pack + "props/gravestone.glb", Vector3(gx, gy, gz), rng.randf() * TAU)


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
