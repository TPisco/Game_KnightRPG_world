## Lone knight protagonist: movement, combat, stamina, stats, feedback.
class_name KnightController
extends CharacterBody3D

const JUMP_VELOCITY := 4.5
const STAMINA_REGEN := 10.0
const MANA_REGEN := 4.0
const DAMAGE_NUMBER_SCENE := preload("res://scenes/ui/DamageNumber.tscn")
const SKILL_UI_SCENE := preload("res://scenes/ui/SkillSelectionUI.tscn")
const BULLET_SCENE := preload("res://scenes/projectiles/Bullet.tscn")
const STAFF_BOLT_SCENE := preload("res://scenes/projectiles/ArcaneBolt.tscn")

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
var mana: float = 40.0
var max_mana: float = 40.0
var target: Array = []
var isGuarding: bool = false

@onready var camera: Camera3D = $FirstPov
@onready var third_person_camera: Camera3D = $Head/ThirdPov
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var coolDown: Timer = $AttackCoolDown
@onready var HpBar: TextureProgressBar = $HUD/HpBar
@onready var StaminaBar: ProgressBar = $HUD/StaminaBar
@onready var GoldLabel: Label = $HUD/GoldLabel
@onready var LevelLabel: Label = $HUD/LevelLabel
@onready var death_screen: CanvasLayer = $deathScreen
@onready var inventory_ui: InventoryManager = $InventoryUI
@onready var swordItem: Node3D = $FirstPov/WeaponRig/EquippedItem/Sword
@onready var gunItem: Node3D = get_node_or_null("FirstPov/WeaponRig/EquippedItem/Gun")
@onready var staffItem: Node3D = get_node_or_null("FirstPov/WeaponRig/EquippedItem/Staff")
@onready var ManaBar: ProgressBar = get_node_or_null("HUD/ManaBar")
@onready var skill_system: Node = $SkillSystem

var _camera_base_offset: Vector3 = Vector3.ZERO
var _shake_strength: float = 0.0
var _knight_model: Node3D = null
var _crosshair: Control = null


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
	call_deferred("_restore_saved_state")
	_setup_knight_model()
	_setup_combat_ui()
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
	if HubWorldStartup.is_hub_scene(get_tree().current_scene):
		call_deferred("_setup_hub_testing")
		if not Global.hub_story_shown:
			Global.hub_story_shown = true
			StoryManager.trigger_story_event("hub_memory")


## Applies gold and inventory queued by SaveManager.load_slot() (Continue Game).
func _restore_saved_state() -> void:
	var saved_gold := SaveManager.take_pending_gold()
	if saved_gold >= 0:
		gold = saved_gold
		hp = Maxhp  # resuming a saved run starts at full health
	var saved_inventory = SaveManager.take_pending_inventory()
	if saved_inventory != null and inventory_ui and inventory_ui.has_method("load_inventory"):
		inventory_ui.load_inventory(saved_inventory)
	_updateHUD()


func setup_for_hub_testing() -> void:
	if Global.hub_test_applied:
		_ensure_skill_ui()
		return
	Global.hub_test_mode = true
	ProgressionTracker.strength = 100
	ProgressionTracker.magic = 100
	ProgressionTracker.defense = 100
	ProgressionTracker.stat_points = 50
	ProgressionTracker.level = maxi(ProgressionTracker.level, 10)
	ProgressionTracker.build_path = "hybrid"
	ProgressionTracker.refresh_skill_unlocks()
	for skill_id in ProgressionTracker.SKILL_DEFS:
		if skill_id not in ProgressionTracker.unlocked_skills:
			ProgressionTracker.unlocked_skills.append(skill_id)
	for passive_id in ProgressionTracker.PASSIVE_DEFS:
		if passive_id not in ProgressionTracker.unlocked_passives:
			ProgressionTracker.unlocked_passives.append(passive_id)
	if skill_system and skill_system.has_method("grant_all_skills"):
		skill_system.grant_all_skills()
	if inventory_ui and inventory_ui.has_method("grant_all_weapons"):
		inventory_ui.grant_all_weapons()
	hp = 1000
	Maxhp = 1000
	stamina = 200.0
	max_stamina = 200.0
	mana = 500.0
	max_mana = 500.0
	gold = maxi(gold, 5000)
	refresh_stats()
	add_test_mode_effect()
	_ensure_skill_ui()
	Global.hub_test_applied = true


func _setup_hub_testing() -> void:
	if Global.hub_test_applied:
		_ensure_skill_ui()
		return
	setup_for_hub_testing()


func _ensure_skill_ui() -> void:
	var run_root := get_tree().current_scene
	if run_root == null:
		return
	var skill_ui = run_root.get_node_or_null("SkillSelectionUI")
	if skill_ui == null:
		skill_ui = SKILL_UI_SCENE.instantiate()
		run_root.add_child(skill_ui)
	if skill_ui.has_method("bind_player"):
		skill_ui.bind_player(self)


func add_test_mode_effect() -> void:
	if has_node("TestModeGlow"):
		return
	var glow := OmniLight3D.new()
	glow.name = "TestModeGlow"
	glow.light_color = Color(0.35, 0.75, 1.0)
	glow.light_energy = 1.4
	glow.omni_range = 4.0
	add_child(glow)
	glow.position = Vector3(0, 1.2, 0)
	var label := Label3D.new()
	label.name = "TestModeLabel"
	label.text = "TEST MODE\nPress K — skills"
	label.font_size = 28
	label.modulate = Color(0.4, 0.9, 1.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 2.4, 0)
	add_child(label)


func refresh_stats() -> void:
	var bonuses: Dictionary = {}
	if inventory_ui and inventory_ui.has_method("get_equipment_bonuses"):
		bonuses = inventory_ui.get_equipment_bonuses()
	var stats: Dictionary = ProgressionTracker.get_player_stats(bonuses)
	Maxhp = int(stats["max_hp"])
	damage = int(stats["damage"])
	speed = float(stats["speed"])
	max_stamina = float(stats.get("max_stamina", 50.0))
	max_mana = float(stats.get("max_mana", 40.0))
	move_speed = speed
	hp = mini(hp, Maxhp)
	stamina = minf(stamina, max_stamina)
	mana = minf(mana, max_mana)
	HpBar.max_value = Maxhp
	if StaminaBar:
		StaminaBar.max_value = max_stamina
	if ManaBar:
		ManaBar.max_value = max_mana
	_updateHUD()


func get_total_damage() -> int:
	return damage


func spend_stamina(cost: float) -> bool:
	if stamina < cost:
		return false
	stamina -= cost
	_updateHUD()
	return true


func spend_mana(cost: float) -> bool:
	if Global.hub_test_mode:
		return true
	if mana < cost:
		return false
	mana -= cost
	_updateHUD()
	return true


func restore_mana(amount: float) -> void:
	mana = minf(max_mana, mana + amount)
	_updateHUD()


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
		if not is_instance_valid(enemy):
			continue
		var dealt := get_total_damage()
		if enemy.has_method("take_damage"):
			enemy.take_damage(dealt)
		elif "hp" in enemy:
			enemy.hp -= dealt
			if enemy.has_method("show_damage_number"):
				enemy.show_damage_number(dealt)
	SoundManager.play("hit")
	_apply_screen_shake(0.06)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	stamina = minf(max_stamina, stamina + STAMINA_REGEN * delta)
	mana = minf(max_mana, mana + MANA_REGEN * delta)
	_update_dynamic_hud()

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
	# Only look around while the mouse is captured (not in inventory/menus).
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * sensivity)
		camera.rotate_x(-event.relative.y * sensivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-60), deg_to_rad(70))


func _attack(event: InputEvent) -> void:
	if event.is_action_pressed("attack") and not onCoolDown and not is_attacking:
		var weapon_class := "melee"
		if inventory_ui and inventory_ui.has_method("get_equipped_weapon_class"):
			weapon_class = inventory_ui.get_equipped_weapon_class()
		match weapon_class:
			"gun":
				_fire_gun()
			"staff":
				_fire_staff()
			_:
				is_attacking = true
				animation_player.play("swordswing")
				coolDown.wait_time = 0.4
				onCoolDown = true
				coolDown.start()


func _fire_gun() -> void:
	var fire_rate: float = 0.5
	if inventory_ui and inventory_ui.has_method("get_equipped_weapon_stat"):
		fire_rate = float(inventory_ui.get_equipped_weapon_stat("fire_rate", 0.5))
	_spawn_aimed_projectile(BULLET_SCENE, get_total_damage())
	SoundManager.play("shoot")
	_apply_screen_shake(0.05)
	coolDown.wait_time = maxf(0.15, fire_rate)
	onCoolDown = true
	coolDown.start()


func _fire_staff() -> void:
	var fire_rate: float = 0.7
	var mana_cost: float = 8.0
	if inventory_ui and inventory_ui.has_method("get_equipped_weapon_stat"):
		fire_rate = float(inventory_ui.get_equipped_weapon_stat("fire_rate", 0.7))
		mana_cost = float(inventory_ui.get_equipped_weapon_stat("mana_cost", 8.0))
	if not spend_mana(mana_cost):
		SoundManager.play("deny")
		return
	var bolt_damage := int(get_total_damage() * 0.8 + get_magic() * 3)
	_spawn_aimed_projectile(STAFF_BOLT_SCENE, bolt_damage)
	SoundManager.play("staff")
	coolDown.wait_time = maxf(0.2, fire_rate)
	onCoolDown = true
	coolDown.start()


## Spawns a projectile from the active camera, flying exactly where it looks.
func _spawn_aimed_projectile(scene: PackedScene, projectile_damage: int) -> void:
	var cam := third_person_camera if third_person_camera.current else camera
	var projectile := scene.instantiate()
	get_parent().add_child(projectile)
	var forward: Vector3 = -cam.global_transform.basis.z.normalized()
	var spawn_pos: Vector3 = cam.global_position + forward * 0.8
	projectile.global_position = spawn_pos
	if projectile is Node3D:
		(projectile as Node3D).look_at(spawn_pos + forward, Vector3.UP)
	if projectile.has_method("launch"):
		projectile.launch(forward, projectile_damage)


func _handle_skill_input(event: InputEvent) -> void:
	if not skill_system:
		return
	if event.is_action_pressed("skill"):
		is_skill_active = skill_system.activate_skill()
	# Direct-cast hotkeys: every unlocked power is usable at any time.
	for i in SkillSystem.SKILL_DATABASE.size():
		if event.is_action_pressed("skill_%d" % (i + 1)):
			skill_system.activate_skill(SkillSystem.SKILL_DATABASE[i]["id"])
			break
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
	GoldLabel.text = str(gold)
	_update_dynamic_hud()


## Values that change every frame: stamina regen and skill cooldown readout.
func _update_dynamic_hud() -> void:
	if StaminaBar:
		StaminaBar.value = stamina
	if ManaBar:
		ManaBar.value = mana
	if _crosshair:
		_crosshair.visible = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if LevelLabel:
		var skill_text := ""
		if skill_system and skill_system.active_skill != "":
			var cd: float = skill_system.get_cooldown_remaining()
			var skill_name: String = skill_system.active_skill.replace("_", " ").capitalize()
			if cd > 0.0:
				skill_text = "  |  %s (%.1fs)" % [skill_name, cd]
			else:
				skill_text = "  |  %s READY" % skill_name
		LevelLabel.text = "Lv.%d  Depth:%d  STA:%d%s" % [
			ProgressionTracker.level, ProgressionTracker.run_depth, int(stamina), skill_text
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


func _has_weapon_out() -> bool:
	if swordItem.visible:
		return true
	if gunItem and gunItem.visible:
		return true
	if staffItem and staffItem.visible:
		return true
	var holder := get_node_or_null("FirstPov/WeaponRig/EquippedItem/WeaponModel") as Node3D
	return holder != null and holder.visible


func _input(event: InputEvent) -> void:
	# No attacking/casting while the inventory (visible cursor) is open.
	if _has_weapon_out() and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_attack(event)
		_handle_skill_input(event)
	if event.is_action_pressed("switch"):
		_switch_view()
	if Input.is_action_just_pressed("escape"):
		get_tree().paused = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		Global.save_progression()
		get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
	if Input.is_action_just_pressed("inventory"):
		toggle_inventory()


## Crosshair, bottom hotbar, and the power-key side panel.
func _setup_combat_ui() -> void:
	var hud := get_node_or_null("HUD")
	if hud:
		_crosshair = Control.new()
		_crosshair.name = "Crosshair"
		_crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hud.add_child(_crosshair)
		_crosshair.set_anchors_preset(Control.PRESET_FULL_RECT)
		var outline := ColorRect.new()
		outline.color = Color(0, 0, 0, 0.6)
		outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_crosshair.add_child(outline)
		outline.set_anchors_preset(Control.PRESET_CENTER)
		outline.offset_left = -3
		outline.offset_top = -3
		outline.offset_right = 3
		outline.offset_bottom = 3
		var dot := ColorRect.new()
		dot.color = Color(1, 1, 1, 0.9)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_crosshair.add_child(dot)
		dot.set_anchors_preset(Control.PRESET_CENTER)
		dot.offset_left = -1.5
		dot.offset_top = -1.5
		dot.offset_right = 1.5
		dot.offset_bottom = 1.5

	var hotbar := Hotbar.new()
	hotbar.setup(inventory_ui)
	add_child(hotbar)

	var power_panel := PowerPanel.new()
	power_panel.setup(self)
	add_child(power_panel)


## FantasyPack knight body: shown in third person, hidden in first person.
func _setup_knight_model() -> void:
	var path := "res://assets/model/FantasyPack/characters/player_knight.glb"
	if not ModelLibrary.exists(path):
		return
	_knight_model = ModelLibrary.spawn(path)
	if _knight_model == null:
		return
	add_child(_knight_model)
	var aabb := ModelLibrary.measure(_knight_model)
	# Collision capsule spans -0.9..0.9 — put the model's feet at the bottom.
	_knight_model.position = Vector3(0, -0.9 - aabb.position.y, 0)
	_knight_model.visible = third_person_camera != null and third_person_camera.current
	var capsule := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if capsule:
		capsule.visible = false


func _switch_view() -> void:
	if third_person_camera.current:
		third_person_camera.current = false
		camera.current = true
	else:
		camera.current = false
		third_person_camera.current = true
	if _knight_model:
		_knight_model.visible = third_person_camera.current


func _on_respawn_pressed() -> void:
	get_tree().paused = false
	# Restart Here: same realm, same seed, same dungeon progress — respawn at
	# the last surface spot (so dungeon deaths return to the world outside).
	ProgressionTracker.restart_in_current_realm()
	if not HubWorldStartup.is_hub_scene(get_tree().current_scene) \
			and Global.last_surface_position != Vector3.INF:
		SaveManager.queue_player_position(Global.last_surface_position)
	get_tree().reload_current_scene()


func _on_menu_pressed() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Global.save_progression()
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
