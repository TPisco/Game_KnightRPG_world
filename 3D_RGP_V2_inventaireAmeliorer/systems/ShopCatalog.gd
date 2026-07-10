## The Collector's stock: weapons, staffs, spells, and potions with prices.
extends Node
class_name ShopCatalog


## kind "item": factory id resolved by make_item(); kind "spell": unlocks skill_id.
static func get_stock() -> Array:
	return [
		{"name": "Healing Potion", "type": "Consumable", "desc": "Restores 35 HP on use", "price": 25, "kind": "item", "factory": "healing_vial"},
		{"name": "Mana Potion", "type": "Consumable", "desc": "Restores 40 mana on use", "price": 25, "kind": "item", "factory": "mana_vial"},
		{"name": "Rift Pistol", "type": "Gun", "desc": "+8 dmg, fast ranged shots", "price": 60, "kind": "item", "factory": "pistol"},
		{"name": "Shard Rifle", "type": "Gun", "desc": "+18 dmg, slow heavy shots", "price": 150, "kind": "item", "factory": "rifle"},
		{"name": "Knight's Blade", "type": "Melee", "desc": "+18 dmg sword", "price": 120, "kind": "item", "factory": "knights_blade"},
		{"name": "Apprentice Staff", "type": "Staff", "desc": "+5 dmg, +20 mana, magic bolts", "price": 90, "kind": "item", "factory": "apprentice_staff"},
		{"name": "Ember Staff", "type": "Staff", "desc": "+14 dmg, +35 mana, strong bolts", "price": 180, "kind": "item", "factory": "ember_staff"},
		{"name": "Guardian Plate", "type": "Armor", "desc": "+35 HP, +2 dmg", "price": 110, "kind": "item", "factory": "guardian_plate"},
		{"name": "Spell: Arcane Bolt", "type": "Spell", "desc": "Unlocks the Arcane Bolt skill", "price": 120, "kind": "spell", "skill_id": "arcane_bolt"},
		{"name": "Spell: Iron Wall", "type": "Spell", "desc": "Unlocks the Iron Wall skill", "price": 120, "kind": "spell", "skill_id": "iron_wall"},
		{"name": "Spell: Life Drain", "type": "Spell", "desc": "Unlocks the Life Drain skill", "price": 200, "kind": "spell", "skill_id": "life_drain"},
	]


static func make_item(factory_id: String) -> ItemData:
	match factory_id:
		"healing_vial":
			return LootTable.healing_vial()
		"mana_vial":
			return LootTable.mana_vial()
		"pistol":
			return LootTable.pistol()
		"rifle":
			return LootTable.rifle()
		"knights_blade":
			return LootTable.knights_blade()
		"apprentice_staff":
			return LootTable.apprentice_staff()
		"ember_staff":
			return LootTable.ember_staff()
		"guardian_plate":
			return LootTable.guardian_plate()
		_:
			return null
