## Indoor shop room. Lives far below the world; the player teleports in and out
## so the outside world (chunks, enemies, portals) is never unloaded.
class_name ShopInterior
extends Node3D

const REENTRY_COOLDOWN_MS := 1500
const INTERIOR_DEPTH := -140.0

static var _met_collector: bool = false

var _return_position: Vector3 = Vector3.ZERO
var _cooldown_until_ms: int = 0
var _ui_opened_this_visit: bool = false

@onready var exit_area: Area3D = $ExitArea
@onready var spawn_point: Marker3D = $SpawnPoint
@onready var shop_zone: Area3D = $ShopZone
@onready var shop_ui: CanvasLayer = $ShopUI


func _ready() -> void:
	if exit_area:
		exit_area.body_entered.connect(_on_exit_body_entered)
	if shop_zone:
		shop_zone.body_entered.connect(_on_shop_zone_entered)
	_apply_fantasy_pack_visuals()


## Swap placeholder shapes for FantasyPack shop assets when they exist.
func _apply_fantasy_pack_visuals() -> void:
	var pack := "res://assets/model/FantasyPack/"

	# The Collector: real merchant model instead of the purple capsule.
	if ModelLibrary.exists(pack + "characters/merchant.glb"):
		var keeper := get_node_or_null("Shopkeeper") as MeshInstance3D
		if keeper:
			keeper.visible = false
		var merchant := ModelLibrary.place_prop(self, pack + "characters/merchant.glb", Vector3(0, 0, -4.5), PI)
		if merchant:
			var aabb := ModelLibrary.measure(merchant)
			merchant.position.y = -aabb.position.y

	# Counter model over the (kept) collision box.
	if ModelLibrary.exists(pack + "shop/shop_counter.glb"):
		var counter_mesh := get_node_or_null("Counter/Mesh") as MeshInstance3D
		if counter_mesh:
			counter_mesh.visible = false
		ModelLibrary.place_prop(self, pack + "shop/shop_counter.glb", Vector3(0, 0, -3), PI)

	# Furnishings — pure decor, no collision needed.
	ModelLibrary.place_prop(self, pack + "shop/shop_shelf.glb", Vector3(-4.5, 0, -5.4))
	ModelLibrary.place_prop(self, pack + "shop/shop_shelf.glb", Vector3(4.5, 0, -5.4))
	ModelLibrary.place_prop(self, pack + "shop/rug.glb", Vector3(0, 0.02, 0.5))
	ModelLibrary.place_prop(self, pack + "shop/potion_red.glb", Vector3(-1.2, 1.12, -3.0))
	ModelLibrary.place_prop(self, pack + "shop/potion_blue.glb", Vector3(-0.7, 1.12, -3.1))
	ModelLibrary.place_prop(self, pack + "shop/coin_pile.glb", Vector3(1.0, 1.12, -3.0))
	ModelLibrary.place_prop(self, pack + "shop/barrel.glb", Vector3(-5.8, 0, 3.8))
	ModelLibrary.place_prop(self, pack + "shop/crate.glb", Vector3(5.8, 0, 3.9), 0.4)
	ModelLibrary.place_prop(self, pack + "shop/sack.glb", Vector3(5.0, 0, 4.6))
	ModelLibrary.place_prop(self, pack + "dungeon/brazier.glb", Vector3(-5.5, 0, -5.0))
	ModelLibrary.place_prop(self, pack + "shop/shop_table.glb", Vector3(4.8, 0, -1.5))
	ModelLibrary.place_prop(self, pack + "shop/shop_stool.glb", Vector3(3.8, 0, -1.2), 0.7)


func enter_shop(player: Node3D, building: Node3D) -> void:
	if Time.get_ticks_msec() < _cooldown_until_ms:
		return
	_cooldown_until_ms = Time.get_ticks_msec() + REENTRY_COOLDOWN_MS
	_ui_opened_this_visit = false

	# Park the room directly under this shop so chunk streaming stays put,
	# and return the player a few meters outside the door afterwards.
	global_position = Vector3(building.global_position.x, INTERIOR_DEPTH, building.global_position.z)
	_return_position = building.global_position \
		+ building.global_transform.basis.z * 7.0 + Vector3(0, 1.2, 0)

	player.global_position = spawn_point.global_position
	if "velocity" in player:
		player.velocity = Vector3.ZERO
	SoundManager.play("portal")

	if not _met_collector:
		_met_collector = true
		StoryManager.trigger_story_event("shop_first")
	else:
		StoryManager.trigger_story_event("shop_visit")


func _on_shop_zone_entered(body: Node3D) -> void:
	if not body.has_method("player") or _ui_opened_this_visit:
		return
	_ui_opened_this_visit = true
	if shop_ui and shop_ui.has_method("open_shop"):
		shop_ui.open_shop(body)


func _on_exit_body_entered(body: Node3D) -> void:
	if not body.has_method("player"):
		return
	if Time.get_ticks_msec() < _cooldown_until_ms:
		return
	_cooldown_until_ms = Time.get_ticks_msec() + REENTRY_COOLDOWN_MS
	if shop_ui and shop_ui.has_method("close_shop"):
		shop_ui.close_shop()
	body.global_position = _return_position
	if "velocity" in body:
		body.velocity = Vector3.ZERO
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	SoundManager.play("portal")
