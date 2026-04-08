#enemy
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



@export var navAgent : NavigationAgent3D
@export var animationPlayer : AnimationPlayer

func enemy():
	pass

func _process(delta: float) -> void:
	if hp <=0:
		state = states.die

func _physics_process(delta: float) -> void:
	if not  is_on_floor():
		velocity.y -= gravity * delta
	 
		
	if state == states.idle:
		velocity = Vector3(0,velocity.y,0)
		animationPlayer.play("Idle")
	elif state == states.chase :
		look_at(Vector3(target.global_position.x, target.global_position.y,target.global_position.z),Vector3.UP, true)
		navAgent.target_position = target.global_position
		
		var direction = navAgent.get_next_path_position() - global_position
		direction = direction.normalized()
		
		velocity = velocity.lerp(direction * speed, accel * delta)
		animationPlayer.play("Walk")
		
	elif state == states.attack:
		look_at(Vector3(target.global_position.x, target.global_position.y,target.global_position.z),Vector3.UP, true)
		animationPlayer.play("Punch")
		velocity = Vector3.ZERO
	elif state == states.die:
		animationPlayer.play("Die")
		velocity = Vector3.ZERO
	
	move_and_slide()

func attack():
	if target.isGuarding == true:
		target.hp -= damage * 0.1
		target._updateHUD()
	else :
		target.hp -= damage
		target._updateHUD()

func give_Gold():
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
