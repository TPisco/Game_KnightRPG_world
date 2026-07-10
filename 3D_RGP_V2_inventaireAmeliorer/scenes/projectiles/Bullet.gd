## Physical gun projectile — fast, flat-damage tracer round.
extends Area3D

const SPEED := 48.0
const LIFETIME := 1.6

var _direction := Vector3.FORWARD
var _damage := 10
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
	if body.has_method("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(_damage)
		elif "hp" in body:
			body.hp -= _damage
			if body.has_method("show_damage_number"):
				body.show_damage_number(_damage)
		queue_free()
	elif body is StaticBody3D:
		queue_free()
