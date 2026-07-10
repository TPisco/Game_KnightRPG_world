extends Node
class_name InventoryHandler

@export var playerBody : CharacterBody3D
@export_flags_3d_physics var CollisionMask : int

@export var ItemSlotsCount : int = 20

@export var InventoryGrid : GridContainer
@export var InventorySlotPrefab : PackedScene = preload("res://scenes/Inventory/InventorySlot.tscn")

@onready var equipped_item: Node3D = $"../FirstPov/WeaponRig/EquippedItem"


var InventorySlots : Array[InventorySlot]= []
var EquippedSlot : int = -1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in ItemSlotsCount : 
		var slot = InventorySlotPrefab.instantiate() as InventorySlot
		InventoryGrid.add_child(slot)
		slot.InventorySlotID = i
		slot.OnItemDropped.connect(ItemDroppedOnSlot.bind())
		slot.OnItemEquiped.connect(ItemEquiped.bind())
		InventorySlots.append(slot)

func pickupItem(item : ItemData):
	var foundSlot : bool = false
	for slot in InventorySlots:
		if !slot.SlotFilled :
			slot.FillSlot(item,false)
			foundSlot = true
			break
	
	if !foundSlot:
		# Inventory full: drop the item back into the world instead of losing it.
		if item.ItemModelPrefab == null or playerBody == null or playerBody.get_parent() == null:
			return
		var newItem = item.ItemModelPrefab.instantiate() as Node3D
		playerBody.get_parent().add_child(newItem)
		newItem.global_position = playerBody.global_position + playerBody.global_transform.basis.x * 2

func ItemEquiped(slotID : int):
	if EquippedSlot != -1:
		InventorySlots[EquippedSlot].FillSlot(InventorySlots[EquippedSlot].SlotData, false)
		var ItemShow = equipped_item.find_child(InventorySlots[EquippedSlot].SlotData["ItemName"])
		ItemShow.visible = false
	
	if slotID != EquippedSlot && InventorySlots[slotID].SlotData != null:
		InventorySlots[slotID].FillSlot(InventorySlots[slotID].SlotData ,true)
		var ItemShow = equipped_item.find_child(InventorySlots[slotID].SlotData["ItemName"])
		ItemShow.visible = true
		EquippedSlot = slotID
	else:
		EquippedSlot = -1

func ItemDroppedOnSlot(fromSlotID : int, toSlotID : int):
	if EquippedSlot != -1 :
		if EquippedSlot == fromSlotID :
			EquippedSlot = toSlotID
		elif EquippedSlot == toSlotID:
			EquippedSlot = fromSlotID
	
	var toSlotItem = InventorySlots[toSlotID].SlotData
	var fromSlotItem = InventorySlots[fromSlotID].SlotData
	
	InventorySlots[toSlotID].FillSlot(fromSlotItem,EquippedSlot == toSlotID)
	InventorySlots[fromSlotID].FillSlot(toSlotItem,EquippedSlot == fromSlotID)

func _can_drop_data(at_position: Vector2,data:Variant)->bool:
	return typeof(data) == TYPE_DICTIONARY and data.get("Type", "") == "Item"

func _drop_data(at_position: Vector2,data:Variant)->void:
	# --- Safety checks (prevent crash on null/invalid data) ---
	if typeof(data) != TYPE_DICTIONARY or not data.has("ID"):
		print("Drop failed: invalid drag data")
		return
	var slot_index: int = int(data["ID"])
	if slot_index < 0 or slot_index >= InventorySlots.size():
		print("Drop failed: invalid slot index ", slot_index)
		return
	var slot := InventorySlots[slot_index]
	if not slot.SlotFilled or slot.SlotData == null:
		print("Drop failed: no item in slot ", slot_index)
		return
	if playerBody == null or playerBody.get_parent() == null:
		print("Drop failed: player not in scene")
		return
	if slot.SlotData.ItemModelPrefab == null:
		# Item has no world model (armor/artifact): clear the slot without crashing.
		print("Drop: '", slot.SlotData.ItemName, "' has no world model — removed from inventory")
		if EquippedSlot == slot_index:
			EquippedSlot = -1
		slot.FillSlot(null, false)
		return
	# --- Original logic (unchanged) ---
	if EquippedSlot == data["ID"] :
		EquippedSlot = -1
	var newItem = InventorySlots[data["ID"]].SlotData.ItemModelPrefab.instantiate() as Node3D
	InventorySlots[data["ID"]].FillSlot(null,false)
	
	playerBody.get_parent().add_child(newItem)
	newItem.global_position = GetWorldMousePosition()

func GetWorldMousePosition() -> Vector3:
	var mousePosition = get_viewport().get_mouse_position()
	var cam = get_viewport().get_camera_3d()
	var ray_start = cam.project_ray_origin(mousePosition)
	var ray_end = ray_start + cam.project_ray_normal(mousePosition) * cam.global_position.distance_to(playerBody.global_position)*2
	var world3d : World3D = playerBody.get_world_3d()
	var space_state = world3d.direct_space_state
	
	var query = PhysicsRayQueryParameters3D.create(ray_start,ray_end,CollisionMask)
	
	var results = space_state.intersect_ray(query)
	
	if results:
		return results["position"] as Vector3 + Vector3(0.0,0.5,0.0)
	else :
		return ray_start.lerp(ray_end,0.5) + Vector3(0.0,0.5,0.0)
