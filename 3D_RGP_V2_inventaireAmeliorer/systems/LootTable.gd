## Item definitions for procedural world loot drops.
extends Node
class_name LootTable

const ICON_SWORD := preload("res://assets/Textures/SwordIcon.png")
const ICON_SPHERE := preload("res://assets/Textures/SphereIcon.png")
const ICON_TORCH := preload("res://assets/Textures/torch.png")
const ICON_BOX := preload("res://assets/Textures/BoxIcon.png")
const SWORD_WORLD := preload("res://scenes/Items/sword.tscn")
const SWORD_EQUIP := preload("res://assets/Sprites/items/sword.tscn")

const ICON_DIR := "res://assets/Textures/icons/"


## Dedicated item icon with a safe fallback to the legacy generic icons.
static func _icon(file_name: String, fallback: Texture2D) -> Texture2D:
	var path := ICON_DIR + file_name
	if ResourceLoader.exists(path):
		return load(path)
	return fallback


static func rusted_sword() -> ItemData:
	var item := ItemData.new()
	item.ItemName = "Rusted Sword"
	item.Icon = _icon("icon_sword_rusted.png", ICON_SWORD)
	item.item_type = "weapon"
	item.weapon_class = "melee"
	item.stat_bonuses = {"damage": 6}
	item.ItemModelPrefab = SWORD_WORLD
	item.UsableModel = SWORD_EQUIP
	return item


static func fractured_blade() -> ItemData:
	var item := ItemData.new()
	item.ItemName = "Fractured Blade"
	item.Icon = _icon("icon_sword_fractured.png", ICON_SWORD)
	item.item_type = "weapon"
	item.weapon_class = "melee"
	item.stat_bonuses = {"damage": 12}
	item.ItemModelPrefab = SWORD_WORLD
	item.UsableModel = SWORD_EQUIP
	return item


static func wooden_shield() -> ItemData:
	var item := ItemData.new()
	item.ItemName = "WoodenShield"
	item.Icon = _icon("icon_shield.png", ICON_BOX)
	item.item_type = "armor"
	item.weapon_class = "shield"
	item.stat_bonuses = {"max_hp": 20}
	return item


static func guardian_plate() -> ItemData:
	var item := ItemData.new()
	item.ItemName = "GuardianPlate"
	item.Icon = _icon("icon_plate.png", ICON_BOX)
	item.item_type = "armor"
	item.stat_bonuses = {"max_hp": 35, "damage": 2}
	return item


static func fractured_shard() -> ItemData:
	var item := ItemData.new()
	item.ItemName = "FracturedShard"
	item.Icon = _icon("icon_shard.png", ICON_SPHERE)
	item.item_type = "artifact"
	item.stat_bonuses = {"damage": 4, "max_hp": 12}
	return item


static func healing_vial() -> ItemData:
	var item := ItemData.new()
	item.ItemName = "HealingVial"
	item.Icon = _icon("icon_potion_red.png", ICON_TORCH)
	item.item_type = "consumable"
	item.stat_bonuses = {"heal": 35}
	return item


static func mana_vial() -> ItemData:
	var item := ItemData.new()
	item.ItemName = "ManaVial"
	item.Icon = _icon("icon_potion_blue.png", ICON_SPHERE)
	item.item_type = "consumable"
	item.stat_bonuses = {"mana": 40}
	return item


static func pistol() -> ItemData:
	var item := ItemData.new()
	item.ItemName = "RiftPistol"
	item.Icon = _icon("icon_gun_pistol.png", ICON_SWORD)
	item.item_type = "weapon"
	item.weapon_class = "gun"
	item.stat_bonuses = {"damage": 8, "fire_rate": 0.45}
	return item


static func rifle() -> ItemData:
	var item := ItemData.new()
	item.ItemName = "ShardRifle"
	item.Icon = _icon("icon_gun_rifle.png", ICON_SWORD)
	item.item_type = "weapon"
	item.weapon_class = "gun"
	item.stat_bonuses = {"damage": 18, "fire_rate": 0.9}
	return item


static func apprentice_staff() -> ItemData:
	var item := ItemData.new()
	item.ItemName = "ApprenticeStaff"
	item.Icon = _icon("icon_staff_arcane.png", ICON_SPHERE)
	item.item_type = "weapon"
	item.weapon_class = "staff"
	item.stat_bonuses = {"damage": 5, "max_mana": 20, "fire_rate": 0.7, "mana_cost": 8}
	return item


static func ember_staff() -> ItemData:
	var item := ItemData.new()
	item.ItemName = "EmberStaff"
	item.Icon = _icon("icon_staff_fire.png", ICON_SPHERE)
	item.item_type = "weapon"
	item.weapon_class = "staff"
	item.stat_bonuses = {"damage": 14, "max_mana": 35, "fire_rate": 0.6, "mana_cost": 10}
	return item


static func knights_blade() -> ItemData:
	var item := ItemData.new()
	item.ItemName = "Knight's Blade"
	item.Icon = _icon("icon_sword_knight.png", ICON_SWORD)
	item.item_type = "weapon"
	item.weapon_class = "melee"
	item.stat_bonuses = {"damage": 18}
	item.ItemModelPrefab = SWORD_WORLD
	item.UsableModel = SWORD_EQUIP
	return item


## Skill tome: picking it up unlocks the given power (no inventory slot used).
static func skill_tome(skill_id: String) -> ItemData:
	var item := ItemData.new()
	item.ItemName = "Tome of %s" % skill_id.capitalize()
	item.Icon = _icon("icon_tome.png", ICON_SPHERE)
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
		if roll < 0.2:
			return fractured_blade()
		if roll < 0.32:
			return pistol()
		if roll < 0.42:
			return apprentice_staff()
		if roll < 0.58:
			return guardian_plate()
		if roll < 0.7:
			return healing_vial()
		if roll < 0.8:
			return mana_vial()
		return fractured_shard()
	if roll < 0.2:
		return fractured_blade()
	if roll < 0.32:
		return rifle()
	if roll < 0.44:
		return ember_staff()
	if roll < 0.6:
		return guardian_plate()
	if roll < 0.7:
		return mana_vial()
	return fractured_shard()


static func starter_loadout() -> Array[ItemData]:
	return [rusted_sword(), wooden_shield(), healing_vial()]


## Mini-boss reward: guaranteed high-tier gear, clearly better than mob drops.
static func roll_boss_loot(depth: int, rng: RandomNumberGenerator) -> Array[ItemData]:
	var strong_gear: Array = [fractured_blade(), knights_blade(), rifle(), ember_staff(), guardian_plate()]
	if depth < 6:
		strong_gear.append(pistol())
		strong_gear.append(apprentice_staff())
	var loot: Array[ItemData] = []
	loot.append(strong_gear[rng.randi() % strong_gear.size()])
	loot.append(fractured_shard())
	loot.append(healing_vial() if rng.randf() < 0.5 else mana_vial())
	# Rare bonus: a skill tome.
	if rng.randf() < 0.2:
		loot.append(skill_tome(SKILL_TOMES[rng.randi() % SKILL_TOMES.size()]))
	return loot
