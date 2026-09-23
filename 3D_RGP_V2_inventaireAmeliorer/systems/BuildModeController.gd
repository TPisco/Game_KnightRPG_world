## Home editor for the hub world and the tavern interior.
## Toggle with [B] in any hub scene: pick a furnishing from the catalog, aim
## with the mouse, and place / rotate / move / remove it. Layouts are stored
## per scene in the shared settings file, so they persist for every run.
class_name BuildModeController
extends Node

const GRID_STEP := 0.5
const AIM_RANGE := 120.0
const PICK_RADIUS := 3.0
const HUB_SCENE := "res://scenes/world.tscn"
const TAVERN_SCENE := "res://scenes/world_2.tscn"

# Bird's-eye build camera.
const CAM_PAN_SPEED := 14.0
const CAM_MIN_DIST := 6.0
const CAM_MAX_DIST := 48.0
const CAM_MIN_PITCH := 25.0
const CAM_MAX_PITCH := 87.0

var _player: CharacterBody3D
var _menu: BuildMenu
var _root: Node3D
var _ghost: Node3D
var _selected: Dictionary = {}
var _placed: Array[Node3D] = []

var _active: bool = false
var _snap: bool = true
var _valid: bool = false
var _has_hit: bool = false
var _tinted_valid: bool = true
var _ghost_yaw: float = 0.0
var _hit_pos: Vector3 = Vector3.ZERO
var _hover: Node3D = null

var _build_cam: Camera3D
var _prev_cam: Camera3D
var _cam_pivot: Vector3 = Vector3.ZERO
var _cam_yaw: float = 0.0
var _cam_pitch: float = 62.0
var _cam_dist: float = 20.0
var _orbiting: bool = false

var _mat_valid: StandardMaterial3D
var _mat_invalid: StandardMaterial3D


func setup(player: CharacterBody3D) -> void:
	_player = player


func _ready() -> void:
	_mat_valid = _ghost_material(Color(0.4, 1.0, 0.5, 0.55))
	_mat_invalid = _ghost_material(Color(1.0, 0.35, 0.3, 0.55))

	var scene := get_tree().current_scene
	if scene == null:
		return
	_root = Node3D.new()
	_root.name = "PlayerFurnishings"
	scene.add_child(_root)

	_menu = BuildMenu.new()
	add_child(_menu)
	_menu.entry_selected.connect(_on_entry_selected)
	_menu.travel_requested.connect(_on_travel_requested)
	_menu.exit_requested.connect(toggle)

	_load_layout()


func _ghost_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


# --- Mode ---------------------------------------------------------------

func toggle() -> void:
	if not _active and not HubWorldStartup.is_hub_scene(get_tree().current_scene):
		return  # the editor only exists in the player's own hub
	_active = not _active
	Global.build_mode_active = _active
	if _active:
		_orbiting = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_enter_birds_eye()
		_set_hud_visible(false)
		_menu.open()  # the catalog is open the moment build mode starts
		SoundManager.play("page")
	else:
		_clear_ghost()
		_selected = {}
		_hover = null
		_orbiting = false
		_menu.close()
		_exit_birds_eye()
		_set_hud_visible(true)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# --- Bird's-eye camera --------------------------------------------------

func _enter_birds_eye() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	_prev_cam = _player.get_viewport().get_camera_3d()
	if _build_cam == null or not is_instance_valid(_build_cam):
		_build_cam = Camera3D.new()
		_build_cam.name = "BuildCamera"
		_build_cam.fov = 70.0
		_build_cam.far = 400.0
		get_tree().current_scene.add_child(_build_cam)
	# Start looking down at wherever the knight is standing.
	_cam_pivot = _player.global_position
	_cam_yaw = rad_to_deg(_player.rotation.y)
	_cam_dist = 20.0
	_cam_pitch = 62.0
	_apply_camera()
	_build_cam.current = true
	# The knight stays visible from above as a size reference.
	if _player.has_method("set_body_visible"):
		_player.set_body_visible(true)


func _exit_birds_eye() -> void:
	if _prev_cam and is_instance_valid(_prev_cam):
		_prev_cam.current = true
	if _player and is_instance_valid(_player) and _player.has_method("restore_body_visibility"):
		_player.restore_body_visibility()


func _apply_camera() -> void:
	if _build_cam == null or not is_instance_valid(_build_cam):
		return
	var yaw := deg_to_rad(_cam_yaw)
	var pitch := deg_to_rad(_cam_pitch)
	var offset := Vector3(
		cos(pitch) * sin(yaw), sin(pitch), cos(pitch) * cos(yaw)
	) * _cam_dist
	_build_cam.global_position = _cam_pivot + offset
	_build_cam.look_at(_cam_pivot, Vector3.UP)


## WASD glides the view across the build area, scaled by zoom level.
func _update_camera(delta: float) -> void:
	var move := Input.get_vector("left", "right", "foward", "backward")
	if move != Vector2.ZERO:
		var yaw := deg_to_rad(_cam_yaw)
		var forward := Vector3(-sin(yaw), 0.0, -cos(yaw))
		var right := forward.cross(Vector3.UP)
		var speed := CAM_PAN_SPEED * (_cam_dist / 20.0)
		_cam_pivot += (right * move.x - forward * move.y) * speed * delta
	_apply_camera()


func _set_hud_visible(shown: bool) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var hud := _player.get_node_or_null("HUD") as CanvasLayer
	if hud:
		hud.visible = shown
	var inventory := _player.get_node_or_null("InventoryUI") as Control
	if inventory and not shown:
		inventory.visible = false
	# The hotbar and power panel are separate overlays on the knight.
	for child in _player.get_children():
		if child is Hotbar or child is PowerPanel:
			(child as CanvasLayer).visible = shown


func _on_entry_selected(entry: Dictionary) -> void:
	_selected = entry
	_build_ghost()


func _on_travel_requested(scene_path: String) -> void:
	# Leaving the scene: drop out of build mode cleanly first.
	if _active:
		toggle()
	Global.node_position = "door1"
	Global.rotation = 0
	get_tree().change_scene_to_file(scene_path)


# --- Ghost preview ------------------------------------------------------

func _clear_ghost() -> void:
	if _ghost and is_instance_valid(_ghost):
		_ghost.queue_free()
	_ghost = null


func _build_ghost() -> void:
	_clear_ghost()
	if _selected.is_empty():
		return
	var model := ModelLibrary.spawn(str(_selected["path"]))
	if model == null:
		return
	_ghost = Node3D.new()
	_ghost.visible = false  # shown once the first aim pass positions it
	_root.add_child(_ghost)
	_ghost.add_child(model)
	var aabb := ModelLibrary.measure(model)
	model.position.y = -aabb.position.y
	_disable_collision(_ghost)  # the preview must never block its own aim ray
	_tinted_valid = true
	_tint(_ghost, _mat_valid)


func _disable_collision(node: Node) -> void:
	if node is CollisionObject3D:
		var body := node as CollisionObject3D
		body.collision_layer = 0
		body.collision_mask = 0
	for child in node.get_children():
		_disable_collision(child)


func _tint(node: Node, mat: StandardMaterial3D) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = mat
	for child in node.get_children():
		_tint(child, mat)


func _process(delta: float) -> void:
	if not _active:
		return
	_update_camera(delta)
	_menu.set_status(_status_text())


## Aiming MUST run in the physics step: space-state queries are only valid
## there. Running it in _process() returned empty hits every frame, which is
## what stopped anything from ever being placed.
func _physics_process(_delta: float) -> void:
	if not _active:
		return
	_update_aim()
	_update_ghost()
	_update_hover()


func _update_aim() -> void:
	_has_hit = false
	var cam := _get_camera()
	if cam == null or _player == null or not is_instance_valid(_player):
		return
	var viewport := cam.get_viewport()
	# The cursor is always visible in build mode, so it is the aiming point.
	var point: Vector2 = viewport.get_mouse_position()
	var from: Vector3 = cam.project_ray_origin(point)
	var dir: Vector3 = cam.project_ray_normal(point)
	var params := PhysicsRayQueryParameters3D.create(from, from + dir * AIM_RANGE, 1)
	params.exclude = [_player.get_rid()]
	var hit := cam.get_world_3d().direct_space_state.intersect_ray(params)
	if not hit.is_empty():
		_has_hit = true
		_hit_pos = hit["position"]
		var normal: Vector3 = hit.get("normal", Vector3.UP)
		_valid = normal.y > 0.55
		return

	# Fallback: aim at the ground plane the knight is standing on, so surfaces
	# without collision (or a ray that misses everything) still accept objects.
	var ground := Plane(Vector3.UP, _player.global_position.y - 0.9)
	var plane_hit = ground.intersects_ray(from, dir)
	if plane_hit == null:
		return
	_has_hit = true
	_hit_pos = plane_hit
	_valid = true


func _get_camera() -> Camera3D:
	if _active and _build_cam and is_instance_valid(_build_cam):
		return _build_cam
	if _player == null or not is_instance_valid(_player):
		return null
	var third := _player.get_node_or_null("Head/ThirdPov") as Camera3D
	if third and third.current:
		return third
	return _player.get_node_or_null("FirstPov") as Camera3D


func _update_ghost() -> void:
	if _ghost == null or not is_instance_valid(_ghost):
		return
	if not _has_hit:
		_ghost.visible = false
		_valid = false
		return
	_ghost.visible = true
	var pos := _hit_pos
	if _snap:
		pos.x = snappedf(pos.x, GRID_STEP)
		pos.z = snappedf(pos.z, GRID_STEP)
	_ghost.global_position = pos
	_ghost.rotation.y = deg_to_rad(_ghost_yaw)

	var radius := float(_selected.get("radius", 0.5))
	if _valid and _overlaps(pos, radius):
		_valid = false
	if _valid != _tinted_valid:
		_tinted_valid = _valid
		_tint(_ghost, _mat_valid if _valid else _mat_invalid)


## Keeps furnishings from being stuffed inside each other.
func _overlaps(pos: Vector3, radius: float) -> bool:
	for node in _placed:
		if not is_instance_valid(node):
			continue
		var other := float(node.get_meta("radius", 0.5))
		var flat := Vector2(node.global_position.x - pos.x, node.global_position.z - pos.z)
		if flat.length() < (radius + other) * 0.7:
			return true
	return false


func _update_hover() -> void:
	_hover = null
	if not _has_hit:
		return
	var best := PICK_RADIUS
	for node in _placed:
		if not is_instance_valid(node):
			continue
		var d := node.global_position.distance_to(_hit_pos)
		if d < best:
			best = d
			_hover = node


func _status_text() -> String:
	var lines: Array[String] = []
	if _selected.is_empty():
		lines.append("Pick a furnishing from the catalog to start placing.")
	else:
		var state: String = "ready to place" if _valid else "blocked here"
		lines.append("Placing: %s  (%s)" % [str(_selected.get("name", "?")), state])
	if _hover and is_instance_valid(_hover):
		lines.append("Aiming at: %s   [F] move   [X] remove" % str(_hover.get_meta("display_name", "furnishing")))
	lines.append("[LMB] place   [R] / Shift+wheel rotate   [C] cancel   [G] grid: %s" % ("on" if _snap else "off"))
	lines.append("[WASD] pan view   [wheel] zoom   [RMB drag] turn view   [B]/[Esc] finish")
	return "\n".join(lines)


# --- Input --------------------------------------------------------------

## All build-mode input is handled here rather than in _unhandled_input, so
## placement never depends on how GUI events happen to propagate. Whether the
## cursor is over the catalog is checked explicitly instead.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("build_mode"):
		toggle()
		get_viewport().set_input_as_handled()
		return
	if not _active:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		match (event as InputEventKey).physical_keycode:
			KEY_R:
				_ghost_yaw = wrapf(_ghost_yaw + 45.0, 0.0, 360.0)
			KEY_G:
				_snap = not _snap
			KEY_X:
				_remove_hovered()
			KEY_F:
				_pick_up_hovered()
			KEY_C:
				_cancel_selection()
			KEY_ESCAPE:
				toggle()
			_:
				return
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseMotion:
		if _orbiting:
			var motion := event as InputEventMouseMotion
			_cam_yaw = wrapf(_cam_yaw - motion.relative.x * 0.3, 0.0, 360.0)
			_cam_pitch = clampf(_cam_pitch + motion.relative.y * 0.2, CAM_MIN_PITCH, CAM_MAX_PITCH)
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		# Right button always resolves, so a drag that ends over the catalog
		# cannot leave the view stuck in orbit mode.
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			_orbiting = mb.pressed
			get_viewport().set_input_as_handled()
			return
		if _menu and _menu.blocks_pointer():
			return  # the catalog owns the cursor: let it scroll and click
		match mb.button_index:
			MOUSE_BUTTON_LEFT:
				if mb.pressed:
					_place()
			MOUSE_BUTTON_WHEEL_UP:
				if mb.pressed:
					if mb.shift_pressed:
						_ghost_yaw = wrapf(_ghost_yaw + 15.0, 0.0, 360.0)
					else:
						_cam_dist = clampf(_cam_dist - 2.0, CAM_MIN_DIST, CAM_MAX_DIST)
			MOUSE_BUTTON_WHEEL_DOWN:
				if mb.pressed:
					if mb.shift_pressed:
						_ghost_yaw = wrapf(_ghost_yaw - 15.0, 0.0, 360.0)
					else:
						_cam_dist = clampf(_cam_dist + 2.0, CAM_MIN_DIST, CAM_MAX_DIST)
			_:
				return
		get_viewport().set_input_as_handled()


func _cancel_selection() -> void:
	_clear_ghost()
	_selected = {}
	if _menu:
		_menu.highlight_entry({})


# --- Editing ------------------------------------------------------------

func _place() -> void:
	# _has_hit/_ghost.visible guarantee the preview has been positioned by at
	# least one aim pass, so a very fast click cannot drop an object at origin.
	if _selected.is_empty() or not _valid or not _has_hit \
			or _ghost == null or not is_instance_valid(_ghost) or not _ghost.visible:
		SoundManager.play("deny")
		return
	var node := _spawn_furnishing(_selected, _ghost.global_position, _ghost_yaw)
	if node:
		_placed.append(node)
		_save_layout()
		SoundManager.play("buy")


func _remove_hovered() -> void:
	if _hover == null or not is_instance_valid(_hover):
		return
	_placed.erase(_hover)
	_hover.queue_free()
	_hover = null
	_save_layout()
	SoundManager.play("page")


## Picking up = removing the object and re-arming the ghost with it, so it can
## be re-placed anywhere (and rotated) exactly like a fresh furnishing.
func _pick_up_hovered() -> void:
	if _hover == null or not is_instance_valid(_hover):
		return
	var entry := BuildCatalog.get_entry(str(_hover.get_meta("entry_id", "")))
	if entry.is_empty():
		return
	_ghost_yaw = float(_hover.get_meta("yaw", 0.0))
	_placed.erase(_hover)
	_hover.queue_free()
	_hover = null
	_selected = entry
	_menu.highlight_entry(entry)
	_build_ghost()
	_save_layout()
	SoundManager.play("page")


func _spawn_furnishing(entry: Dictionary, pos: Vector3, yaw: float) -> Node3D:
	var node: Node3D = null
	match str(entry.get("fn", "")):
		"dummy":
			var dummy := TrainingDummy.new()
			_root.add_child(dummy)
			dummy.setup(str(entry["path"]))
			node = dummy
		"font":
			var font := RestorationFont.new()
			_root.add_child(font)
			font.setup(str(entry["path"]))
			node = font
		_:
			var model := ModelLibrary.spawn(str(entry["path"]))
			if model == null:
				return null
			node = Node3D.new()
			_root.add_child(node)
			node.add_child(model)
			var aabb := ModelLibrary.measure(model)
			model.position.y = -aabb.position.y
			if bool(entry.get("solid", false)):
				_add_collision(node, aabb)
			var energy := float(entry.get("light_energy", 0.0))
			if energy > 0.0:
				var light := OmniLight3D.new()
				light.light_color = entry.get("light_color", Color.WHITE)
				light.light_energy = energy
				light.omni_range = 8.0
				light.position = Vector3(0, maxf(aabb.size.y * 0.75, 0.8), 0)
				node.add_child(light)

	node.global_position = pos
	node.rotation.y = deg_to_rad(yaw)
	node.set_meta("entry_id", entry["id"])
	node.set_meta("radius", entry.get("radius", 0.5))
	node.set_meta("yaw", yaw)
	node.set_meta("display_name", entry.get("name", "furnishing"))
	return node


func _add_collision(parent: Node3D, aabb: AABB) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	parent.add_child(body)
	var shape := BoxShape3D.new()
	shape.size = Vector3(
		maxf(aabb.size.x, 0.3), maxf(aabb.size.y, 0.4), maxf(aabb.size.z, 0.3)
	)
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position = Vector3(0, shape.size.y * 0.5, 0)
	body.add_child(col)


# --- Persistence --------------------------------------------------------

func _layout_key() -> String:
	var scene := get_tree().current_scene
	return scene.scene_file_path if scene else ""


func _save_layout() -> void:
	var layouts = SaveManager.settings.get("hub_layouts", {})
	if typeof(layouts) != TYPE_DICTIONARY:
		layouts = {}
	var list: Array = []
	for node in _placed:
		if not is_instance_valid(node):
			continue
		list.append({
			"id": str(node.get_meta("entry_id", "")),
			"x": node.global_position.x,
			"y": node.global_position.y,
			"z": node.global_position.z,
			"yaw": float(node.get_meta("yaw", 0.0)),
		})
	layouts[_layout_key()] = list
	SaveManager.settings["hub_layouts"] = layouts
	SaveManager.save_settings()


func _load_layout() -> void:
	var layouts = SaveManager.settings.get("hub_layouts", {})
	if typeof(layouts) != TYPE_DICTIONARY:
		return
	var list = layouts.get(_layout_key(), [])
	if not (list is Array):
		return
	for item in list:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var entry := BuildCatalog.get_entry(str(item.get("id", "")))
		if entry.is_empty():
			continue
		var pos := Vector3(
			float(item.get("x", 0.0)), float(item.get("y", 0.0)), float(item.get("z", 0.0))
		)
		var node := _spawn_furnishing(entry, pos, float(item.get("yaw", 0.0)))
		if node:
			_placed.append(node)
