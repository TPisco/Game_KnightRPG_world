## Boss AI: multi-phase fights extending the base enemy FSM.
class_name BossController
extends "res://scripts/enemy.gd"

signal phase_changed(phase: int)
signal boss_defeated

const PORTAL_SCENE := preload("res://scenes/world/cave_portal.tscn")

@export var boss_name: String = "Fractured Guardian"
@export var phase_thresholds: Array[float] = [0.66, 0.33]
@export var loot_item: ItemData
@export var spawns_portal_on_death: bool = true

var max_hp: int = 200
var current_phase: int = 1
var _xp_awarded: bool = false
var _attack_cd: float = 0.0


func _ready() -> void:
	super._ready()
	max_hp = hp
	add_to_group("bosses")
	if _death_system:
		_death_system.death_rewards_callback = _on_boss_death_rewards
		if loot_item:
			_death_system.loot_item = loot_item


func _physics_process(delta: float) -> void:
	if state == states.die:
		super._physics_process(delta)
		return
	_update_phase()
	super._physics_process(delta)
	_attack_cd = maxf(0.0, _attack_cd - delta)

	if state == states.chase:
		speed = 2.0 + current_phase * 0.5
	elif state == states.attack:
		if _attack_cd <= 0.0 and target:
			_perform_attack()
			_attack_cd = 1.4 - current_phase * 0.1
		if current_phase >= 2:
			_try_slam_attack()


func _perform_attack() -> void:
	attack()


func _update_phase() -> void:
	if hp <= 0:
		return
	var ratio := float(hp) / float(max_hp)
	var new_phase := 1
	if phase_thresholds.size() > 1 and ratio <= phase_thresholds[1]:
		new_phase = 3
	elif phase_thresholds.size() > 0 and ratio <= phase_thresholds[0]:
		new_phase = 2
	if new_phase != current_phase:
		current_phase = new_phase
		phase_changed.emit(current_phase)
		damage = 20 + current_phase * 8
		speed = 2.0 + current_phase * 0.5
		_on_phase_changed(current_phase)


func _on_phase_changed(_phase: int) -> void:
	pass


func _try_slam_attack() -> void:
	if target == null:
		return
	if target.global_position.distance_to(global_position) < 5.0:
		var dmg := int(damage * 1.5)
		if target.isGuarding:
			dmg = int(damage * ProgressionTracker.get_guard_damage_multiplier())
		if target.has_method("take_damage"):
			target.take_damage(dmg)
		elif "hp" in target:
			target.hp -= dmg
			target._updateHUD()


func _on_boss_death_rewards() -> void:
	if _xp_awarded:
		return
	_xp_awarded = true
	ProgressionTracker.register_boss_defeat()
	boss_defeated.emit()
	StoryManager.trigger_boss_defeat(boss_name)
	give_Gold()
	if spawns_portal_on_death:
		_spawn_progress_portal()


func _spawn_progress_portal() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var portal := PORTAL_SCENE.instantiate()
	parent.add_child(portal)
	# Place the portal just behind where the boss stood.
	var behind := -global_transform.basis.z.normalized()
	portal.global_position = global_position + behind * 3.0 + Vector3(0, 1.0, 0)
	var world_gen := get_tree().current_scene.get_node_or_null("WorldGenerator")
	if portal.has_method("configure"):
		portal.configure(world_gen, null)
	if portal.has_method("enable_portal"):
		portal.call_deferred("enable_portal")
