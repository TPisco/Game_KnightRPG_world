## Boss AI: multi-phase fights extending the base enemy FSM.
class_name BossController
extends "res://scripts/enemy.gd"

signal phase_changed(phase: int)
signal boss_defeated

@export var boss_name: String = "Fractured Guardian"
@export var phase_thresholds: Array[float] = [0.66, 0.33]
@export var loot_item: ItemData

var max_hp: int = 200
var current_phase: int = 1
var _xp_awarded: bool = false
var _attack_cd: float = 0.0


func _ready() -> void:
	max_hp = hp
	add_to_group("enemies")
	add_to_group("bosses")


func enemy() -> void:
	pass


func _process(_delta: float) -> void:
	if hp <= 0 and state != states.die:
		state = states.die
		_on_boss_death()


func _physics_process(delta: float) -> void:
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
	# Override in boss subclasses for unique mechanics.
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


func _on_boss_death() -> void:
	if _xp_awarded:
		return
	_xp_awarded = true
	ProgressionTracker.register_boss_defeat()
	boss_defeated.emit()
	StoryManager.trigger_boss_defeat(boss_name)
	if loot_item and target and target.has_method("player"):
		var handler = target.get_node_or_null("InventoryUI")
		if handler and handler.has_method("pickupItem"):
			handler.pickupItem(loot_item)
	give_Gold()
