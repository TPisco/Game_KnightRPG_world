## Lightweight procedural enemy — no NavMesh bake required.
extends CharacterBody3D

enum states {attack, idle, chase, die}

var state = states.idle
var hp = 20
var speed = 2.0
var accel = 10.0
var gravity = 9.8
var target = null
var damage = 15
var value = 10
var _xp_given: bool = false
var _gold_given: bool = false
var _attack_cd: float = 0.0

@onready var animation_player: AnimationPlayer = $AnimationPlayer


func enemy() -> void:
	pass


func _ready() -> void:
	add_to_group("enemies")


func _process(_delta: float) -> void:
	if hp <= 0:
		state = states.die
		_award_xp_once()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	match state:
		states.idle:
			velocity.x = 0.0
			velocity.z = 0.0
			if animation_player:
				animation_player.play("Idle")
		states.chase:
			if target:
				look_at(Vector3(target.global_position.x, global_position.y, target.global_position.z), Vector3.UP, true)
				var direction: Vector3 = target.global_position - global_position
				direction.y = 0.0
				direction = direction.normalized()
				velocity.x = lerp(velocity.x, direction.x * speed, accel * delta)
				velocity.z = lerp(velocity.z, direction.z * speed, accel * delta)
			if animation_player:
				animation_player.play("Walk")
		states.attack:
			if target:
				look_at(Vector3(target.global_position.x, global_position.y, target.global_position.z), Vector3.UP, true)
			velocity = Vector3.ZERO
			_attack_cd -= delta
			if _attack_cd <= 0.0 and target:
				attack()
				_attack_cd = 1.2
			if animation_player:
				animation_player.play("Punch")
		states.die:
			velocity = Vector3.ZERO
			if not _gold_given:
				_gold_given = true
				give_Gold()
			if animation_player:
				animation_player.play("Die")

	move_and_slide()


func attack() -> void:
	if target == null:
		return
	if target.has_method("take_damage"):
		target.take_damage(damage)
		return
	var guard_mult := ProgressionTracker.get_guard_damage_multiplier()
	if target.isGuarding:
		target.hp -= damage * guard_mult
	else:
		target.hp -= damage
	target._updateHUD()


func show_damage_number(amount: int) -> void:
	CombatFeedback.spawn_damage_number(global_position + Vector3(0, 1.5, 0), amount, Color(1.0, 0.85, 0.3))


func give_Gold() -> void:
	if target:
		target.gold += value
		target._updateHUD()


func _award_xp_once() -> void:
	if _xp_given:
		return
	_xp_given = true
	ProgressionTracker.add_xp(value)


func _on_chase_area_body_entered(body: Node3D) -> void:
	if body.has_method("player") and state != states.die:
		target = body
		state = states.chase


func _on_chase_area_body_exited(body: Node3D) -> void:
	if body.has_method("player") and state != states.die:
		target = null
		state = states.idle


func _on_attack_area_body_entered(body: Node3D) -> void:
	if body.has_method("player") and state != states.die:
		state = states.attack


func _on_attack_area_body_exited(body: Node3D) -> void:
	if body.has_method("player") and state != states.die:
		state = states.chase
