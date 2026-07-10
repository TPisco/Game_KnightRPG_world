## Shared mini-boss dungeon room. Each visit spawns the next mini-boss for the
## current realm; two clears break the seal and reveal the Boss Gate.
class_name MiniBossArena
extends Node3D

const REENTRY_COOLDOWN_MS := 1500
const ARENA_DEPTH := -200.0
const ENEMY_SCENE := preload("res://scenes/objects/chunk_enemy.tscn")
const MINIBOSS_MODELS := [
	"res://assets/model/FantasyPack/minibosses/miniboss_cave_guardian.glb",
	"res://assets/model/FantasyPack/minibosses/miniboss_crystal_golem.glb",
	"res://assets/model/FantasyPack/minibosses/miniboss_orc_warlord.glb",
]

var _return_position: Vector3 = Vector3.ZERO
var _cooldown_until_ms: int = 0
var _content: Node3D = null

@onready var exit_area: Area3D = $ExitArea
@onready var spawn_point: Marker3D = $SpawnPoint
@onready var boss_spawn: Marker3D = $BossSpawn


func _ready() -> void:
	exit_area.body_entered.connect(_on_exit_body_entered)
	_decorate()


func _decorate() -> void:
	var pack := "res://assets/model/FantasyPack/"
	for s in [1.0, -1.0]:
		ModelLibrary.place_prop(self, pack + "dungeon/dungeon_pillar.glb", Vector3(7.0 * s, 0, -3.0))
		ModelLibrary.place_prop(self, pack + "dungeon/dungeon_pillar_broken.glb", Vector3(7.5 * s, 0, 5.0))
		ModelLibrary.place_prop(self, pack + "dungeon/brazier.glb", Vector3(4.5 * s, 0, -8.0))
	ModelLibrary.place_prop(self, pack + "cave/bone_pile.glb", Vector3(-3.0, 0, -6.0), 0.8)
	ModelLibrary.place_prop(self, pack + "dungeon/chain_hanging.glb", Vector3(3.0, 7.6, 2.0))


## Teleports the player in and prepares the room for the current dungeon step.
func enter(player: Node3D, return_pos: Vector3, difficulty: float) -> void:
	if Time.get_ticks_msec() < _cooldown_until_ms:
		return
	_cooldown_until_ms = Time.get_ticks_msec() + REENTRY_COOLDOWN_MS
	_return_position = return_pos
	global_position = Vector3(return_pos.x, ARENA_DEPTH, return_pos.z)

	_rebuild_content(difficulty)
	player.global_position = spawn_point.global_position
	if "velocity" in player:
		player.velocity = Vector3.ZERO
	SoundManager.play("portal")


func _rebuild_content(difficulty: float) -> void:
	if _content and is_instance_valid(_content):
		_content.queue_free()
	_content = Node3D.new()
	_content.name = "Content"
	add_child(_content)

	if ProgressionTracker.minibosses_cleared >= 2:
		_spawn_boss_gate()
	else:
		_spawn_miniboss(ProgressionTracker.minibosses_cleared, difficulty)
		StoryManager.trigger_story_event("dungeon_enter")


func _spawn_miniboss(index: int, difficulty: float) -> void:
	var mob := ENEMY_SCENE.instantiate()
	_content.add_child(mob)
	mob.global_position = boss_spawn.global_position
	if "hp" in mob:
		mob.hp = int(320 * difficulty)
	if "damage" in mob:
		mob.damage = int(30 * difficulty)
	if "value" in mob:
		mob.value = int(80 * difficulty)
	if "speed" in mob:
		mob.speed = 2.6
	if "attack_interval" in mob:
		mob.attack_interval = 1.6
	var model_id: int = posmod(ProgressionTracker.cave_portals_cleared + index, MINIBOSS_MODELS.size())
	if mob.has_method("set_mob_visual"):
		mob.set_mob_visual(MINIBOSS_MODELS[model_id])
	mob.scale = Vector3(1.45, 1.45, 1.45)
	if "_death_system" in mob and mob._death_system:
		mob._death_system.death_rewards_callback = _on_miniboss_defeated.bind(mob)


func _on_miniboss_defeated(mob: Node) -> void:
	# The callback replaces the default reward flow — grant XP/gold here.
	var value: int = int(mob.value) if "value" in mob else 50
	ProgressionTracker.add_xp(value)
	var killer = mob.target if "target" in mob else null
	if killer and is_instance_valid(killer) and killer.has_method("player"):
		killer.gold += value
		if killer.has_method("_updateHUD"):
			killer._updateHUD()

	ProgressionTracker.minibosses_cleared += 1
	ProgressionTracker.save_game()
	if ProgressionTracker.minibosses_cleared >= 2:
		_spawn_boss_gate()
		StoryManager.trigger_story_event("dungeon_unlocked")
	else:
		StoryManager.trigger_story_event("dungeon_first_clear")


func _spawn_boss_gate() -> void:
	if _content == null or not is_instance_valid(_content):
		return
	if _content.get_node_or_null("BossGate") != null:
		return
	var gate := BossGate.new()
	gate.name = "BossGate"
	_content.add_child(gate)
	gate.global_position = boss_spawn.global_position
	gate.configure(_return_position)


func _on_exit_body_entered(body: Node3D) -> void:
	if not body.has_method("player"):
		return
	if Time.get_ticks_msec() < _cooldown_until_ms:
		return
	_cooldown_until_ms = Time.get_ticks_msec() + REENTRY_COOLDOWN_MS
	body.global_position = _return_position
	if "velocity" in body:
		body.velocity = Vector3.ZERO
	SoundManager.play("portal")
