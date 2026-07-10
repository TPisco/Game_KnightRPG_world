## Lightweight procedural enemy — same death system as hub goblin.
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
var attack_interval: float = 1.2
var _attack_cd: float = 0.0

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var _death_system: EnemyDeathSystem


func enemy() -> void:
	pass


func _ready() -> void:
	add_to_group("enemies")
	_setup_death_system()
	EnemyHealthBar.attach(self)


## Swaps the placeholder capsule for a FantasyPack model and refits the
## collision capsule + health bar to the model's real size.
func set_mob_visual(model_path: String) -> void:
	var model := ModelLibrary.apply_character_model(self, model_path, true, true)
	if model == null:
		return
	var bar := get_node_or_null("HealthBar")
	if bar and bar.has_method("_compute_top_y"):
		bar.position.y = bar._compute_top_y(self) + 0.45


func _setup_death_system() -> void:
	_death_system = get_node_or_null("EnemyDeathSystem") as EnemyDeathSystem
	if _death_system == null:
		_death_system = EnemyDeathSystem.new()
		_death_system.name = "EnemyDeathSystem"
		add_child(_death_system)
	_death_system.setup(self, animation_player)


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
				_attack_cd = attack_interval
			if animation_player:
				animation_player.play("Punch")

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
