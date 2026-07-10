## Minecraft-style bottom hotbar: quick access to the first 5 inventory slots.
## Keys 1-5 select a slot (equip weapon / drink potion); mouse wheel cycles
## between hotbar weapons. Purely reads the existing inventory — no new state.
class_name Hotbar
extends CanvasLayer

const SLOT_SIZE := 56.0
const SLOT_GAP := 6.0

var _inventory: Node = null
var _slot_panels: Array[Panel] = []
var _slot_icons: Array[TextureRect] = []
var _normal_style: StyleBoxFlat
var _selected_style: StyleBoxFlat


func setup(inventory: Node) -> void:
	_inventory = inventory


func _ready() -> void:
	layer = 5
	_normal_style = _make_style(Color(0.1, 0.1, 0.14, 0.75), Color(0.5, 0.5, 0.55, 0.8), 2)
	_selected_style = _make_style(Color(0.16, 0.14, 0.1, 0.9), Color(0.95, 0.8, 0.3, 1.0), 3)

	var row := HBoxContainer.new()
	row.name = "Row"
	add_child(row)
	row.add_theme_constant_override("separation", int(SLOT_GAP))
	row.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	var total_w := 5 * SLOT_SIZE + 4 * SLOT_GAP
	row.offset_left = -total_w * 0.5
	row.offset_right = total_w * 0.5
	row.offset_top = -SLOT_SIZE - 12.0
	row.offset_bottom = -12.0

	for i in 5:
		var panel := Panel.new()
		panel.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		panel.add_theme_stylebox_override("panel", _normal_style)
		row.add_child(panel)

		var icon := TextureRect.new()
		panel.add_child(icon)
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 6
		icon.offset_top = 6
		icon.offset_right = -6
		icon.offset_bottom = -6
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

		var key_label := Label.new()
		key_label.text = str(i + 1)
		key_label.add_theme_font_size_override("font_size", 12)
		key_label.modulate = Color(1, 1, 1, 0.7)
		panel.add_child(key_label)
		key_label.position = Vector2(4, 2)

		_slot_panels.append(panel)
		_slot_icons.append(icon)


func _make_style(bg: Color, border: Color, border_w: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	for side in ["border_width_left", "border_width_top", "border_width_right", "border_width_bottom"]:
		style.set(side, border_w)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style


func _process(_delta: float) -> void:
	if _inventory == null or not is_instance_valid(_inventory):
		return
	var slots = _inventory.InventorySlots
	var equipped: int = _inventory.EquippedSlot
	for i in _slot_icons.size():
		if i < slots.size() and slots[i].SlotFilled and slots[i].SlotData:
			_slot_icons[i].texture = slots[i].SlotData.Icon
		else:
			_slot_icons[i].texture = null
		_slot_panels[i].add_theme_stylebox_override(
			"panel", _selected_style if i == equipped else _normal_style
		)


func _input(event: InputEvent) -> void:
	if _inventory == null or not is_instance_valid(_inventory):
		return
	# Only during live gameplay — never while a menu owns the mouse.
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	for i in 5:
		if event.is_action_pressed("hotbar_%d" % (i + 1)):
			_inventory.equip_hotbar_slot(i)
			return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_inventory.cycle_hotbar_weapon(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_inventory.cycle_hotbar_weapon(1)
