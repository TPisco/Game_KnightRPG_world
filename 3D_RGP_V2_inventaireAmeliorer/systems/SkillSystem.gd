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
	if ProgressionTracker.is_skill_unlocked(skill_id):
		active_skill = skill_id


func is_on_cooldown(skill_id: String = "") -> bool:
	var id := skill_id if skill_id != "" else active_skill
	return _cooldowns.get(id, 0.0) > 0.0


func get_cooldown_remaining(skill_id: String = "") -> float:
	var id := skill_id if skill_id != "" else active_skill
	return _cooldowns.get(id, 0.0)


func activate_skill() -> bool:
	if not _player or active_skill == "":
		return false
	if not ProgressionTracker.is_skill_unlocked(active_skill):
		return false
	if is_on_cooldown():
		return false
	var stamina_cost: float = SKILL_STAMINA_COSTS.get(active_skill, 20.0)
	if _player.has_method("spend_stamina") and not _player.spend_stamina(stamina_cost):
		return false

	match active_skill:
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

	_start_cooldown(active_skill)
	skill_activated.emit(active_skill)
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
	var mult: float = ProgressionTracker.get_player_stats().get("skill_cooldown_mult", 1.0)
	_cooldowns[skill_id] = base_cd * mult


func _use_power_slash() -> void:
	if _animations:
		_animations.play("swordswing")
	var stats: Dictionary = ProgressionTracker.get_player_stats()
	var dmg: int = int(stats["damage"] * 1.8)
	_damage_enemies_in_radius(4.0, dmg)


func _use_arcane_bolt() -> void:
	var bolt := ARCANE_BOLT_SCENE.instantiate()
	_player.get_parent().add_child(bolt)
	var forward := -_player.global_transform.basis.z
	bolt.global_position = _player.global_position + Vector3(0, 1.2, 0)
	if bolt.has_method("launch"):
		var stats: Dictionary = ProgressionTracker.get_player_stats()
		bolt.launch(forward, int(stats["damage"] * 1.5))


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
		if "hp" in node and node.hp > 0:
			node.hp -= damage
			total_heal += int(damage * 0.25)
	return total_heal
