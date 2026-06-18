## Extends grid inventory with stat bonuses and progression sync.
extends InventoryHandler
class_name InventoryManager

signal equipment_changed(bonuses: Dictionary)

var _equipment_bonuses: Dictionary = {}


func _ready() -> void:
	super._ready()


func get_equipment_bonuses() -> Dictionary:
	return _equipment_bonuses.duplicate()


func ItemEquiped(slotID: int) -> void:
	if EquippedSlot != -1:
		InventorySlots[EquippedSlot].FillSlot(InventorySlots[EquippedSlot].SlotData, false)
		var old_data: ItemData = InventorySlots[EquippedSlot].SlotData
		if old_data:
			if old_data.item_type == "weapon":
				var sword = equipped_item.find_child("Sword", true, false)
				if sword:
					sword.visible = false
			else:
				var item_show = equipped_item.find_child(old_data.ItemName, true, false)
				if item_show:
					item_show.visible = false

	if slotID != EquippedSlot && InventorySlots[slotID].SlotData != null:
		InventorySlots[slotID].FillSlot(InventorySlots[slotID].SlotData, true)
		var new_data: ItemData = InventorySlots[slotID].SlotData
		if new_data:
			if new_data.item_type == "weapon":
				var sword = equipped_item.find_child("Sword", true, false)
				if sword:
					sword.visible = true
			else:
				var item_show = equipped_item.find_child(new_data.ItemName, true, false)
				if item_show:
					item_show.visible = true
		EquippedSlot = slotID
	else:
		EquippedSlot = -1
	_recalculate_bonuses()


func ItemDroppedOnSlot(fromSlotID: int, toSlotID: int) -> void:
	super.ItemDroppedOnSlot(fromSlotID, toSlotID)
	_recalculate_bonuses()


func pickupItem(item: ItemData) -> void:
	super.pickupItem(item)
	_recalculate_bonuses()


func _drop_data(at_position: Vector2, data: Variant) -> void:
	super._drop_data(at_position, data)
	_recalculate_bonuses()


func _recalculate_bonuses() -> void:
	_equipment_bonuses.clear()
	for slot in InventorySlots:
		if not slot.SlotFilled or slot.SlotData == null:
			continue
		var data: ItemData = slot.SlotData
		if data.item_type in ["artifact", "armor"] and data.stat_bonuses:
			for key in data.stat_bonuses:
				if key == "heal":
					continue
				_equipment_bonuses[key] = _equipment_bonuses.get(key, 0) + data.stat_bonuses[key]
		elif slot.InventorySlotID == EquippedSlot and data.stat_bonuses:
			for key in data.stat_bonuses:
				if key == "heal":
					continue
				_equipment_bonuses[key] = _equipment_bonuses.get(key, 0) + data.stat_bonuses[key]
	equipment_changed.emit(_equipment_bonuses)
	if Global.player_node and Global.player_node.has_method("refresh_stats"):
		Global.player_node.refresh_stats()
