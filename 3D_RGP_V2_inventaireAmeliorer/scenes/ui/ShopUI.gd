## Merchant purchase overlay: name, type, effect, price, and a Buy button per item.
extends CanvasLayer

@onready var gold_label: Label = $Panel/Margin/VBox/GoldLabel
@onready var rows_box: VBoxContainer = $Panel/Margin/VBox/Scroll/Rows
@onready var message_label: Label = $Panel/Margin/VBox/MessageLabel
@onready var close_btn: Button = $Panel/Margin/VBox/CloseBtn

var _player: Node
var _rows_built: bool = false


func _ready() -> void:
	visible = false
	if close_btn:
		close_btn.pressed.connect(close_shop)


func open_shop(player: Node) -> void:
	_player = player
	if not _rows_built:
		_build_rows()
		_rows_built = true
	_refresh()
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close_shop() -> void:
	if not visible:
		return
	visible = false
	if is_instance_valid(_player):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _build_rows() -> void:
	for entry in ShopCatalog.get_stock():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)

		var info := Label.new()
		info.text = "%s  [%s]\n%s" % [entry["name"], entry["type"], entry["desc"]]
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)

		var price := Label.new()
		price.text = "%d g" % int(entry["price"])
		price.custom_minimum_size = Vector2(64, 0)
		price.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(price)

		var buy := Button.new()
		buy.text = "Buy"
		buy.custom_minimum_size = Vector2(70, 0)
		buy.pressed.connect(_attempt_buy.bind(entry, buy))
		row.add_child(buy)

		rows_box.add_child(row)


func _attempt_buy(entry: Dictionary, buy_btn: Button) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var price := int(entry["price"])
	if _player.gold < price:
		_flash_message("Not enough gold.")
		SoundManager.play("deny")
		return

	if entry["kind"] == "spell":
		var skill_id: String = entry["skill_id"]
		if ProgressionTracker.is_skill_unlocked(skill_id):
			_flash_message("Already known.")
			SoundManager.play("deny")
			return
		_player.gold -= price
		ProgressionTracker.unlock_skill(skill_id)
		buy_btn.text = "Owned"
		buy_btn.disabled = true
		_flash_message("%s learned! Select it with K." % entry["name"])
	else:
		var inv = _player.get_node_or_null("InventoryUI")
		if inv == null or not inv.has_method("pickupItem"):
			return
		if inv.has_method("has_free_slot") and not inv.has_free_slot():
			_flash_message("Inventory full.")
			SoundManager.play("deny")
			return
		var item: ItemData = ShopCatalog.make_item(entry["factory"])
		if item == null:
			return
		_player.gold -= price
		inv.pickupItem(item)
		_flash_message("%s added to inventory." % entry["name"])

	SoundManager.play("buy")
	if _player.has_method("_updateHUD"):
		_player._updateHUD()
	_refresh()


func _refresh() -> void:
	if gold_label and is_instance_valid(_player):
		gold_label.text = "Your gold: %d" % int(_player.gold)
	# Keep spell buttons in sync with what the knight already knows.
	var stock := ShopCatalog.get_stock()
	for i in rows_box.get_child_count():
		if i >= stock.size():
			break
		var entry: Dictionary = stock[i]
		if entry["kind"] != "spell":
			continue
		var row := rows_box.get_child(i)
		var buy_btn := row.get_child(row.get_child_count() - 1) as Button
		if buy_btn and ProgressionTracker.is_skill_unlocked(entry["skill_id"]):
			buy_btn.text = "Owned"
			buy_btn.disabled = true


func _flash_message(text: String) -> void:
	if message_label:
		message_label.text = text
