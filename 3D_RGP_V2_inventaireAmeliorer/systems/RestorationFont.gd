## Placeable restoration font: standing near it steadily restores health and
## mana, turning a corner of the hub into a rest area.
class_name RestorationFont
extends Node3D

const HEAL_PER_SECOND := 12.0
const MANA_PER_SECOND := 8.0

var _player: Node = null
var _label: Label3D
var _carry_hp: float = 0.0


func setup(model_path: String) -> void:
	var model := ModelLibrary.spawn(model_path)
	if model:
		add_child(model)
		var aabb := ModelLibrary.measure(model)
		model.position.y = -aabb.position.y

	var glow := OmniLight3D.new()
	glow.light_color = Color(0.5, 1.0, 0.8)
	glow.light_energy = 1.4
	glow.omni_range = 6.0
	glow.position = Vector3(0, 1.2, 0)
	add_child(glow)

	var area := Area3D.new()
	add_child(area)
	var shape := CylinderShape3D.new()
	shape.height = 4.0
	shape.radius = 3.5
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position = Vector3(0, 2.0, 0)
	area.add_child(col)
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

	_label = Label3D.new()
	_label.text = "Restoration Font"
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 26
	_label.outline_size = 8
	_label.modulate = Color(0.6, 1, 0.85)
	_label.position = Vector3(0, 2.4, 0)
	add_child(_label)


func _on_body_entered(body: Node3D) -> void:
	if body.has_method("player"):
		_player = body


func _on_body_exited(body: Node3D) -> void:
	if body == _player:
		_player = null
		_carry_hp = 0.0


func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	# Health is an integer, so accumulate fractional healing between frames.
	_carry_hp += HEAL_PER_SECOND * delta
	var whole := int(_carry_hp)
	if whole > 0 and "hp" in _player and "Maxhp" in _player:
		_carry_hp -= float(whole)
		_player.hp = mini(_player.Maxhp, _player.hp + whole)
		if _player.has_method("_updateHUD"):
			_player._updateHUD()
	if _player.has_method("restore_mana"):
		_player.restore_mana(MANA_PER_SECOND * delta)
