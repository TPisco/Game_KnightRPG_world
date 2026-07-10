## Extends grid inventory with stat bonuses and progression sync.
extends InventoryHandler
class_name InventoryManager

signal equipment_changed(bonuses: Dictionary)

const HOTBAR_SIZE := 5

## Dedicated equipment slots (indices into InventorySlots, -1 = empty).
var EquippedArmorSlot: int = -1
var EquippedShieldSlot: int = -1

var _equipment_bonuses: Dictionary = {}
var _eq_display: Dictionary = {}  # "Weapon"/"Armor"/"Shield" -> {icon, label}


func _ready() -> void:
	super._ready()
	_build_equipment_panel()


func get_equipment_bonuses() -> Dictionary:
	return _equipment_bonuses.duplicate()


## "melee", "gun", or "staff" for the equipped weapon; "" when nothing is equipped.
func get_equipped_weapon_class() -> String:
	if EquippedSlot < 0 or EquippedSlot >= InventorySlots.size():
		return ""
	var data: ItemData = InventorySlots[EquippedSlot].SlotData
	if data == null or data.item_type != "weapon":
		return ""
	return data.weapon_class if data.weapon_class != "" else "melee"


## Reads a combat tuning value (fire_rate, mana_cost...) off the equipped weapon.
func get_equipped_weapon_stat(key: String, default_value: float) -> float:
	if EquippedSlot < 0 or EquippedSlot >= InventorySlots.size():
		return default_value
	var data: ItemData = InventorySlots[EquippedSlot].SlotData
	if data == null or data.stat_bonuses == null:
		return default_value
	return float(data.stat_bonuses.get(key, default_value))


func has_free_slot() -> bool:
	for slot in InventorySlots:
		if not slot.SlotFilled:
			return true
	return false


# --- Save/load (multi-slot save system) ------------------------------------

## Snapshot of every filled slot plus the equipped index, JSON-safe.
func serialize_inventory() -> Dictionary:
	var items: Array = []
	for slot in InventorySlots:
		if not slot.SlotFilled or slot.SlotData == null:
			continue
		var data: ItemData = slot.SlotData
		items.append({
			"slot": slot.InventorySlotID,
			"name": data.ItemName,
			"type": data.item_type,
			"wclass": data.weapon_class,
			"bonuses": data.stat_bonuses,
			"unlock": data.unlock_skill,
			"icon": data.Icon.resource_path if data.Icon else "",
			"model": data.ItemModelPrefab.resource_path if data.ItemModelPrefab else "",
			"usable": data.UsableModel.resource_path if data.UsableModel else "",
		})
	return {
		"items": items,
		"equipped": EquippedSlot,
		"equipped_armor": EquippedArmorSlot,
		"equipped_shield": EquippedShieldSlot,
	}


## Rebuilds the grid from a snapshot; restores the equipped weapon too.
func load_inventory(snapshot: Dictionary) -> void:
	# Clear whatever is currently held (fresh spawns are normally empty).
	if EquippedSlot != -1:
		ItemEquiped(EquippedSlot)
	for slot in InventorySlots:
		slot.FillSlot(null, false)
	EquippedSlot = -1
	EquippedArmorSlot = -1
	EquippedShieldSlot = -1

	var entries = snapshot.get("items", [])
	if entries is Array:
		for entry in entries:
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			var idx := int(entry.get("slot", -1))
			if idx < 0 or idx >= InventorySlots.size():
				continue
			InventorySlots[idx].FillSlot(_item_from_dict(entry), false)

	var equipped := int(snapshot.get("equipped", -1))
	if equipped >= 0 and equipped < InventorySlots.size() \
			and InventorySlots[equipped].SlotFilled \
			and InventorySlots[equipped].SlotData.item_type in ["weapon", "misc"]:
		ItemEquiped(equipped)

	var armor_idx := int(snapshot.get("equipped_armor", -1))
	if armor_idx >= 0 and armor_idx < InventorySlots.size() \
			and InventorySlots[armor_idx].SlotFilled \
			and InventorySlots[armor_idx].SlotData.item_type == "armor" \
			and InventorySlots[armor_idx].SlotData.weapon_class != "shield":
		_toggle_armor_equip(armor_idx, false)

	var shield_idx := int(snapshot.get("equipped_shield", -1))
	if shield_idx >= 0 and shield_idx < InventorySlots.size() \
			and InventorySlots[shield_idx].SlotFilled \
			and InventorySlots[shield_idx].SlotData.weapon_class == "shield":
		_toggle_armor_equip(shield_idx, true)

	_recalculate_bonuses()


func _item_from_dict(entry: Dictionary) -> ItemData:
	var item := ItemData.new()
	item.ItemName = str(entry.get("name", ""))
	item.item_type = str(entry.get("type", "misc"))
	item.weapon_class = str(entry.get("wclass", ""))
	item.unlock_skill = str(entry.get("unlock", ""))
	var bonuses = entry.get("bonuses", {})
	if bonuses is Dictionary:
		item.stat_bonuses = bonuses
	for prop_and_key in [["Icon", "icon"], ["ItemModelPrefab", "model"], ["UsableModel", "usable"]]:
		var path := str(entry.get(prop_and_key[1], ""))
		if path != "" and ResourceLoader.exists(path):
			item.set(prop_and_key[0], load(path))
	return item


## Maps a weapon to its first-person view model node under EquippedItem.
func _weapon_visual_name(data: ItemData) -> String:
	match data.weapon_class:
		"gun":
			return "Gun"
		"staff":
			return "Staff"
		_:
			return "Sword"


# FantasyPack in-hand models per item (grip at origin, blade +Y, barrel -Z).
const WEAPON_VIEW_MODELS := {
	"Rusted Sword": "res://assets/model/FantasyPack/weapons/sword_basic.glb",
	"Fractured Blade": "res://assets/model/FantasyPack/weapons/sword_fractured.glb",
	"Knight's Blade": "res://assets/model/FantasyPack/weapons/sword_knight.glb",
	"RiftPistol": "res://assets/model/FantasyPack/weapons/gun_flintlock.glb",
	"ShardRifle": "res://assets/model/FantasyPack/weapons/gun_blunderbuss.glb",
	"ApprenticeStaff": "res://assets/model/FantasyPack/weapons/staff_arcane.glb",
	"EmberStaff": "res://assets/model/FantasyPack/weapons/staff_fire.glb",
}


func _get_weapon_holder() -> Node3D:
	var holder := equipped_item.get_node_or_null("WeaponModel") as Node3D
	if holder == null:
		holder = Node3D.new()
		holder.name = "WeaponModel"
		equipped_item.add_child(holder)
		# Same grip point as the original Sword view model.
		holder.position = Vector3(0.464, 0.221, -0.429)
	return holder


## Shows/hides the in-hand visual for a weapon: exact pack model when known,
## otherwise the generic Sword/Gun/Staff placeholder node.
func _set_weapon_visible(data: ItemData, shown: bool) -> void:
	var holder := _get_weapon_holder()
	for child in holder.get_children():
		child.queue_free()
	holder.visible = false
	var fallback = equipped_item.find_child(_weapon_visual_name(data), true, false)
	if not shown:
		if fallback:
			fallback.visible = false
		return
	var path: String = WEAPON_VIEW_MODELS.get(data.ItemName, "")
	if path != "" and ModelLibrary.exists(path):
		var model := ModelLibrary.spawn(path)
		if model:
			holder.add_child(model)
			holder.visible = true
			return
	if fallback:
		fallback.visible = true


func ItemEquiped(slotID: int) -> void:
	# Consumables are used; armor and shields go to their own equipment slots.
	if slotID >= 0 and slotID < InventorySlots.size():
		var sel: ItemData = InventorySlots[slotID].SlotData
		if sel and sel.item_type == "consumable":
			_consume_item(slotID, sel)
			return
		if sel and sel.item_type == "armor":
			_toggle_armor_equip(slotID, sel.weapon_class == "shield")
			return
	if EquippedSlot != -1:
		InventorySlots[EquippedSlot].FillSlot(InventorySlots[EquippedSlot].SlotData, false)
		var old_data: ItemData = InventorySlots[EquippedSlot].SlotData
		if old_data:
			if old_data.item_type == "weapon":
				_set_weapon_visible(old_data, false)
			else:
				var item_show = equipped_item.find_child(old_data.ItemName, true, false)
				if item_show:
					item_show.visible = false

	if slotID != EquippedSlot && InventorySlots[slotID].SlotData != null:
		InventorySlots[slotID].FillSlot(InventorySlots[slotID].SlotData, true)
		var new_data: ItemData = InventorySlots[slotID].SlotData
		if new_data:
			if new_data.item_type == "weapon":
				_set_weapon_visible(new_data, true)
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
	var mana_restore: int = int(item.stat_bonuses.get("mana", 0))
	var player = playerBody if playerBody else Global.player_node
	if heal > 0 and player and "hp" in player and "Maxhp" in player:
		player.hp = mini(player.Maxhp, player.hp + heal)
		if player.has_method("_updateHUD"):
			player._updateHUD()
	if mana_restore > 0 and player and player.has_method("restore_mana"):
		player.restore_mana(float(mana_restore))
	if EquippedSlot == slotID:
		EquippedSlot = -1
	InventorySlots[slotID].FillSlot(null, false)
	_recalculate_bonuses()


func grant_all_weapons() -> void:
	var items: Array[ItemData] = [
		LootTable.rusted_sword(),
		LootTable.fractured_blade(),
		LootTable.pistol(),
		LootTable.rifle(),
		LootTable.apprentice_staff(),
		LootTable.ember_staff(),
		LootTable.wooden_shield(),
		LootTable.guardian_plate(),
		LootTable.fractured_shard(),
	]
	for item in items:
		pickupItem(item.duplicate(true))
	# Auto-equip the first weapon so attacks/skills are enabled in the hub,
	# plus the first armor piece and shield for equipment testing.
	for slot in InventorySlots:
		if slot.SlotFilled and slot.SlotData and slot.SlotData.item_type == "weapon":
			ItemEquiped(slot.InventorySlotID)
			break
	for slot in InventorySlots:
		if not slot.SlotFilled or slot.SlotData == null or slot.SlotData.item_type != "armor":
			continue
		var is_shield: bool = slot.SlotData.weapon_class == "shield"
		if is_shield and EquippedShieldSlot == -1:
			_toggle_armor_equip(slot.InventorySlotID, true)
		elif not is_shield and EquippedArmorSlot == -1:
			_toggle_armor_equip(slot.InventorySlotID, false)


## Equip/unequip armor or a shield into its dedicated slot.
func _toggle_armor_equip(slotID: int, is_shield: bool) -> void:
	var current := EquippedShieldSlot if is_shield else EquippedArmorSlot
	if current == slotID:
		InventorySlots[slotID].FillSlot(InventorySlots[slotID].SlotData, false)
		if is_shield:
			EquippedShieldSlot = -1
		else:
			EquippedArmorSlot = -1
	else:
		if current >= 0 and current < InventorySlots.size():
			InventorySlots[current].FillSlot(InventorySlots[current].SlotData, false)
		InventorySlots[slotID].FillSlot(InventorySlots[slotID].SlotData, true)
		if is_shield:
			EquippedShieldSlot = slotID
		else:
			EquippedArmorSlot = slotID
	_recalculate_bonuses()


func _remap_index(idx: int, a: int, b: int) -> int:
	if idx == a:
		return b
	if idx == b:
		return a
	return idx


func _is_equipped_index(i: int) -> bool:
	return i != -1 and (i == EquippedSlot or i == EquippedArmorSlot or i == EquippedShieldSlot)


func ItemDroppedOnSlot(fromSlotID: int, toSlotID: int) -> void:
	# Keep all three equipment references pointing at the moved items.
	EquippedSlot = _remap_index(EquippedSlot, fromSlotID, toSlotID)
	EquippedArmorSlot = _remap_index(EquippedArmorSlot, fromSlotID, toSlotID)
	EquippedShieldSlot = _remap_index(EquippedShieldSlot, fromSlotID, toSlotID)

	var toSlotItem = InventorySlots[toSlotID].SlotData
	var fromSlotItem = InventorySlots[fromSlotID].SlotData
	InventorySlots[toSlotID].FillSlot(fromSlotItem, _is_equipped_index(toSlotID))
	InventorySlots[fromSlotID].FillSlot(toSlotItem, _is_equipped_index(fromSlotID))
	_recalculate_bonuses()


## Hotbar: select slot i (equip weapon / drink potion / equip armor).
func equip_hotbar_slot(i: int) -> void:
	if i < 0 or i >= mini(HOTBAR_SIZE, InventorySlots.size()):
		return
	var slot := InventorySlots[i]
	if not slot.SlotFilled or slot.SlotData == null:
		return
	if slot.SlotData.item_type == "weapon" and EquippedSlot == i:
		return  # already in hand — don't toggle it away
	ItemEquiped(i)


## Hotbar: mouse-wheel cycling through the weapons in the hotbar row.
func cycle_hotbar_weapon(dir: int) -> void:
	var weapon_slots: Array[int] = []
	for i in mini(HOTBAR_SIZE, InventorySlots.size()):
		var slot := InventorySlots[i]
		if slot.SlotFilled and slot.SlotData and slot.SlotData.item_type == "weapon":
			weapon_slots.append(i)
	if weapon_slots.is_empty():
		return
	var pos := weapon_slots.find(EquippedSlot)
	var next_slot: int = weapon_slots[0] if pos == -1 \
		else weapon_slots[posmod(pos + dir, weapon_slots.size())]
	if next_slot != EquippedSlot:
		ItemEquiped(next_slot)


func pickupItem(item: ItemData) -> void:
	super.pickupItem(item)
	_recalculate_bonuses()


func _drop_data(at_position: Vector2, data: Variant) -> void:
	# Dropping equipped armor/a shield into the world unequips it first.
	if typeof(data) == TYPE_DICTIONARY and data.has("ID"):
		var idx := int(data["ID"])
		if idx == EquippedArmorSlot:
			EquippedArmorSlot = -1
		if idx == EquippedShieldSlot:
			EquippedShieldSlot = -1
	super._drop_data(at_position, data)
	_recalculate_bonuses()


# --- Equipment panel (weapon / armor / shield display) ----------------------

func _build_equipment_panel() -> void:
	var panel := Panel.new()
	panel.name = "EquipmentPanel"
	add_child(panel)
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 430.0
	panel.offset_top = -328.0
	panel.offset_right = 720.0
	panel.offset_bottom = -43.0

	var margin := MarginContainer.new()
	panel.add_child(margin)
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 10)

	var vbox := VBoxContainer.new()
	margin.add_child(vbox)
	vbox.add_theme_constant_override("separation", 10)

	var title := Label.new()
	title.text = "Equipment"
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	for kind in ["Weapon", "Armor", "Shield"]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		vbox.add_child(row)

		var kind_label := Label.new()
		kind_label.text = kind + ":"
		kind_label.custom_minimum_size = Vector2(64, 0)
		row.add_child(kind_label)

		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(40, 40)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)

		var name_label := Label.new()
		name_label.text = "—"
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.clip_text = true
		row.add_child(name_label)

		var unequip := Button.new()
		unequip.text = "X"
		unequip.custom_minimum_size = Vector2(32, 0)
		unequip.pressed.connect(_on_unequip_pressed.bind(kind))
		row.add_child(unequip)

		_eq_display[kind] = {"icon": icon, "label": name_label}

	var hint := Label.new()
	hint.text = "Double-click items to equip.\nKeys 1-5 / wheel: hotbar."
	hint.add_theme_font_size_override("font_size", 12)
	hint.modulate = Color(1, 1, 1, 0.65)
	vbox.add_child(hint)
	_refresh_equipment_panel()


func _on_unequip_pressed(kind: String) -> void:
	match kind:
		"Weapon":
			if EquippedSlot != -1:
				ItemEquiped(EquippedSlot)
		"Armor":
			if EquippedArmorSlot != -1:
				_toggle_armor_equip(EquippedArmorSlot, false)
		"Shield":
			if EquippedShieldSlot != -1:
				_toggle_armor_equip(EquippedShieldSlot, true)


func _refresh_equipment_panel() -> void:
	if _eq_display.is_empty():
		return
	var kinds := {"Weapon": EquippedSlot, "Armor": EquippedArmorSlot, "Shield": EquippedShieldSlot}
	for kind in kinds:
		var idx: int = kinds[kind]
		var display: Dictionary = _eq_display[kind]
		var icon := display["icon"] as TextureRect
		var label := display["label"] as Label
		if idx >= 0 and idx < InventorySlots.size() and InventorySlots[idx].SlotFilled:
			var data: ItemData = InventorySlots[idx].SlotData
			icon.texture = data.Icon
			label.text = data.ItemName
		else:
			icon.texture = null
			label.text = "—"


func _recalculate_bonuses() -> void:
	_equipment_bonuses.clear()
	for slot in InventorySlots:
		if not slot.SlotFilled or slot.SlotData == null:
			continue
		var data: ItemData = slot.SlotData
		if data.stat_bonuses == null or data.stat_bonuses.is_empty():
			continue
		# Artifacts radiate power from the bag; gear must be equipped.
		var counted: bool = data.item_type == "artifact" or _is_equipped_index(slot.InventorySlotID)
		if not counted:
			continue
		for key in data.stat_bonuses:
			if key in ["heal", "mana", "fire_rate", "mana_cost"]:
				continue
			_equipment_bonuses[key] = _equipment_bonuses.get(key, 0) + data.stat_bonuses[key]
	equipment_changed.emit(_equipment_bonuses)
	if Global.player_node and Global.player_node.has_method("refresh_stats"):
		Global.player_node.refresh_stats()
	_refresh_equipment_panel()
