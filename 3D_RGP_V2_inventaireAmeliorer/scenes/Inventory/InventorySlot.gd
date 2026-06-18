extends Control
class_name InventorySlot

signal OnItemEquiped(SlotID)
signal OnItemDropped(fromSlotID, toSlotID)

@export var EquippedHighlight : Panel
@export var IconSlot : TextureRect

var InventorySlotID : int = -1
var SlotFilled : bool = false

var SlotData : ItemData

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if (event.button_index == MOUSE_BUTTON_LEFT and event.double_click):
			OnItemEquiped.emit(InventorySlotID)

func FillSlot(data : ItemData, equipped : bool):
	SlotData = data
	EquippedHighlight.visible = equipped
	if (SlotData != null):
		SlotFilled = true
		IconSlot.texture = data.Icon
		tooltip_text = _build_tooltip(data)
	else:
		SlotFilled = false
		IconSlot.texture = null
		tooltip_text = ""


func _build_tooltip(data: ItemData) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append(data.ItemName)
	if data.item_type != "":
		lines.append("Type: " + data.item_type)
	for key in data.stat_bonuses:
		lines.append("%s: +%s" % [key, str(data.stat_bonuses[key])])
	return "\n".join(lines)

func _get_drag_data(at_position: Vector2) -> Variant:
	if (SlotFilled):
		var preview : TextureRect = TextureRect.new()
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.size = IconSlot.size
		preview.pivot_offset = IconSlot.size / 2.0
		preview.rotation = 2.0
		preview.texture = IconSlot.texture
		set_drag_preview(preview)
		return {"Type": "Item", "ID": InventorySlotID}
	else:
		return false

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data["Type"] == "Item"
	

func _drop_data(at_position: Vector2, data: Variant) -> void:
	OnItemDropped.emit(data["ID"], InventorySlotID)
