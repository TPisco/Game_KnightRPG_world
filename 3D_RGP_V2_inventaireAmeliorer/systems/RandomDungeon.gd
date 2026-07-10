## Randomly generated mini-boss dungeon: a fresh room layout on every entry,
## mini-bosses only (never the real boss), boss-tier loot on victory, and a
## return portal back to exactly where the player came from. Seal progression
## (the 2-mini-boss requirement of the cave dungeons) is NOT affected here.
class_name RandomDungeon
extends Node3D

const REENTRY_COOLDOWN_MS := 1500
const DUNGEON_DEPTH := -320.0
const ENEMY_SCENE := preload("res://scenes/objects/chunk_enemy.tscn")
const LOOT_SCENE := preload("res://scenes/Items/WorldLootPickup.tscn")
const MINIBOSS_MODELS := [
	"res://assets/model/FantasyPack/minibosses/miniboss_cave_guardian.glb",
	"res://assets/model/FantasyPack/minibosses/miniboss_crystal_golem.glb",
	"res://assets/model/FantasyPack/minibosses/miniboss_orc_warlord.glb",
]

var _return_position: Vector3 = Vector3.ZERO
var _cooldown_until_ms: int = 0
var _room: Node3D = null
var _spawn_pos: Vector3 = Vector3.ZERO  # local
var _boss_pos: Vector3 = Vector3.ZERO   # local
var _bosses_alive: int = 0
var _difficulty: float = 1.0
var _room_size: Vector2 = Vector2(22, 26)


func enter(player: Node3D, return_pos: Vector3, difficulty: float) -> void:
	if Time.get_ticks_msec() < _cooldown_until_ms:
		return
	_cooldown_until_ms = Time.get_ticks_msec() + REENTRY_COOLDOWN_MS
	_return_position = return_pos
	_difficulty = difficulty
	global_position = Vector3(return_pos.x, DUNGEON_DEPTH, return_pos.z)

	_rebuild_room()
	player.global_position = global_position + _spawn_pos
	if "velocity" in player:
		player.velocity = Vector3.ZERO
	SoundManager.play("portal")


## Builds a brand-new randomized layout each entry.
func _rebuild_room() -> void:
	if _room and is_instance_valid(_room):
		_room.queue_free()
	_room = Node3D.new()
	_room.name = "Room"
	add_child(_room)

	var rng := RandomNumberGenerator.new()
	rng.randomize()  # truly different every visit
	var w := rng.randf_range(20.0, 28.0)
	var l := rng.randf_range(24.0, 34.0)
	var height := 9.0
	_room_size = Vector2(w, l)
	_spawn_pos = Vector3(0, 1.2, -l * 0.5 + 3.0)
	_boss_pos = Vector3(rng.randf_range(-w * 0.15, w * 0.15), 0.6, l * 0.5 - 6.0)

	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.2, 0.18, 0.22)
	floor_mat.roughness = 1.0
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.26, 0.22, 0.27)
	wall_mat.roughness = 1.0

	_add_box(Vector3(0, -0.5, 0), Vector3(w, 1, l), floor_mat)
	_add_box(Vector3(0, height + 0.5, 0), Vector3(w, 1, l), wall_mat)
	_add_box(Vector3(-w * 0.5, height * 0.5, 0), Vector3(1, height, l), wall_mat)
	_add_box(Vector3(w * 0.5, height * 0.5, 0), Vector3(1, height, l), wall_mat)
	_add_box(Vector3(0, height * 0.5, -l * 0.5), Vector3(w, height, 1), wall_mat)
	_add_box(Vector3(0, height * 0.5, l * 0.5), Vector3(w, height, 1), wall_mat)

	# Random pillars and decor make every layout feel different.
	var pack := "res://assets/model/FantasyPack/"
	for i in rng.randi_range(2, 5):
		var px := rng.randf_range(-w * 0.35, w * 0.35)
		var pz := rng.randf_range(-l * 0.28, l * 0.28)
		var pillar := "dungeon/dungeon_pillar.glb" if rng.randf() < 0.6 else "dungeon/dungeon_pillar_broken.glb"
		ModelLibrary.place_prop(_room, pack + pillar, Vector3(px, 0, pz), rng.randf() * TAU)
	for prop in ["cave/bone_pile.glb", "cave/crystal_cluster_purple.glb", "dungeon/brazier.glb", "cave/rock_medium.glb"]:
		if rng.randf() < 0.75:
			ModelLibrary.place_prop(_room, pack + prop,
				Vector3(rng.randf_range(-w * 0.4, w * 0.4), 0, rng.randf_range(-l * 0.35, l * 0.35)),
				rng.randf() * TAU)

	for i in 3:
		var light := OmniLight3D.new()
		light.light_color = Color(0.7, 0.45, 0.9) if i == 1 else Color(1, 0.6, 0.35)
		light.light_energy = 1.4
		light.omni_range = 20.0
		light.position = Vector3(rng.randf_range(-w * 0.3, w * 0.3), height - 2.0, (i - 1) * l * 0.3)
		_room.add_child(light)

	# Exit door (always available — leaving early just means no loot).
	var exit_visual := MeshInstance3D.new()
	var exit_mesh := BoxMesh.new()
	exit_mesh.size = Vector3(2, 3, 0.2)
	exit_visual.mesh = exit_mesh
	var exit_mat := StandardMaterial3D.new()
	exit_mat.albedo_color = Color(0.4, 0.7, 1, 0.85)
	exit_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	exit_mat.emission_enabled = true
	exit_mat.emission = Color(0.3, 0.6, 1)
	exit_mat.emission_energy_multiplier = 1.6
	exit_visual.material_override = exit_mat
	exit_visual.position = Vector3(0, 1.5, -l * 0.5 + 0.4)
	_room.add_child(exit_visual)
	var exit_label := Label3D.new()
	exit_label.text = "Leave Dungeon"
	exit_label.font_size = 32
	exit_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	exit_label.modulate = Color(0.6, 0.85, 1)
	exit_label.position = Vector3(0, 3.4, -l * 0.5 + 0.6)
	_room.add_child(exit_label)
	var exit_area := Area3D.new()
	_room.add_child(exit_area)
	var exit_col := CollisionShape3D.new()
	var exit_shape := BoxShape3D.new()
	exit_shape.size = Vector3(2.4, 3, 1.2)
	exit_col.shape = exit_shape
	exit_col.position = Vector3(0, 1.5, -l * 0.5 + 0.8)
	exit_area.add_child(exit_col)
	exit_area.body_entered.connect(_on_exit_body_entered)

	# Mini-bosses only: one, or two in deeper realms.
	var count := 1 + (1 if _difficulty >= 1.8 else 0)
	_bosses_alive = count
	for i in count:
		var offset := Vector3(4.0 * i - 2.0 * (count - 1), 0, 2.0 * i)
		_spawn_miniboss(_boss_pos + offset, rng)


func _spawn_miniboss(local_pos: Vector3, rng: RandomNumberGenerator) -> void:
	var mob := ENEMY_SCENE.instantiate()
	_room.add_child(mob)
	mob.position = local_pos
	if "hp" in mob:
		mob.hp = int(280 * _difficulty)
	if "damage" in mob:
		mob.damage = int(26 * _difficulty)
	if "value" in mob:
		mob.value = int(70 * _difficulty)
	if "speed" in mob:
		mob.speed = 2.6
	if "attack_interval" in mob:
		mob.attack_interval = 1.6
	if mob.has_method("set_mob_visual"):
		mob.set_mob_visual(MINIBOSS_MODELS[rng.randi() % MINIBOSS_MODELS.size()])
	mob.scale = Vector3(1.4, 1.4, 1.4)
	if "_death_system" in mob and mob._death_system:
		mob._death_system.death_rewards_callback = _on_miniboss_defeated.bind(mob)


func _on_miniboss_defeated(mob: Node) -> void:
	# The callback replaces default rewards — grant XP/gold explicitly.
	var value: int = int(mob.value) if "value" in mob else 60
	ProgressionTracker.add_xp(value)
	var killer = mob.target if "target" in mob else null
	if killer and is_instance_valid(killer) and killer.has_method("player"):
		killer.gold += value
		if killer.has_method("_updateHUD"):
			killer._updateHUD()

	_bosses_alive -= 1
	if _bosses_alive > 0:
		return
	_spawn_loot(mob)
	_spawn_return_portal()
	StoryManager.trigger_story_event("random_dungeon_clear")


## Boss-tier loot scattered where the last mini-boss fell.
func _spawn_loot(mob: Node) -> void:
	if _room == null or not is_instance_valid(_room):
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var center: Vector3 = (mob as Node3D).position if mob is Node3D else _boss_pos
	var items := LootTable.roll_boss_loot(ProgressionTracker.run_depth + 4, rng)
	for i in items.size():
		var pickup := LOOT_SCENE.instantiate()
		if pickup.has_method("set_loot"):
			pickup.set_loot(items[i])
		elif "loot_data" in pickup:
			pickup.loot_data = items[i]
		_room.add_child(pickup)
		var angle := TAU * float(i) / float(items.size())
		pickup.position = Vector3(center.x + cos(angle) * 1.8, 0.5, center.z + sin(angle) * 1.8)


func _spawn_return_portal() -> void:
	if _room == null or not is_instance_valid(_room):
		return
	var portal := Node3D.new()
	portal.name = "ReturnPortal"
	_room.add_child(portal)
	portal.position = Vector3(0, 0, _room_size.y * 0.5 - 2.5)

	var torus := TorusMesh.new()
	torus.inner_radius = 0.55
	torus.outer_radius = 1.3
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.95, 0.5, 0.85)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.9, 0.4)
	mat.emission_energy_multiplier = 2.2
	var ring := MeshInstance3D.new()
	ring.mesh = torus
	ring.material_override = mat
	ring.rotation_degrees = Vector3(90, 0, 0)
	ring.position = Vector3(0, 1.7, 0)
	portal.add_child(ring)

	var label := Label3D.new()
	label.text = "RETURN PORTAL\nBack to your world"
	label.font_size = 40
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(0.5, 1, 0.6)
	label.outline_size = 10
	label.position = Vector3(0, 3.8, 0)
	portal.add_child(label)

	var light := OmniLight3D.new()
	light.light_color = Color(0.3, 1, 0.5)
	light.light_energy = 2.0
	light.omni_range = 9.0
	light.position = Vector3(0, 1.7, 0)
	portal.add_child(light)

	var area := Area3D.new()
	portal.add_child(area)
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.height = 3.5
	shape.radius = 1.4
	col.shape = shape
	col.position = Vector3(0, 1.7, 0)
	area.add_child(col)
	area.body_entered.connect(_on_exit_body_entered)
	SoundManager.play("portal")


func _on_exit_body_entered(body: Node3D) -> void:
	if not body.has_method("player"):
		return
	if Time.get_ticks_msec() < _cooldown_until_ms:
		return
	_cooldown_until_ms = Time.get_ticks_msec() + REENTRY_COOLDOWN_MS
	body.global_position = _return_position
	if "velocity" in body:
		body.velocity = Vector3.ZERO
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	SoundManager.play("portal")


func _add_box(local_pos: Vector3, size: Vector3, material: StandardMaterial3D) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	_room.add_child(body)
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
