#enemy — base FSM; death handled by EnemyDeathSystem (same as goblin flow).
extends CharacterBody3D

enum states {attack, idle, chase, die}

var state = states.idle
var hp = 20
var speed = 2
var accel = 10
var gravity = 9.8
var target = null
var damage = 20
var value = 15

@export var navAgent: NavigationAgent3D
@export var animationPlayer: AnimationPlayer

var _death_system: EnemyDeathSystem


func enemy() -> void:
	pass


func _ready() -> void:
	add_to_group("enemies")
	_setup_death_system()
	EnemyHealthBar.attach(self)


func _setup_death_system() -> void:
	_death_system = get_node_or_null("EnemyDeathSystem") as EnemyDeathSystem
	if _death_system == null:
		_death_system = EnemyDeathSystem.new()
		_death_system.name = "EnemyDeathSystem"
		add_child(_death_system)
	_death_system.setup(self, animationPlayer)


func show_damage_number(amount: int) -> void:
	CombatFeedback.spawn_damage_number(global_position + Vector3(0, 1.5, 0), amount, Color(1.0, 0.85, 0.3))


func take_damage(amount: int) -> void:
	if state == states.die:
		return
	hp -= amount
	show_damage_number(amount)
	if hp <= 0:
		_enter_death_state()


func _enter_death_state() -> void:
	if state == states.die:
		return
	state = states.die
	_death_system.begin_death()


func _process(_delta: float) -> void:
	if hp <= 0 and state != states.die:
		_enter_death_state()


func _physics_process(delta: float) -> void:
	if state == states.die:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y -= gravity * delta

	if state == states.idle:
		velocity = Vector3(0, velocity.y, 0)
		if animationPlayer:
			animationPlayer.play("Idle")
	elif state == states.chase:
		if target:
			look_at(Vector3(target.global_position.x, target.global_position.y, target.global_position.z), Vector3.UP, true)
			navAgent.target_position = target.global_position
			var direction: Vector3 = navAgent.get_next_path_position() - global_position
			if direction.length() < 0.1:
				direction = target.global_position - global_position
			direction.y = 0.0
			direction = direction.normalized()
			velocity = velocity.lerp(direction * speed, accel * delta)
		if animationPlayer:
			animationPlayer.play("Walk")
	elif state == states.attack:
		if target:
			look_at(Vector3(target.global_position.x, target.global_position.y, target.global_position.z), Vector3.UP, true)
		if animationPlayer:
			animationPlayer.play("Punch")
		velocity = Vector3.ZERO

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


func give_Gold() -> void:
	if target:
		target.gold += value
		target._updateHUD()


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
