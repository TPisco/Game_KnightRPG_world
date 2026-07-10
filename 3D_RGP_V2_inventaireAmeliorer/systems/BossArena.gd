## Shared real-boss arena: spawns the current realm's boss on entry. The boss's
## own death flow spawns the next-world portal inside this room.
class_name BossArena
extends Node3D

const REENTRY_COOLDOWN_MS := 1800
const ARENA_DEPTH := -260.0

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
		ModelLibrary.place_prop(self, pack + "dungeon/dungeon_pillar.glb", Vector3(11.0 * s, 0, -6.0))
		ModelLibrary.place_prop(self, pack + "dungeon/dungeon_pillar.glb", Vector3(11.0 * s, 0, 6.0))
		ModelLibrary.place_prop(self, pack + "dungeon/brazier.glb", Vector3(7.0 * s, 0, -11.0))
		ModelLibrary.place_prop(self, pack + "dungeon/brazier.glb", Vector3(7.0 * s, 0, 11.0))
	ModelLibrary.place_prop(self, pack + "dungeon/chain_hanging.glb", Vector3(-4.0, 11.5, 0.0))
	ModelLibrary.place_prop(self, pack + "dungeon/chain_hanging.glb", Vector3(5.0, 11.5, -4.0))


func enter(player: Node3D, return_pos: Vector3) -> void:
	if Time.get_ticks_msec() < _cooldown_until_ms:
		return
	_cooldown_until_ms = Time.get_ticks_msec() + REENTRY_COOLDOWN_MS
	_return_position = return_pos
	global_position = Vector3(return_pos.x, ARENA_DEPTH, return_pos.z)

	_rebuild_content()
	player.global_position = spawn_point.global_position
	if "velocity" in player:
		player.velocity = Vector3.ZERO
	SoundManager.play("portal")
	StoryManager.trigger_boss_warning()


func _rebuild_content() -> void:
	if _content and is_instance_valid(_content):
		_content.queue_free()
	_content = Node3D.new()
	_content.name = "Content"
	add_child(_content)

	var boss_scene := BossRegistry.get_boss_scene_for_realm(ProgressionTracker.cave_portals_cleared)
	if boss_scene == null:
		return
	var boss := boss_scene.instantiate()
	_content.add_child(boss)
	boss.global_position = boss_spawn.global_position

	var boss_ui = get_tree().current_scene.get_node_or_null("BossUI")
	if boss_ui and boss_ui.has_method("register_boss"):
		boss_ui.register_boss(boss)


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
