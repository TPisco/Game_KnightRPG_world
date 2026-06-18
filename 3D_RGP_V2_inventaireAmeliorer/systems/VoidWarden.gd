## Boss #3 — void pulses that punish players who stay close.
extends "res://systems/BossController.gd"

var _pulse_timer: float = 3.0


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if hp <= 0:
		return
	if current_phase < 2:
		return
	_pulse_timer -= delta
	if _pulse_timer <= 0.0:
		_void_pulse()
		_pulse_timer = 4.0 - current_phase * 0.5


func _void_pulse() -> void:
	if target == null or not target.has_method("player"):
		return
	var radius := 8.0 if current_phase < 3 else 12.0
	if target.global_position.distance_to(global_position) > radius:
		return
	var dmg := int(damage * (1.2 if current_phase < 3 else 1.8))
	if target.isGuarding:
		target.hp -= int(dmg * ProgressionTracker.get_guard_damage_multiplier())
	else:
		target.hp -= dmg
	target._updateHUD()
