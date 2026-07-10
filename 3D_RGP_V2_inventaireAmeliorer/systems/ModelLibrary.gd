## Runtime model helper for the FantasyPack GLB assets.
## Loads scenes safely (fallback-friendly), measures them, swaps character
## placeholder visuals, and resizes collision capsules to fit the new model.
## Pack conventions: 1 unit = 1 m, characters face -Z, origins at the feet.
extends Node
class_name ModelLibrary

static var _cache: Dictionary = {}


static func exists(path: String) -> bool:
	return ResourceLoader.exists(path)


static func spawn(path: String) -> Node3D:
	if not ResourceLoader.exists(path):
		return null
	var scene: PackedScene = _cache.get(path)
	if scene == null:
		scene = load(path)
		if scene == null:
			return null
		_cache[path] = scene
	var node := scene.instantiate()
	return node as Node3D


## Merged world-space-less AABB of every mesh in the model (local space).
static func measure(model: Node3D) -> AABB:
	var merged := AABB()
	var first := true
	var stack: Array[Node] = [model]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.append(child)
		if node is MeshInstance3D:
			var mesh_inst := node as MeshInstance3D
			var aabb := mesh_inst.get_aabb()
			# Transform into the model root's space.
			var xform := mesh_inst.transform
			var parent := mesh_inst.get_parent()
			while parent != null and parent != model and parent is Node3D:
				xform = (parent as Node3D).transform * xform
				parent = parent.get_parent()
			aabb = xform * aabb
			if first:
				merged = aabb
				first = false
			else:
				merged = merged.merge(aabb)
	return merged


## Replaces a character's placeholder visuals with a pack model.
## - hides direct MeshInstance3D children and any child named "Visual"
## - adds the model (flipped 180° for enemies whose "model front" is +Z)
## - optionally resizes the body capsule so the hitbox matches the model
## Returns the model node, or null if the asset is unavailable.
static func apply_character_model(host: Node3D, path: String, flip: bool = true, resize_collision: bool = true) -> Node3D:
	var model := spawn(path)
	if model == null:
		return null

	for child in host.get_children():
		if child is MeshInstance3D or child.name == "Visual":
			(child as Node3D).visible = false

	model.name = "PackModel"
	host.add_child(model)
	var aabb := measure(model)
	# Feet on the ground even if the origin is slightly off.
	model.position = Vector3(0, -aabb.position.y + 0.02, 0)
	if flip:
		model.rotation.y = PI

	if resize_collision and aabb.size.y > 0.1:
		var height := aabb.size.y
		var radius: float = clampf(maxf(aabb.size.x, aabb.size.z) * 0.35, 0.25, height * 0.45)
		for child in host.get_children():
			if child is CollisionShape3D:
				var capsule := CapsuleShape3D.new()
				capsule.height = maxf(height, radius * 2.1)
				capsule.radius = radius
				(child as CollisionShape3D).shape = capsule
				(child as CollisionShape3D).position = Vector3(0, height * 0.5 + 0.02, 0)
				(child as CollisionShape3D).rotation = Vector3.ZERO
				break
	return model


## Decorative prop: spawn at a local position under a parent (no collision).
static func place_prop(parent: Node3D, path: String, local_pos: Vector3, yaw: float = 0.0, scale: float = 1.0) -> Node3D:
	var prop := spawn(path)
	if prop == null:
		return null
	parent.add_child(prop)
	prop.position = local_pos
	prop.rotation.y = yaw
	if scale != 1.0:
		prop.scale = Vector3.ONE * scale
	return prop
