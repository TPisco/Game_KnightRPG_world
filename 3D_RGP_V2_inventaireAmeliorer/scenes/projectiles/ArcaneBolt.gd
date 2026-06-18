## Ranged magic projectile for the Arcane Bolt skill.
extends Area3D

const SPEED := 22.0
const LIFETIME := 3.0

var _direction := Vector3.FORWARD
var _damage := 15
var _alive := 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_alive = LIFETIME


func launch(direction: Vector3, damage: int) -> void:
	_direction = direction.normalized()
	_damage = damage


func _physics_process(delta: float) -> void:
	global_position += _direction * SPEED * delta
	_alive -= delta
	if _alive <= 0.0:
		queue_free()


func _on_body_entered(body: Node3D) -> void:
	if body.has_method("enemy") and "hp" in body:
		body.hp -= _damage
		queue_free()
	elif body is StaticBody3D:
		queue_free()
