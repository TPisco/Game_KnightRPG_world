## Reusable death logic for goblins, chunk enemies, and bosses.
class_name EnemyDeathSystem
extends Node

signal enemy_died(enemy_node: Node, xp_value: int, loot_data: ItemData)

@export var death_anim_name: String = "Die"
@export var fallback_remove_delay: float = 2.0
@export var loot_item: ItemData

var death_rewards_callback: Callable  ## Optional hook (e.g. CaveGuardian portal spawn).

var _host: CharacterBody3D
var _anim: AnimationPlayer
var _dying: bool = false
var _rewards_given: bool = false


func setup(host: CharacterBody3D, anim: AnimationPlayer = null) -> void:
	_host = host
	_anim = anim
	if _anim == null and _host:
		_anim = _host.find_child("AnimationPlayer", true, false) as AnimationPlayer


func take_damage(amount: int) -> void:
	if _dying or _host == null or not ("hp" in _host):
		return
	_host.hp -= amount
	if _host.has_method("show_damage_number"):
		_host.show_damage_number(amount)
	else:
		CombatFeedback.spawn_damage_number(
			_host.global_position + Vector3(0, 1.5, 0),
			amount,
			Color(1.0, 0.85, 0.3)
		)
	if _host.hp <= 0:
		begin_death()


func begin_death() -> void:
	if _dying or _host == null:
		return
	_dying = true
	_disable_host_collisions()
	_give_rewards()
	_spawn_death_particles()
	SoundManager.play("death")
	if _anim and _anim.has_animation(death_anim_name):
		_anim.play(death_anim_name)
		await _anim.animation_finished
	else:
		await get_tree().create_timer(fallback_remove_delay).timeout
	enemy_died.emit(_host, _get_xp_value(), loot_item)
	_host.queue_free()


func _get_xp_value() -> int:
	if _host and "value" in _host:
		return int(_host.value)
	return 10


func _get_gold_value() -> int:
	if _host and "value" in _host:
		return int(_host.value)
	return 10


func _give_rewards() -> void:
	if _rewards_given:
		return
	_rewards_given = true
	if death_rewards_callback.is_valid():
		death_rewards_callback.call()
	else:
		ProgressionTracker.add_xp(_get_xp_value())
		_give_gold_to_killer()
		_give_loot_to_killer()


func _give_gold_to_killer() -> void:
	if _host == null or not ("target" in _host):
		return
	var killer = _host.target
	if killer and is_instance_valid(killer) and killer.has_method("player"):
		killer.gold += _get_gold_value()
		if killer.has_method("_updateHUD"):
			killer._updateHUD()


func _give_loot_to_killer() -> void:
	if loot_item == null or _host == null or not ("target" in _host):
		return
	var killer = _host.target
	if killer and is_instance_valid(killer) and killer.has_method("player"):
		var inv = killer.get_node_or_null("InventoryUI")
		if inv and inv.has_method("pickupItem"):
			inv.pickupItem(loot_item.duplicate(true))


func _disable_host_collisions() -> void:
	if _host == null:
		return
	for col in _host.find_children("*", "CollisionShape3D", true, false):
		if col is CollisionShape3D:
			(col as CollisionShape3D).disabled = true
	for area in _host.find_children("*", "Area3D", true, false):
		if area is Area3D:
			(area as Area3D).monitoring = false
			(area as Area3D).monitorable = false


func _spawn_death_particles() -> void:
	if _host == null:
		return
	var root := _host.get_parent()
	if root == null:
		return
	for i in 3:
		var spark := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.08
		sphere.height = 0.16
		spark.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.85, 0.2)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.7, 0.1)
		mat.emission_energy_multiplier = 2.0
		spark.material_override = mat
		root.add_child(spark)
		spark.global_position = _host.global_position + Vector3(randf_range(-0.4, 0.4), 1.0, randf_range(-0.4, 0.4))
		var tween := spark.create_tween()
		tween.set_parallel(true)
		tween.tween_property(spark, "global_position:y", spark.global_position.y + 1.5, 0.6)
		tween.tween_property(spark, "scale", Vector3.ZERO, 0.6)
		tween.chain().tween_callback(spark.queue_free)
