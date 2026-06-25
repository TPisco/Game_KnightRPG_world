## Interactive portal spawned when a Cave Guardian dies.
class_name CavePortal
extends Node3D

const ENTER_COOLDOWN := 1.5

var is_active: bool = false
var world_index: int = 0

var _world_generator: Node = null
var _owner_chunk: Node3D = null
var _entering: bool = false

@onready var portal_area: Area3D = $PortalArea
@onready var portal_mesh: MeshInstance3D = $PortalMesh
@onready var particles: GPUParticles3D = $Particles


func _ready() -> void:
	visible = false
	if portal_area:
		portal_area.body_entered.connect(_on_body_entered)
	if particles:
		particles.emitting = false


func configure(world_generator: Node, owner_chunk: Node3D = null) -> void:
	_world_generator = world_generator
	_owner_chunk = owner_chunk
	if world_generator and "world_seed" in world_generator:
		world_index = int(world_generator.world_seed)


func enable_portal() -> void:
	is_active = true
	visible = true
	if particles:
		particles.emitting = true
	_start_idle_pulse()
	SoundManager.play("portal")
	print("Cave portal is now active!")


func _start_idle_pulse() -> void:
	if portal_mesh == null:
		return
	var tween := create_tween().set_loops()
	tween.tween_property(portal_mesh, "scale", Vector3(1.15, 1.15, 1.15), 0.8)
	tween.tween_property(portal_mesh, "scale", Vector3.ONE, 0.8)


func _on_body_entered(body: Node3D) -> void:
	if not is_active or _entering:
		return
	if not body.has_method("player"):
		return
	_enter_portal(body)


func _enter_portal(_player: Node) -> void:
	if _entering:
		return
	_entering = true
	is_active = false
	if portal_area:
		portal_area.set_deferred("monitoring", false)
	if particles:
		particles.emitting = false

	await _screen_flash()
	if _world_generator and _world_generator.has_method("enter_cave_portal"):
		_world_generator.enter_cave_portal(self)
	else:
		get_tree().reload_current_scene()


func _screen_flash() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	var rect := ColorRect.new()
	rect.color = Color(0.15, 0.05, 0.35, 0.0)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(rect)
	get_tree().root.add_child(layer)
	var tween := create_tween()
	tween.tween_property(rect, "color:a", 1.0, 0.35)
	tween.tween_property(rect, "color:a", 0.0, 0.45)
	await tween.finished
	layer.queue_free()
