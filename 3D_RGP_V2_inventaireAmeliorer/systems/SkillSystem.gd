## Ability registry, cooldowns, stamina costs, and activation for the knight.
class_name SkillSystem
extends Node

signal skill_activated(skill_id: String)

const SKILL_COOLDOWNS := {
	"power_slash": 4.0,
	"arcane_bolt": 3.0,
	"iron_wall": 6.0,
	"life_drain": 8.0,
}

const SKILL_STAMINA_COSTS := {
	"power_slash": 15.0,
	"arcane_bolt": 20.0,
	"iron_wall": 25.0,
	"life_drain": 30.0,
}

const SKILL_DATABASE := [
	{"id": "power_slash", "name": "Power Slash", "type": "strength", "cost": 15, "effect": "aoe_damage"},
	{"id": "arcane_bolt", "name": "Arcane Bolt", "type": "magic", "cost": 20, "effect": "spawn_projectile"},
	{"id": "iron_wall", "name": "Iron Wall", "type": "defense", "cost": 25, "effect": "damage_reduction"},
	{"id": "life_drain", "name": "Life Drain", "type": "hybrid", "cost": 30, "effect": "lifesteal"},
]

@export var active_skill: String = "power_slash"

var _player: CharacterBody3D
var _animations: AnimationPlayer
var _cooldowns: Dictionary = {}
var _iron_wall_timer: float = 0.0

const ARCANE_BOLT_SCENE := preload("res://scenes/projectiles/ArcaneBolt.tscn")


func setup(player: CharacterBody3D, animations: AnimationPlayer) -> void:
	_player = player
	_animations = animations
	if active_skill == "" and ProgressionTracker.unlocked_skills.size() > 0:
		active_skill = ProgressionTracker.unlocked_skills[0]


func _process(delta: float) -> void:
	for skill_id in _cooldowns.keys():
		_cooldowns[skill_id] = maxf(0.0, _cooldowns[skill_id] - delta)
	if _iron_wall_timer > 0.0:
		_iron_wall_timer -= delta
		if _iron_wall_timer <= 0.0 and _player:
			_player.isGuarding = false
			if _animations:
				_animations.play("RESET")


func set_active_skill(skill_id: String) -> void:
	if Global.hub_test_mode or ProgressionTracker.is_skill_unlocked(skill_id):
		active_skill = skill_id


func grant_all_skills() -> void:
	for entry in SKILL_DATABASE:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var skill_id: String = entry.get("id", "")
		if skill_id != "" and skill_id not in ProgressionTracker.unlocked_skills:
			ProgressionTracker.unlocked_skills.append(skill_id)
	if active_skill == "" and ProgressionTracker.unlocked_skills.size() > 0:
		active_skill = ProgressionTracker.unlocked_skills[0]


func is_on_cooldown(skill_id: String = "") -> bool:
	var id := skill_id if skill_id != "" else active_skill
	return _cooldowns.get(id, 0.0) > 0.0


func get_cooldown_remaining(skill_id: String = "") -> float:
	var id := skill_id if skill_id != "" else active_skill
	return _cooldowns.get(id, 0.0)


## Casts a specific power (defaults to the selected active skill), so every
## unlocked power stays usable at once through its own hotkey.
func activate_skill(skill_id: String = "") -> bool:
	var id := skill_id if skill_id != "" else active_skill
	if not _player or id == "":
		return false
	if not Global.hub_test_mode and not ProgressionTracker.is_skill_unlocked(id):
		return false
	if is_on_cooldown(id):
		return false
	var stamina_cost: float = 0.0 if Global.hub_test_mode else SKILL_STAMINA_COSTS.get(id, 20.0)
	if stamina_cost > 0.0 and _player.has_method("spend_stamina") and not _player.spend_stamina(stamina_cost):
		return false

	match id:
		"power_slash":
			_use_power_slash()
		"arcane_bolt":
			_use_arcane_bolt()
		"iron_wall":
			_use_iron_wall()
		"life_drain":
			_use_life_drain()
		_:
			return false

	_start_cooldown(id)
	SoundManager.play("skill")
	skill_activated.emit(id)
	return true


func handle_guard_input(pressed: bool) -> bool:
	# Iron wall uses the guard animation; other skills activate on press.
	if pressed and active_skill != "iron_wall":
		return activate_skill()
	if active_skill == "iron_wall" and pressed:
		return activate_skill()
	return false


func _start_cooldown(skill_id: String) -> void:
	var base_cd: float = SKILL_COOLDOWNS.get(skill_id, 5.0)
	if Global.hub_test_mode:
		base_cd *= 0.25
	var mult: float = ProgressionTracker.get_player_stats().get("skill_cooldown_mult", 1.0)
	_cooldowns[skill_id] = base_cd * mult


func _use_power_slash() -> void:
	if _animations:
		_animations.play("swordswing")
	var stats: Dictionary = ProgressionTracker.get_player_stats()
	var dmg: int = int(stats["damage"] * 1.8)
	_damage_enemies_in_radius(4.0, dmg)


func _use_arcane_bolt() -> void:
	var cam := _get_aim_camera()
	if cam == null:
		return
	var bolt := ARCANE_BOLT_SCENE.instantiate()
	_player.get_parent().add_child(bolt)
	var forward := -cam.global_transform.basis.z.normalized()
	var spawn_pos := cam.global_position + forward * 0.75
	bolt.global_position = spawn_pos
	if bolt is Node3D:
		(bolt as Node3D).look_at(spawn_pos + forward, Vector3.UP)
	if bolt.has_method("launch"):
		var stats: Dictionary = ProgressionTracker.get_player_stats()
		bolt.launch(forward, int(stats["damage"] * 1.5))


func _get_aim_camera() -> Camera3D:
	if _player == null:
		return null
	var first := _player.get_node_or_null("FirstPov") as Camera3D
	var third := _player.get_node_or_null("Head/ThirdPov") as Camera3D
	if third and third.current:
		return third
	if first and first.current:
		return first
	return first if first else third


func _use_iron_wall() -> void:
	if _animations:
		_animations.play("Guard")
	_player.isGuarding = true
	_iron_wall_timer = 3.0 + ProgressionTracker.defense * 0.2


func _use_life_drain() -> void:
	var stats: Dictionary = ProgressionTracker.get_player_stats()
	var dmg: int = int(stats["damage"] * 1.2 + ProgressionTracker.magic * 2)
	var healed := _damage_enemies_in_radius(5.0, dmg)
	_player.hp = mini(_player.Maxhp, _player.hp + healed)
	_player._updateHUD()


func _damage_enemies_in_radius(radius: float, damage: int) -> int:
	var total_heal := 0
	for node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(node):
			continue
		if node.global_position.distance_to(_player.global_position) > radius:
			continue
		if node.has_method("take_damage"):
			node.take_damage(damage)
			total_heal += int(damage * 0.25)
		elif "hp" in node and node.hp > 0:
			node.hp -= damage
			total_heal += int(damage * 0.25)
	return total_heal
