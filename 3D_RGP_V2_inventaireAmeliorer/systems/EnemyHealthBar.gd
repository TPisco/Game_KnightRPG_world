## Floating billboard health bar shown above every mob.
## Reads the host's `hp` each frame; hides itself when the host dies.
class_name EnemyHealthBar
extends Node3D

const BAR_WIDTH := 0.9
const BAR_HEIGHT := 0.11

var _host: Node3D
var _max_hp: float = 1.0
var _fill: MeshInstance3D


## Creates a bar above `host`, placed just over its body collision capsule.
static func attach(host: Node3D) -> EnemyHealthBar:
	var bar := EnemyHealthBar.new()
	bar.name = "HealthBar"
	bar._host = host
	host.add_child(bar)
	bar.position = Vector3(0, bar._compute_top_y(host) + 0.45, 0)
	return bar


func _compute_top_y(host: Node3D) -> float:
	for child in host.get_children():
		if child is CollisionShape3D:
			var col := child as CollisionShape3D
			var shape := col.shape
			if shape is CapsuleShape3D:
				return col.position.y + (shape as CapsuleShape3D).height * 0.5
			if shape is BoxShape3D:
				return col.position.y + (shape as BoxShape3D).size.y * 0.5
	return 1.8


func _ready() -> void:
	_build_quad(Color(0.08, 0.08, 0.1, 0.85), BAR_WIDTH, 0)
	_fill = _build_quad(Color(0.85, 0.15, 0.12, 0.95), BAR_WIDTH - 0.06, 1)
	if _host and "hp" in _host:
		_max_hp = maxf(1.0, float(_host.hp))


func _build_quad(color: Color, width: float, priority: int) -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = Vector2(width, BAR_HEIGHT if priority == 0 else BAR_HEIGHT - 0.04)
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.billboard_keep_scale = true
	mat.render_priority = priority
	mesh_inst.material_override = mat
	mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh_inst)
	return mesh_inst


func _process(_delta: float) -> void:
	if _host == null or not is_instance_valid(_host) or not ("hp" in _host):
		visible = false
		return
	var hp := float(_host.hp)
	if hp > _max_hp:
		_max_hp = hp  # stats were assigned after spawn
	if hp <= 0.0:
		visible = false
		return
	visible = true
	var ratio: float = clampf(hp / _max_hp, 0.0, 1.0)
	if _fill:
		_fill.scale = Vector3(ratio, 1.0, 1.0)
		# Tint from red to green-ish depending on remaining health.
		var mat := _fill.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color = Color(0.85, 0.15, 0.12).lerp(Color(0.25, 0.8, 0.2), ratio)
