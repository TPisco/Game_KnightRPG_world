## Item definitions for procedural world loot drops.
extends Node
class_name LootTable

const ICON_SWORD := preload("res://assets/Textures/SwordIcon.png")
const ICON_SPHERE := preload("res://assets/Textures/SphereIcon.png")
const ICON_TORCH := preload("res://assets/Textures/torch.png")
const ICON_BOX := preload("res://assets/Textures/BoxIcon.png")
const SWORD_WORLD := preload("res://scenes/Items/sword.tscn")
const SWORD_EQUIP := preload("res://assets/Sprites/items/sword.tscn")


static func rusted_sword() -> ItemData:
	var item := ItemData.new()
	item.ItemName = "Sword"
	item.Icon = ICON_SWORD
	item.item_type = "weapon"
	item.stat_bonuses = {"damage": 6}
	item.ItemModelPrefab = SWORD_WORLD
	item.UsableModel = SWORD_EQUIP
	return item


static func fractured_blade() -> ItemData:
	var item := ItemData.new()
	item.ItemName = "Sword"
	item.Icon = ICON_SWORD
	item.item_type = "weapon"
	item.stat_bonuses = {"damage": 12}
	item.ItemModelPrefab = SWORD_WORLD
	item.UsableModel = SWORD_EQUIP
	return item


static func wooden_shield() -> ItemData:
	var item := ItemData.new()
	item.ItemName = "WoodenShield"
	item.Icon = ICON_BOX
	item.item_type = "armor"
	item.stat_bonuses = {"max_hp": 20}
	return item


static func guardian_plate() -> ItemData:
	var item := ItemData.new()
	item.ItemName = "GuardianPlate"
	item.Icon = ICON_BOX
	item.item_type = "armor"
	item.stat_bonuses = {"max_hp": 35, "damage": 2}
	return item


static func fractured_shard() -> ItemData:
	var item := ItemData.new()
	item.ItemName = "FracturedShard"
	item.Icon = ICON_SPHERE
	item.item_type = "artifact"
	item.stat_bonuses = {"damage": 4, "max_hp": 12}
	return item


static func healing_vial() -> ItemData:
	var item := ItemData.new()
	item.ItemName = "HealingVial"
	item.Icon = ICON_TORCH
	item.item_type = "consumable"
	item.stat_bonuses = {"heal": 35}
	return item


## Skill tome: picking it up unlocks the given power (no inventory slot used).
static func skill_tome(skill_id: String) -> ItemData:
	var item := ItemData.new()
	item.ItemName = "Tome of %s" % skill_id.capitalize()
	item.Icon = ICON_SPHERE
	item.item_type = "tome"
	item.unlock_skill = skill_id
	return item


const SKILL_TOMES := ["arcane_bolt", "iron_wall", "life_drain"]


static func roll_loot(depth: int, rng: RandomNumberGenerator) -> ItemData:
	# Rare chance for a skill tome that unlocks a power on pickup.
	if depth >= 2 and rng.randf() < 0.08:
		return skill_tome(SKILL_TOMES[rng.randi() % SKILL_TOMES.size()])
	var roll := rng.randf()
	if depth <= 1:
		if roll < 0.35:
			return rusted_sword()
		if roll < 0.55:
			return wooden_shield()
		if roll < 0.75:
			return healing_vial()
		return fractured_shard()
	if depth < 8:
		if roll < 0.25:
			return fractured_blade()
		if roll < 0.45:
			return guardian_plate()
		if roll < 0.65:
			return healing_vial()
		return fractured_shard()
	if roll < 0.3:
		return fractured_blade()
	if roll < 0.5:
		return guardian_plate()
	return fractured_shard()


static func starter_loadout() -> Array[ItemData]:
	return [rusted_sword(), wooden_shield(), healing_vial()]
