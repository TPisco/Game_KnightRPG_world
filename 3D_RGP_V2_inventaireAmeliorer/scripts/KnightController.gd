## Lone knight protagonist: movement, combat, stamina, stats, feedback.
class_name KnightController
extends CharacterBody3D

const JUMP_VELOCITY := 4.5
const STAMINA_REGEN := 10.0
const DAMAGE_NUMBER_SCENE := preload("res://scenes/ui/DamageNumber.tscn")

@export var move_speed: float = 5.0
@export var jump_velocity: float = 4.5

var sensivity: float = 0.003
var onCoolDown: bool = false
var is_attacking: bool = false
var is_skill_active: bool = false

var gold: int = 20
var hp: int = 100
var Maxhp: int = 100
var damage: int = 10
var speed: float = 5.0
var stamina: float = 50.0
var max_stamina: float = 50.0
var target: Array = []
var isGuarding: bool = false

@onready var camera: Camera3D = $FirstPov
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var coolDown: Timer = $AttackCoolDown
@onready var HpBar: TextureProgressBar = $HUD/HpBar
@onready var StaminaBar: ProgressBar = $HUD/StaminaBar
@onready var GoldLabel: Label = $HUD/GoldLabel
@onready var LevelLabel: Label = $HUD/LevelLabel
@onready var death_screen: CanvasLayer = $deathScreen
@onready var inventory_ui: InventoryManager = $InventoryUI
@onready var swordItem: Node3D = $FirstPov/EquippedItem/Sword
@onready var skill_system: Node = $SkillSystem

var _camera_base_offset: Vector3 = Vector3.ZERO
var _shake_strength: float = 0.0


func player() -> void:
	pass


func get_strength() -> int:
	return ProgressionTracker.strength


func get_magic() -> int:
	return ProgressionTracker.magic


func get_defense() -> int:
	return ProgressionTracker.defense


func _ready() -> void:
	sensivity = ProgressionTracker.mouse_sensitivity
	_camera_base_offset = camera.position
	refresh_stats()
	Global.set_player_reference(self)
	if Global.node_position != "":
		var spawn_node = get_parent().find_child(Global.node_position)
		if spawn_node:
			position = spawn_node.position
			rotation.y = Global.rotation
	HpBar.max_value = Maxhp
	if StaminaBar:
		StaminaBar.max_value = max_stamina
	$FirstPov.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if skill_system.has_method("setup"):
		skill_system.setup(self, animation_player)
	if inventory_ui.has_signal("equipment_changed"):
		inventory_ui.equipment_changed.connect(func(_b): refresh_stats())
	var run_root := get_tree().current_scene
	if run_root:
		var skill_ui = run_root.find_child("SkillSelectionUI", true, false)
		if skill_ui and skill_ui.has_method("bind_player"):
			skill_ui.bind_player(self)
	ProgressionTracker.level_up.connect(func(_l): refresh_stats())


func refresh_stats() -> void:
	var bonuses: Dictionary = {}
	if inventory_ui and inventory_ui.has_method("get_equipment_bonuses"):
		bonuses = inventory_ui.get_equipment_bonuses()
	var stats: Dictionary = ProgressionTracker.get_player_stats(bonuses)
	Maxhp = int(stats["max_hp"])
	damage = int(stats["damage"])
	speed = float(stats["speed"])
	max_stamina = float(stats.get("max_stamina", 50.0))
	move_speed = speed
	hp = mini(hp, Maxhp)
	stamina = mini(stamina, max_stamina)
	HpBar.max_value = Maxhp
	if StaminaBar:
		StaminaBar.max_value = max_stamina
	_updateHUD()


func get_total_damage() -> int:
	return damage


func spend_stamina(cost: float) -> bool:
	if stamina < cost:
		return false
	stamina -= cost
	_updateHUD()
	return true


func take_damage(amount: int) -> void:
	var reduced := amount - get_defense()
	var final_dmg := maxi(1, reduced)
	if isGuarding:
		final_dmg = maxi(1, int(final_dmg * ProgressionTracker.get_guard_damage_multiplier()))
	hp -= final_dmg
	_updateHUD()
	_spawn_damage_number(final_dmg, Color(1.0, 0.35, 0.35))
	_apply_screen_shake(0.12)
	if hp <= 0:
		die()


func die() -> void:
	death_screen.visible = true
	get_tree().paused = true
	var colision = find_child("CollisionShape3D")
	if colision:
		colision.disabled = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Global.save_progression()


func deal_Damage() -> void:
	for enemy in target:
		if not is_instance_valid(enemy) or not ("hp" in enemy):
			continue
		var dealt := get_total_damage()
		enemy.hp -= dealt
		if enemy.has_method("show_damage_number"):
			enemy.show_damage_number(dealt)
		elif enemy is Node3D:
			CombatFeedback.spawn_damage_number(enemy.global_position + Vector3(0, 1.5, 0), dealt, Color(1.0, 0.9, 0.3))
	_apply_screen_shake(0.06)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	stamina = minf(max_stamina, stamina + STAMINA_REGEN * delta)

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	handle_movement(delta)
	_update_camera_shake(delta)
	move_and_slide()


func handle_movement(_delta: float) -> void:
	var input_dir := Input.get_vector("left", "right", "foward", "backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)


func _process(_delta: float) -> void:
	if hp <= 0 and not death_screen.visible:
		die()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * sensivity)
		camera.rotate_x(-event.relative.y * sensivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-60), deg_to_rad(70))


func _attack(event: InputEvent) -> void:
	if event.is_action_pressed("attack") and not onCoolDown and not is_attacking:
		is_attacking = true
		animation_player.play("swordswing")
		onCoolDown = true
		coolDown.start()


func _handle_skill_input(event: InputEvent) -> void:
	if not skill_system:
		return
	if event.is_action_pressed("skill"):
		is_skill_active = skill_system.activate_skill()
	if event.is_action_pressed("Guard"):
		if not skill_system.handle_guard_input(true):
			animation_player.play("Guard")
			isGuarding = true
	elif event.is_action_released("Guard"):
		if skill_system.get_cooldown_remaining("iron_wall") <= 0.0:
			isGuarding = false
			animation_player.play("RESET")


func toggle_inventory() -> void:
	if inventory_ui.visible:
		inventory_ui.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		inventory_ui.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _updateHUD() -> void:
	HpBar.value = hp
	if StaminaBar:
		StaminaBar.value = stamina
	GoldLabel.text = str(gold)
	if LevelLabel:
		LevelLabel.text = "Lv.%d  Depth:%d  STA:%d" % [
			ProgressionTracker.level, ProgressionTracker.run_depth, int(stamina)
		]


func _spawn_damage_number(amount: int, color: Color) -> void:
	CombatFeedback.spawn_damage_number(global_position + Vector3(0, 1.8, 0), amount, color)


func _apply_screen_shake(strength: float) -> void:
	_shake_strength = maxf(_shake_strength, strength)


func _update_camera_shake(delta: float) -> void:
	if _shake_strength <= 0.0:
		camera.position = _camera_base_offset
		return
	camera.position = _camera_base_offset + Vector3(
		randf_range(-_shake_strength, _shake_strength),
		randf_range(-_shake_strength, _shake_strength),
		0.0
	)
	_shake_strength = maxf(0.0, _shake_strength - delta * 0.35)


func _on_attack_cool_down_timeout() -> void:
	onCoolDown = false
	is_attacking = false


func _on_attack_zone_body_entered(body: Node3D) -> void:
	if body.has_method("enemy"):
		target.append(body)


func _on_attack_zone_body_exited(body: Node3D) -> void:
	if body.has_method("enemy"):
		target.erase(body)


func _input(event: InputEvent) -> void:
	if swordItem.visible:
		_attack(event)
		_handle_skill_input(event)
	if event.is_action_pressed("switch"):
		_switch_view()
	if Input.is_action_just_pressed("escape"):
		get_tree().paused = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
	if Input.is_action_just_pressed("inventory"):
		toggle_inventory()


func _switch_view() -> void:
	if camera == $Head:
		camera = $FirstPov
		$FirstPov.current = true
	else:
		camera = $Head
		$Head/ThirdPov.current = true


func _on_respawn_pressed() -> void:
	get_tree().paused = false
	ProgressionTracker.start_new_run(true)
	get_tree().reload_current_scene()


func _on_menu_pressed() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Global.save_progression()
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
