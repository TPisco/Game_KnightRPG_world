## World loot pickup — weapons, armor, consumables. Walk over to collect.
extends Area3D

@export var loot_data: ItemData

var _picked: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	collision_layer = 2
	collision_mask = 1
	if loot_data:
		_build_visual()


func set_loot(data: ItemData) -> void:
	loot_data = data
	if is_inside_tree():
		_build_visual()


func _build_visual() -> void:
	for child in get_children():
		if child.name == "Visual":
			child.queue_free()

	if loot_data == null:
		return

	var root := Node3D.new()
	root.name = "Visual"
	add_child(root)

	var mesh_inst := MeshInstance3D.new()
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	mat.cull_mode = BaseMaterial3D.CULL_BACK

	match loot_data.item_type:
		"weapon":
			var box := BoxMesh.new()
			box.size = Vector3(0.15, 0.6, 0.08)
			mesh_inst.mesh = box
			mesh_inst.rotation_degrees = Vector3(0, 45, -30)
			mat.albedo_color = Color(0.75, 0.75, 0.8)
			mat.metallic = 0.7
			mat.roughness = 0.35
		"armor":
			var box := BoxMesh.new()
			box.size = Vector3(0.55, 0.65, 0.1)
			mesh_inst.mesh = box
			mat.albedo_color = Color(0.45, 0.3, 0.15)
			mat.roughness = 0.8
		"consumable":
			var sphere := SphereMesh.new()
			sphere.radius = 0.2
			sphere.height = 0.35
			mesh_inst.mesh = sphere
			mat.albedo_color = Color(0.9, 0.2, 0.2)
			mat.emission_enabled = true
			mat.emission = Color(0.8, 0.1, 0.1)
			mat.emission_energy_multiplier = 0.6
		_:
			var cube := BoxMesh.new()
			cube.size = Vector3(0.4, 0.4, 0.4)
			mesh_inst.mesh = cube
			mat.albedo_color = Color(0.55, 0.2, 0.85)
			mat.emission_enabled = true
			mat.emission = Color(0.4, 0.1, 0.7)
			mat.emission_energy_multiplier = 1.2

	mat.albedo_color.a = 1.0
	mesh_inst.material_override = mat
	root.add_child(mesh_inst)

	# Floating bob animation target
	var tween := create_tween().set_loops()
	tween.tween_property(root, "position:y", 0.15, 0.8).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(root, "position:y", 0.0, 0.8).set_ease(Tween.EASE_IN_OUT)

	if not has_node("CollisionShape3D"):
		var col := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 0.9
		col.shape = shape
		add_child(col)


func _on_body_entered(body: Node3D) -> void:
	if _picked or loot_data == null:
		return
	if not body.has_method("player"):
		return
	_picked = true

	if loot_data.item_type == "consumable":
		var heal: int = int(loot_data.stat_bonuses.get("heal", 25))
		body.hp = mini(body.Maxhp, body.hp + heal)
		body._updateHUD()
	else:
		var inv = body.get_node_or_null("InventoryUI")
		if inv and inv.has_method("pickupItem"):
			inv.pickupItem(loot_data)

	queue_free()
