#player
extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var sensivity = 0.003
var onCoolDown = false

var gold = 20
var hp = 100
var Maxhp = 100
var damage = 10
var target = []
var isGuarding : bool = false

@onready var camera = $FirstPov
@onready var animations = $AnimationPlayer
@onready var coolDown = $AttackCoolDown
@onready var HpBar = $HUD/HpBar
@onready var GoldLabel = $HUD/GoldLabel
@onready var Sword = $FirstPov/EquippedItem
@onready var death_screen: CanvasLayer = $deathScreen
@onready var inventory_ui: InventoryHandler = $InventoryUI
@onready var swordItem: Node3D = $FirstPov/EquippedItem/Sword


func player() :
	pass

func _ready() -> void:
	_updateHUD()
	Global.set_player_reference(self)
	if Global.node_position != "":
		self.position = get_parent().find_child(Global.node_position).position
		self.rotation.y = Global.rotation
	HpBar.max_value = 100
	$FirstPov.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * sensivity)
		camera.rotate_x(-event.relative.y * sensivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-60),deg_to_rad(70))

func _process(delta: float) -> void:
	if hp <=0:
		death_screen.visible = true
		get_tree().paused =  true
		var colision = find_child("CollisionShape3D")
		colision.disabled = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _switchView(event: InputEvent):
	if event.is_action_pressed("switch"):
		if camera == $Head:
			camera = $FirstPov
			$FirstPov.current = true
		else :
			camera = $Head
			$Head/ThirdPov.current = true

func _attack(event: InputEvent):
	if event.is_action_pressed("attack") and onCoolDown == false:
		animations.play("swordswing")
		onCoolDown = true
		coolDown.start()

func deal_Damage():
	for enemy in target:
		enemy.hp -= damage

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "foward", "backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _updateHUD():
	HpBar.value = hp
	GoldLabel.text = str(gold)

func _Guard(event: InputEvent):
	if event.is_action_pressed("Guard"):
		animations.play("Guard")
		isGuarding = true
	elif event.is_action_released("Guard"):
		isGuarding = false
		animations.play("RESET")

func _on_attack_cool_down_timeout() -> void:
	onCoolDown = false

func _on_attack_zone_body_entered(body: Node3D) -> void:
	if body.has_method("enemy"):
		target.append(body)

func _on_attack_zone_body_exited(body: Node3D) -> void:
	if body.has_method("enemy"):
		target.erase(body)

func _input(event: InputEvent) -> void:
	if swordItem.visible:
		_attack(event)
		_Guard(event)
	_switchView(event)
	if Input.is_action_just_pressed("escape"):
		get_tree().quit()
	
	if Input.is_action_just_pressed("inventory"):
		if inventory_ui.visible :
			inventory_ui.visible = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			inventory_ui.visible = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		

func _on_respawn_pressed() -> void:
	get_tree().paused =  false
	get_tree().reload_current_scene()
