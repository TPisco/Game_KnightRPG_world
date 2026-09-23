## Placeable training dummy: takes hits from every weapon and power, reports
## the damage it soaked, and resets itself instead of dying.
class_name TrainingDummy
extends StaticBody3D

const MAX_HP := 500

var hp: int = MAX_HP
var mob_id: String = "Training Dummy"  # never registered — it cannot die

var _label: Label3D
var _total_damage: int = 0
var _last_hit: int = 0


## Required so the knight's attack zone and projectiles recognise it.
func enemy() -> void:
	pass


func setup(model_path: String) -> void:
	add_to_group("enemies")  # so area-of-effect powers also strike it

	var model := ModelLibrary.spawn(model_path)
	if model:
		add_child(model)
		var aabb := ModelLibrary.measure(model)
		model.position.y = -aabb.position.y
		model.rotation.y = PI

	var shape := BoxShape3D.new()
	shape.size = Vector3(1.3, 2.2, 1.3)
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position = Vector3(0, 1.1, 0)
	add_child(col)

	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 28
	_label.outline_size = 8
	_label.modulate = Color(1, 0.9, 0.6)
	_label.position = Vector3(0, 2.6, 0)
	add_child(_label)
	_refresh_label()


func take_damage(amount: int) -> void:
	hp -= amount
	_last_hit = amount
	_total_damage += amount
	show_damage_number(amount)
	if hp <= 0:
		hp = MAX_HP
		if _label:
			_label.modulate = Color(0.5, 1, 0.6)
			var tween := create_tween()
			tween.tween_interval(0.4)
			tween.tween_callback(func():
				if is_instance_valid(_label):
					_label.modulate = Color(1, 0.9, 0.6))
	_refresh_label()


func show_damage_number(amount: int) -> void:
	CombatFeedback.spawn_damage_number(global_position + Vector3(0, 1.8, 0), amount, Color(1, 0.85, 0.3))


func _refresh_label() -> void:
	if _label == null:
		return
	_label.text = "Training Dummy\nHP %d/%d\nLast hit: %d   Total: %d" % [
		hp, MAX_HP, _last_hit, _total_damage
	]
