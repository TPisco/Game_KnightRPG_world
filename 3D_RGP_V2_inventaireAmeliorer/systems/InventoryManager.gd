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
	# Consumables are used (and removed) instead of equipped.
	if slotID >= 0 and slotID < InventorySlots.size():
		var sel: ItemData = InventorySlots[slotID].SlotData
		if sel and sel.item_type == "consumable":
			_consume_item(slotID, sel)
			return
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


func _consume_item(slotID: int, item: ItemData) -> void:
	var heal: int = int(item.stat_bonuses.get("heal", 0))
	var player = playerBody if playerBody else Global.player_node
	if heal > 0 and player and "hp" in player and "Maxhp" in player:
		player.hp = mini(player.Maxhp, player.hp + heal)
		if player.has_method("_updateHUD"):
			player._updateHUD()
	if EquippedSlot == slotID:
		EquippedSlot = -1
	InventorySlots[slotID].FillSlot(null, false)
	_recalculate_bonuses()


func grant_all_weapons() -> void:
	var items: Array[ItemData] = [
		LootTable.rusted_sword(),
		LootTable.fractured_blade(),
		LootTable.wooden_shield(),
		LootTable.guardian_plate(),
		LootTable.fractured_shard(),
	]
	for item in items:
		pickupItem(item.duplicate(true))
	# Auto-equip the first weapon so attacks/skills are enabled in the hub.
	for slot in InventorySlots:
		if slot.SlotFilled and slot.SlotData and slot.SlotData.item_type == "weapon":
			ItemEquiped(slot.InventorySlotID)
			break


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
